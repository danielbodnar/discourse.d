# tools/lib/docker.sh
#!/usr/bin/env bash

# Function to extract container configuration
extract_container_config() {
    local container="$1"
    local outdir="$2"

    debug "Extracting configuration from container: $container"

    # Get container info
    local config
    if ! config=$(docker inspect "$container"); then
        if [ "$CONTINUE_ON_ERROR" = true ]; then
            warn "Failed to inspect container/image: $container"
            return
        else
            error "Failed to inspect container/image: $container"
        fi
    fi

    # Extract basic configuration
    extract_env_vars "$config" "$outdir"
    extract_volumes "$config" "$outdir"
    extract_ports "$config" "$outdir"
    extract_entrypoint_cmd "$config" "$outdir"

    # Parse image comments if enabled
    if [ "$PARSE_COMMENTS" = true ]; then
        parse_docker_comments "$config" "$outdir"
    fi

    return 0
}

# Function to extract environment variables
extract_env_vars() {
    local config="$1"
    local outdir="$2"
    local env_file="$outdir/scripts/001-environment.sh"

    debug "Extracting environment variables"

    echo "#!/bin/bash" > "$env_file"
    echo "# Generated environment variables" >> "$env_file"
    echo "set -euo pipefail" >> "$env_file"
    echo "" >> "$env_file"

    if jq -e '.[0].Config.Env' <<<"$config" >/dev/null 2>&1; then
        jq -r '.[0].Config.Env[]?' <<<"$config" | while read -r env; do
            if [ -n "$env" ]; then
                echo "export $env" >> "$env_file"
            fi
        done
    else
        debug "No environment variables found"
    fi

    chmod +x "$env_file"
}

# Function to extract volumes
extract_volumes() {
    local config="$1"
    local outdir="$2"
    local volume_file="$outdir/scripts/002-volumes.sh"

    debug "Extracting volume configuration"

    echo "#!/bin/bash" > "$volume_file"
    echo "# Generated volume configuration" >> "$volume_file"
    echo "set -euo pipefail" >> "$volume_file"
    echo "" >> "$volume_file"

    if jq -e '.[0].Config.Volumes' <<<"$config" >/dev/null 2>&1; then
        jq -r '.[0].Config.Volumes | if . == null then {} else . end | keys[]?' <<<"$config" | while read -r volume; do
            if [ -n "$volume" ]; then
                echo "mkdir -p \"$volume\"" >> "$volume_file"
            fi
        done
    else
        debug "No volume configuration found"
    fi

    chmod +x "$volume_file"
}

# Function to extract ports
extract_ports() {
    local config="$1"
    local outdir="$2"
    local ports_file="$outdir/scripts/003-ports.sh"

    debug "Extracting port configuration"

    echo "#!/bin/bash" > "$ports_file"
    echo "# Generated port configuration" >> "$ports_file"
    echo "set -euo pipefail" >> "$ports_file"
    echo "" >> "$ports_file"
    echo "EXPOSED_PORTS=(" >> "$ports_file"

    if jq -e '.[0].Config.ExposedPorts' <<<"$config" >/dev/null 2>&1; then
        jq -r '.[0].Config.ExposedPorts | if . == null then {} else . end | keys[]?' <<<"$config" | while read -r port; do
            if [ -n "$port" ]; then
                echo "    \"$port\"" >> "$ports_file"
            fi
        done
    else
        debug "No exposed ports found"
    fi

    echo ")" >> "$ports_file"
    chmod +x "$ports_file"
}

# Function to extract entrypoint and cmd
extract_entrypoint_cmd() {
    local config="$1"
    local outdir="$2"
    local entrypoint_file="$outdir/scripts/004-entrypoint.sh"

    debug "Extracting entrypoint and command"

    echo "#!/bin/bash" > "$entrypoint_file"
    echo "# Generated entrypoint and command configuration" >> "$entrypoint_file"
    echo "set -euo pipefail" >> "$entrypoint_file"
    echo "" >> "$entrypoint_file"
    echo "ENTRYPOINT_ARGS=()" >> "$entrypoint_file"
    echo "CMD_ARGS=()" >> "$entrypoint_file"

    if jq -e '.[0].Config.Entrypoint' <<<"$config" >/dev/null 2>&1; then
        jq -r '.[0].Config.Entrypoint[]?' <<<"$config" | while read -r entry; do
            if [ -n "$entry" ]; then
                echo "ENTRYPOINT_ARGS+=(\"$entry\")" >> "$entrypoint_file"
            fi
        done
    fi

    if jq -e '.[0].Config.Cmd' <<<"$config" >/dev/null 2>&1; then
        jq -r '.[0].Config.Cmd[]?' <<<"$config" | while read -r cmd; do
            if [ -n "$cmd" ]; then
                echo "CMD_ARGS+=(\"$cmd\")" >> "$entrypoint_file"
            fi
        done
    fi

    chmod +x "$entrypoint_file"
}

# Function to handle multi-stage builds
handle_multi_stage() {
    local image="$1"
    local outdir="$2"

    debug "Checking for multi-stage build"

    # Create stages directory
    mkdir -p "$outdir/stages"

    # Get all stages
    local stages
    stages=$(docker history "$image" --format "{{.CreatedBy}}" | grep -i "^FROM" || true)

    if [ -n "$stages" ]; then
        debug "Found multi-stage build"

        # Process each stage
        local stage_num=0
        while read -r stage; do
            stage_num=$((stage_num + 1))
            local stage_dir="$outdir/stages/stage${stage_num}"
            mkdir -p "$stage_dir"

            # Extract stage information
            echo "# Stage $stage_num: $stage" > "$stage_dir/stage.info"

            # Try to extract intermediate container if possible
            local stage_image
            stage_image=$(echo "$stage" | awk '{print $2}')
            if docker image inspect "$stage_image" >/dev/null 2>&1; then
                extract_container_config "$stage_image" "$stage_dir"
            fi
        done <<< "$stages"
    else
        debug "No multi-stage build detected"
    fi
}
