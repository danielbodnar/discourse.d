# tools/lib/parsers.sh
#!/usr/bin/env bash

# Function to parse Docker image comments
parse_docker_comments() {
    local config="$1"
    local outdir="$2"

    debug "Parsing Docker image comments and history"

    local comments_file="$outdir/config/image_history.json"
    local build_steps_dir="$outdir/build_steps"
    local copy_steps_dir="$outdir/copy_steps"
    mkdir -p "$build_steps_dir" "$copy_steps_dir"

    # Create build order file
    local build_order_file="$outdir/build_order.txt"
    echo "# Build order - execute scripts in this order" > "$build_order_file"
    echo "# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$build_order_file"
    echo "" >> "$build_order_file"

    # Extract and parse the Comment field
    if jq -e '.[0].Comment' <<<"$config" >/dev/null 2>&1; then
        jq -r '.[0].Comment' <<<"$config" > "$comments_file"
        parse_build_history "$comments_file" "$outdir"
    else
        debug "No Comment field found in image configuration"
    fi
}

# Function to parse build history
parse_build_history() {
    local comments_file="$1"
    local outdir="$2"
    local step_counter=0

    debug "Parsing build history from comments"

    jq -r '.[] | select(.created_by != null) | {created: .created, command: .created_by, empty_layer: .empty_layer}' "$comments_file" | \
    jq -r '. | @base64' | while read -r item; do
        # Decode JSON object
        local decoded=$(echo "$item" | base64 --decode)
        local created=$(echo "$decoded" | jq -r '.created')
        local command=$(echo "$decoded" | jq -r '.command')
        local is_empty=$(echo "$decoded" | jq -r '.empty_layer')

        # Skip empty layers
        if [ "$is_empty" = "true" ]; then
            continue
        fi

        # Increment counter
        step_counter=$((step_counter + 1))
        local step_num=$(printf "%03d" $step_counter)

        # Clean up buildkit annotations
        local cleaned_command=$(clean_command "$command")

        # Parse command based on type
        parse_command "$cleaned_command" "$step_num" "$created" "$outdir"
    done
}

# Function to clean command string
clean_command() {
    local command="$1"
    echo "$command" | \
        sed 's/|[0-9]* TARGETARCH=[^ ]* //g' | \
        sed 's/ # buildkit//g' | \
        sed 's/\\u0026/\&/g' | \
        sed 's/\\\\n/\n/g'
}

# Function to parse individual commands
parse_command() {
    local command="$1"
    local step_num="$2"
    local created="$3"
    local outdir="$4"
    local build_order_file="$outdir/build_order.txt"

    case "$command" in
        COPY*|ADD*)
            local script_path="copy_steps/${step_num}-copy.sh"
            create_copy_script "$command" "$outdir/$script_path" "$created"
            echo "$script_path" >> "$build_order_file"
            ;;
        RUN*)
            local script_path="build_steps/${step_num}-run.sh"
            create_run_script "$command" "$outdir/$script_path" "$created"
            echo "$script_path" >> "$build_order_file"
            ;;
        ENV*)
            local script_path="build_steps/${step_num}-env.sh"
            create_env_script "$command" "$outdir/$script_path" "$created"
            echo "$script_path" >> "$build_order_file"
            ;;
        WORKDIR*)
            local script_path="build_steps/${step_num}-workdir.sh"
            create_workdir_script "$command" "$outdir/$script_path" "$created"
            echo "$script_path" >> "$build_order_file"
            ;;
        *)
            debug "Skipping unsupported command: $command"
            ;;
    esac
}

# Function to parse COPY command
parse_copy_command() {
    local command="$1"
    local src=""
    local dest=""
    local stage=""

    if [[ "$command" =~ --from= ]]; then
        stage=$(echo "$command" | grep -o '\--from=[^ ]*' | cut -d= -f2)
        src=$(echo "$command" | awk '{print $3}')
        dest=$(echo "$command" | awk '{print $4}')
    else
        src=$(echo "$command" | awk '{print $2}')
        dest=$(echo "$command" | awk '{print $3}')
    fi

    echo "src=\"$src\""
    echo "dest=\"$dest\""
    [ -n "$stage" ] && echo "stage=\"$stage\""
}

# Function to parse ENV command
parse_env_command() {
    local env_vars="$1"

    if [[ "$env_vars" =~ = ]]; then
        # Equals-separated format
        echo "export $env_vars"
    else
        # Space-separated format
        local key=$(echo "$env_vars" | awk '{print $1}')
        local value=$(echo "$env_vars" | cut -d' ' -f2-)
        echo "export $key=\"$value\""
    fi
}
