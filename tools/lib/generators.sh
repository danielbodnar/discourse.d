# tools/lib/generators.sh
#!/usr/bin/env bash

# Function to create script from template
create_script_from_template() {
    local template="$1"
    local output="$2"
    local vars="$3"

    if [ ! -f "$template" ]; then
        error "Template not found: $template"
    }

    # Create script directory if it doesn't exist
    mkdir -p "$(dirname "$output")"

    # Process template with variables
    eval "cat << EOF
$(cat "$template")
EOF" > "$output"

    chmod +x "$output"
}

# Function to create copy script
create_copy_script() {
    local command="$1"
    local script_file="$2"
    local created="$3"

    local template="${LIB_DIR}/scripts/copy.sh.template"
    local parsed_command=$(parse_copy_command "$command")

    local vars=$(cat << EOF
CREATED="$created"
COMMAND="$command"
$parsed_command
EOF
)

    create_script_from_template "$template" "$script_file" "$vars"
}

# Function to create run script
create_run_script() {
    local command="$1"
    local script_file="$2"
    local created="$3"

    local template="${LIB_DIR}/scripts/run.sh.template"
    local actual_command=$(echo "$command" | sed 's/^RUN //')

    local vars=$(cat << EOF
CREATED="$created"
COMMAND="$command"
ACTUAL_COMMAND="$actual_command"
EOF
)

    create_script_from_template "$template" "$script_file" "$vars"
}

# Function to create environment script
create_env_script() {
    local command="$1"
    local script_file="$2"
    local created="$3"

    local template="${LIB_DIR}/scripts/env.sh.template"
    local env_vars=$(echo "$command" | sed 's/^ENV //')
    local parsed_env=$(parse_env_command "$env_vars")

    local vars=$(cat << EOF
CREATED="$created"
COMMAND="$command"
ENV_VARS="$parsed_env"
EOF
)

    create_script_from_template "$template" "$script_file" "$vars"
}

# Function to create workdir script
create_workdir_script() {
    local command="$1"
    local script_file="$2"
    local created="$3"

    local template="${LIB_DIR}/scripts/workdir.sh.template"
    local dir=$(echo "$command" | sed 's/^WORKDIR //')

    local vars=$(cat << EOF
CREATED="$created"
COMMAND="$command"
WORKDIR="$dir"
EOF
)

    create_script_from_template "$template" "$script_file" "$vars"
}

# Function to create master build script
create_master_build_script() {
    local outdir="$1"
    local template="${LIB_DIR}/scripts/build.sh.template"

    local vars=$(cat << EOF
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
BUILD_ORDER_FILE="\$SCRIPT_DIR/build_order.txt"
EOF
)

    create_script_from_template "$template" "$outdir/build.sh" "$vars"
}

# Function to create runtime scripts
create_runtime_scripts() {
    local outdir="$1"
    local name="$2"

    debug "Creating runtime scripts"

    # Create common library
    create_script_from_template \
        "${LIB_DIR}/scripts/common.sh.template" \
        "$outdir/lib/common.sh" \
        ""

    # Create run script
    create_script_from_template \
        "${LIB_DIR}/scripts/run.sh.template" \
        "$outdir/bin/run.sh" \
        "NAME=\"$name\""
}
