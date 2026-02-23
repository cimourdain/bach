#!/bin/bash

# Get the directory where this library is located
__DOC_HELPER_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prevent re-sourcing if functions already declared
if declare -F bach::get_version_from_doc &>/dev/null && \
   declare -F bach::build_documentation &>/dev/null && \
   declare -F bach::__private::inject_subcommands &>/dev/null && \
   declare -F bach::print_doc &>/dev/null && \
   declare -F bach::print_version &>/dev/null; then
    return 0
fi

# Helper function to check if item is excluded (private)
bach::__private::is_excluded() {
    local item="$1"
    local item_name=$(basename "$item")
    shift
    local -a exclude_array=("$@")

    for pattern in "${exclude_array[@]}"; do
        if [[ "$item_name" == $pattern ]] || [[ "$item" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

# Check if directory has an executable main script (private)
bach::__private::has_executable_main() {
    local dir="$1"

    if [[ -f "$dir/main.sh" && -x "$dir/main.sh" ]]; then
       return 0
    elif [[ -f "$dir/main" && -x "$dir/main" ]]; then
        return 0
    fi
    return 1
}

# Get list of available subcommands in a directory (private)
# Used internally by bach::build_documentation for tests
bach::__private::get_available_subcommands() {
    local base_dir="$1"
    local exclude_list="$2"

    [[ ! -d "$base_dir" ]] && return

    # Setup exclusion list
    local -a exclude_array=()
    if [[ -n "$exclude_list" ]]; then
        IFS=',' read -ra exclude_array <<< "$exclude_list"
    fi
    exclude_array+=("const.sh" "*.sh~" "*.swp" "main.sh")

    local -a subcommands=()

    for item in "$base_dir"/*; do
        [[ ! -e "$item" ]] && continue
        bach::__private::is_excluded "$item" "${exclude_array[@]}" && continue

        local item_name=$(basename "$item")

        # Check if it's a directory
        if [[ -d "$item" ]]; then
            # Include directory if it has main.sh or if it contains any subcommands
            if bach::__private::has_executable_main "$item"; then
                subcommands+=("${item_name}")
            else
                # Check if directory contains any executable files or subdirectories
                local has_content=false
                for subitem in "$item"/*; do
                    [[ ! -e "$subitem" ]] && continue
                    if [[ -d "$subitem" ]] || [[ -f "$subitem" && -x "$subitem" ]]; then
                        has_content=true
                        break
                    fi
                done
                if [[ "$has_content" == "true" ]]; then
                    subcommands+=("${item_name}")
                fi
            fi
        # Check if it's an executable .sh file
        elif [[ -f "$item" && -x "$item" && "$item_name" == *.sh ]]; then
            subcommands+=("${item_name%.sh}")
        # Check if it's an executable file without extension
        elif [[ -f "$item" && -x "$item" && "$item_name" != *.* ]]; then
            subcommands+=("${item_name}")
        fi
    done

    # Output subcommands, one per line
    for cmd in "${subcommands[@]}"; do
        echo "$cmd"
    done
}

# Process and filter subcommands (private)
# Arguments:
#   $1: Script directory
#   $2: Exclude list
#   $3: Name reference to subcommands array
bach::__private::process_and_filter_subcommands() {
    local script_dir="$1"
    local exclude_list="$2"
    local -n sc="$3"

    [[ -z "$script_dir" ]] && return

    # Get available subcommands
    while IFS= read -r cmd; do
        [[ -n "$cmd" ]] && sc+=("$cmd")
    done < <(bach::__private::get_available_subcommands "$script_dir" "$exclude_list")

    # Note: We don't filter out directories without main.sh here
    # because they might have nested subcommands that should be shown

    # Sort subcommands
    if [[ ${#sc[@]} -gt 0 ]]; then
        IFS=$'\n' sc=($(sort <<<"${sc[*]}"))
        unset IFS
    fi
}

# Detect sections and user options in docstring (private)
# Arguments:
#   $1: Documentation string
#   $2: Name reference to has_usage_section
#   $3: Name reference to has_options_section
#   $4: Name reference to has_user_options
bach::__private::detect_sections_and_options() {
    local doc_string="$1"
    local -n hus="$2"
    local -n hos="$3"
    local -n huo="$4"

    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*(Usage:)[[:space:]]*$ ]] && hus=true
        [[ "$line" =~ ^[[:space:]]*(Options:)[[:space:]]*$ ]] && hos=true

        # Detect user-defined options (not help/version)
        if [[ "$line" =~ ^[[:space:]]*(-[a-zA-Z]|--[a-zA-Z]) ]]; then
            if [[ ! "$line" =~ -h,.*--help ]] && [[ ! "$line" =~ -v,.*--version ]]; then
                huo=true
            fi
        fi
    done <<< "$doc_string"
}

# Expand subcommands for directories without main.sh (private)
# Arguments:
#   $1: Script directory
#   $2: Subcommand name
#   $3: Exclude list
#   $4: Name reference to expanded array
bach::__private::expand_nested_subcommands() {
    local script_dir="$1"
    local subcmd="$2"
    local exclude_list="$3"
    local -n expanded="$4"

    local subcmd_path="$script_dir/$subcmd"

    # Check if it's a directory
    if [[ ! -d "$subcmd_path" ]]; then
        expanded+=("$subcmd")
        return
    fi

    # Check if directory has main.sh
    if [[ -f "$subcmd_path/main.sh" && -x "$subcmd_path/main.sh" ]] || \
       [[ -f "$subcmd_path/main" && -x "$subcmd_path/main" ]]; then
        expanded+=("$subcmd")
        return
    fi

    # Directory without main.sh - expand its subcommands
    local -a nested_subcommands=()
    while IFS= read -r cmd; do
        [[ -n "$cmd" ]] && nested_subcommands+=("$cmd")
    done < <(bach::get_available_subcommands "$subcmd_path" "$exclude_list")

    for nested in "${nested_subcommands[@]}"; do
        expanded+=("$subcmd $nested")
    done
}

# Inject usage section when missing (private)
# Arguments:
#   $1: Command name
#   $2: Name reference to subcommands array
#   $3: Script directory (empty if using pre-expanded subcommands)
#   $4: Exclude list (empty if using pre-expanded subcommands)
#   $5: Has user options flag
#   $6: Name reference to custom usage lines array
# Returns:
#   echoes the injected usage section
bach::__private::inject_usage_section() {
    local cmd_name="$1"
    local -n subcmds_ref="$2"
    local script_dir="$3"
    local exclude_list="$4"
    local has_user_options="$5"
    local -n custom_usage_ref="$6"

    local output="Usage:"$'\n'

    # First, add custom usage lines if any
    local has_custom_usage=false
    for custom_line in "${custom_usage_ref[@]}"; do
        output+="    ${custom_line}"$'\n'
        has_custom_usage=true
    done

    # If script_dir is empty, subcommands are pre-expanded
    local -a final_subcommands=()
    if [[ -z "$script_dir" ]]; then
        # Use subcommands as-is (already expanded)
        final_subcommands=("${subcmds_ref[@]}")
    else
        # Expand subcommands (handle nested folders without main.sh)
        for subcmd in "${subcmds_ref[@]}"; do
            bach::__private::expand_nested_subcommands "$script_dir" "$subcmd" "$exclude_list" final_subcommands
        done
    fi

    # If there are subcommands, add them
    if [[ ${#final_subcommands[@]} -gt 0 ]]; then
        # Generate usage lines for subcommands
        for subcmd in "${final_subcommands[@]}"; do
            if [[ -n "$script_dir" ]]; then
                local subcmd_file=$(bach::__private::get_subcommand_file "$script_dir" "$subcmd" "$exclude_list")
                output+="    ${cmd_name} ${subcmd}  # Execute ${subcmd_file}"$'\n'
            else
                # Pre-expanded subcommands don't include file paths
                output+="    ${cmd_name} ${subcmd}"$'\n'
            fi
        done
    elif [[ "$has_custom_usage" == false ]]; then
        # No custom usage and no subcommands, show at least one line with command name
        if [[ "$has_user_options" == "true" ]]; then
            output+="    ${cmd_name} [options]"$'\n'
        else
            output+="    ${cmd_name}"$'\n'
        fi
    elif [[ "$has_user_options" == "true" ]]; then
        # Has custom usage and user options, add [options] line if not already present
        local has_options_line=false
        for custom_line in "${custom_usage_ref[@]}"; do
            if [[ "$custom_line" =~ \[options\] ]]; then
                has_options_line=true
                break
            fi
        done
        if [[ "$has_options_line" == false ]]; then
            output+="    ${cmd_name} [options]"$'\n'
        fi
    fi

    echo -n "$output"
}

# Process docstring and build output (private)
# Arguments:
#   $1: Documentation string
#   $2: Command name
#   $3: Name reference to subcommands array
#   $4: Script directory
#   $5: Exclude list
#   $6: Has usage section flag
#   $7: Has options section flag
#   $8: Has user options flag
# Returns:
#   echoes the processed docstring
bach::__private::process_docstring() {
    local doc_string="$1"
    local cmd_name="$2"
    local -n subcmds_ref="$3"
    local script_dir="$4"
    local exclude_list="$5"
    local has_usage_section="$6"
    local has_options_section="$7"
    local has_user_options="$8"

    # Make a local copy of subcommands array to avoid circular reference
    local -a local_subcmds=("${subcmds_ref[@]}")
    local -a custom_usage_lines=()

    local output=""
    local in_usage_section=false
    local usage_content_skipped=false
    local usage_injected=false

    # First pass: extract custom usage lines if Usage section exists
    if [[ "$has_usage_section" == true ]]; then
        local in_usage=false
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*(Usage:)[[:space:]]*$ ]]; then
                in_usage=true
                continue
            fi
            if [[ "$in_usage" == true ]]; then
                if [[ "$line" =~ ^[[:space:]]*(Options:)[[:space:]]*$ ]] || [[ "$line" =~ ^-+$ ]] || [[ -z "$line" ]]; then
                    break
                fi
                # Extract usage line (remove leading whitespace)
                local trimmed_line="${line#"${line%%[![:space:]]*}"}"
                if [[ -n "$trimmed_line" ]]; then
                    custom_usage_lines+=("$trimmed_line")
                fi
            fi
        done <<< "$doc_string"
    fi

    while IFS= read -r line; do
        # Detect existing usage section and replace it
        if [[ "$line" =~ ^[[:space:]]*(Usage:)[[:space:]]*$ ]]; then
            in_usage_section=true
            usage_content_skipped=false
            usage_injected=true

            # Inject our usage section with custom lines
            output+=$(bach::__private::inject_usage_section "$cmd_name" local_subcmds "$script_dir" "$exclude_list" "$has_user_options" custom_usage_lines)
            output+=$'\n'
            continue
        fi

        # Skip original usage content
        if [[ "$in_usage_section" == true && "$usage_content_skipped" == false ]]; then
            if [[ "$line" =~ ^[[:space:]]*(Options:)[[:space:]]*$ ]] || [[ "$line" =~ ^-+$ ]] || [[ -z "$line" ]]; then
                in_usage_section=false
                usage_content_skipped=true
            else
                continue
            fi
        fi

        # Inject usage before Options section if not yet injected
        if [[ "$line" =~ ^[[:space:]]*(Options:)[[:space:]]*$ ]] && [[ "$usage_injected" == false ]]; then
            output+=$'\n'
            output+=$(bach::__private::inject_usage_section "$cmd_name" local_subcmds "$script_dir" "$exclude_list" "$has_user_options" custom_usage_lines)
            output+=$'\n'
            usage_injected=true
        fi

        # Inject usage before separator if not yet injected and no Options section
        if [[ "$line" =~ ^-+$ ]] && [[ "$usage_injected" == false ]] && [[ "$has_options_section" == false ]]; then
            output+=$'\n'
            output+=$(bach::__private::inject_usage_section "$cmd_name" local_subcmds "$script_dir" "$exclude_list" "$has_user_options" custom_usage_lines)
            output+=$'\n'
            output+="Options:"$'\n'
            output+="    -h, --help              Show this help message"$'\n'
            output+="    -v, --version           Show version information"$'\n'
            output+=$'\n'
            usage_injected=true
        elif [[ "$line" =~ ^[[:space:]]*(Options:)[[:space:]]*$ ]]; then
            # Add help/version to existing Options section
            output+="${line}"$'\n'
            output+="    -h, --help              Show this help message"$'\n'
            output+="    -v, --version           Show version information"$'\n'
            continue
        fi

        output+="${line}"$'\n'
    done <<< "$doc_string"

    echo -n "$output"
}

# Extract version from documentation string
# Arguments:
#   $1: Documentation string
# Returns:
#   Prints version string
bach::get_version_from_doc() {
    local doc_string="$1"
    local version=""

    # Look for version after the "----" separator
    local after_separator=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^-+$ ]]; then
            after_separator=true
            continue
        fi

        if [[ "$after_separator" == true && -n "$line" ]]; then
            # Extract version (should be in semver format)
            if [[ "$line" =~ ^[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)[[:space:]]*$ ]]; then
                version="${BASH_REMATCH[1]}"
                break
            fi
        fi
    done <<< "$doc_string"

    echo "${version}"
}

# Get the file path for a specific subcommand (private)
# Arguments:
#   $1: Script directory path
#   $2: Subcommand name (may include spaces for nested paths like "stwo foo")
#   $3: Comma-separated list of excluded files/patterns
# Returns:
#   Prints the relative file path for the subcommand
bach::__private::get_subcommand_file() {
    local script_dir="$1"
    local subcmd="$2"
    local exclude_list="$3"

    # Setup exclusion list
    local -a exclude_array=()
    if [[ -n "$exclude_list" ]]; then
        IFS=',' read -ra exclude_array <<< "$exclude_list"
    fi

    # Always exclude certain patterns (but not main.sh - we need nested main.sh files)
    exclude_array+=("const.sh" "*.sh~" "*.swp")

    # Handle nested subcommands (e.g., "stwo foo")
    if [[ "$subcmd" == *" "* ]]; then
        local -a parts=($subcmd)
        local current_dir="$script_dir"
        local path_parts=""

        for ((i=0; i<${#parts[@]}; i++)); do
            local part="${parts[$i]}"

            # If this is the last part, check for file
            if [[ $i -eq $((${#parts[@]} - 1)) ]]; then
                # Check for .sh file
                if [[ -f "$current_dir/${part}.sh" && -x "$current_dir/${part}.sh" ]]; then
                    if ! bach::__private::is_excluded "$current_dir/${part}.sh" "${exclude_array[@]}"; then
                        echo "${path_parts}${part}.sh"
                        return
                    fi
                fi

                # Check for file without extension
                if [[ -f "$current_dir/${part}" && -x "$current_dir/${part}" ]]; then
                    if ! bach::__private::is_excluded "$current_dir/${part}" "${exclude_array[@]}"; then
                        echo "${path_parts}${part}"
                        return
                    fi
                fi

                # Check for directory with main.sh
                if [[ -d "$current_dir/${part}" ]]; then
                    if [[ -f "$current_dir/${part}/main.sh" && -x "$current_dir/${part}/main.sh" ]]; then
                        if ! bach::__private::is_excluded "$current_dir/${part}/main.sh" "${exclude_array[@]}"; then
                            echo "${path_parts}${part}/main.sh"
                            return
                        fi
                    elif [[ -f "$current_dir/${part}/main" && -x "$current_dir/${part}/main" ]]; then
                        if ! bach::__private::is_excluded "$current_dir/${part}/main" "${exclude_array[@]}"; then
                            echo "${path_parts}${part}/main"
                            return
                        fi
                    fi
                fi
            else
                # Intermediate directory
                current_dir="$current_dir/${part}"
                path_parts="${path_parts}${part}/"
            fi
        done
        return
    fi

    # Single-level subcommand (original logic)
    # Check for .sh file
    if [[ -f "$script_dir/${subcmd}.sh" && -x "$script_dir/${subcmd}.sh" ]]; then
        if ! bach::__private::is_excluded "$script_dir/${subcmd}.sh" "${exclude_array[@]}"; then
            echo "${subcmd}.sh"
            return
        fi
    fi

    # Check for file without extension
    if [[ -f "$script_dir/${subcmd}" && -x "$script_dir/${subcmd}" ]]; then
        if ! bach::__private::is_excluded "$script_dir/${subcmd}" "${exclude_array[@]}"; then
            echo "${subcmd}"
            return
        fi
    fi

    # Check for directory with main.sh
    if [[ -d "$script_dir/${subcmd}" ]]; then
        if [[ -f "$script_dir/${subcmd}/main.sh" && -x "$script_dir/${subcmd}/main.sh" ]]; then
            if ! bach::__private::is_excluded "$script_dir/${subcmd}/main.sh" "${exclude_array[@]}"; then
                echo "${subcmd}/main.sh"
                return
            fi
        elif [[ -f "$script_dir/${subcmd}/main" && -x "$script_dir/${subcmd}/main" ]]; then
            if ! bach::__private::is_excluded "$script_dir/${subcmd}/main" "${exclude_array[@]}"; then
                echo "${subcmd}/main"
                return
            fi
        fi
    fi
}

# Build complete usage documentation with auto-injected subcommands
# Arguments:
#   $1: Documentation string
#   $2: Script directory path (where to look for subcommands)
#   $3: Comma-separated list of excluded files/patterns (optional)
#   $4: Command name (optional, defaults to script basename)
# Returns:
#   Prints complete documentation with injected subcommands
bach::build_documentation() {
    local doc_string="$1"
    local script_dir="$2"
    local exclude_list="${3:-}"
    local cmd_name="${4:-$(basename "$0" .sh)}"

    # If this is a main.sh file, use parent directory name as command name
    if [[ "$(basename "$0")" == "main.sh" && "$cmd_name" == "main" ]]; then
        cmd_name="$(basename "$(cd "$(dirname "$0")" && pwd)")"
    fi

    # Process and filter subcommands
    local -a subcommands=()
    bach::__private::process_and_filter_subcommands "$script_dir" "$exclude_list" subcommands

    # Detect sections
    local has_usage_section=false
    local has_options_section=false
    local has_user_options=false
    bach::__private::detect_sections_and_options "$doc_string" \
        has_usage_section has_options_section has_user_options

    # Process the docstring (usage will be injected at the right position)
    local output=$(bach::__private::process_docstring "$doc_string" "$cmd_name" subcommands "$script_dir" "$exclude_list" "$has_usage_section" "$has_options_section" "$has_user_options")

    echo -n "$output"
}

# Inject subcommands into usage section (private)
# Arguments:
#   $1: Script directory path
#   $2: Indentation to use
#   $3: Reference to exclude array
# Returns:
#   Prints subcommand lines
bach::__private::inject_subcommands() {
    local script_dir="$1"
    local indent="$2"
    local -n exclude_ref="$3"

    local output=""

    # Convert exclude array to comma-separated string
    local exclude_list=""
    if [[ ${#exclude_ref[@]} -gt 0 ]]; then
        local IFS=','
        exclude_list="${exclude_ref[*]}"
    fi

    # Get available subcommands using the internal function
    local -a subcommands=()
    while IFS= read -r cmd; do
        [[ -n "$cmd" ]] && subcommands+=("$cmd")
    done < <(bach::__private::get_available_subcommands "$script_dir" "$exclude_list")

    # Sort and output subcommands
    if [[ ${#subcommands[@]} -gt 0 ]]; then
        IFS=$'\n' sorted=($(sort <<<"${subcommands[*]}"))
        unset IFS

        for cmd in "${sorted[@]}"; do
            output+="${indent}    ${cmd}"$'\n'
        done
    fi

    echo -n "$output"
}

# Print documentation to stdout
# Arguments:
#   $1: Documentation string
bach::print_doc() {
    echo "$1"
}

# Print version to stdout
# Arguments:
#   $1: Documentation string
bach::print_version() {
    local doc_string="$1"
    local version=$(bach::get_version_from_doc "$doc_string")
    echo "${version}"
}

# Resolve docstring with subcommands and options (PUBLIC API)
# Arguments:
#   $1: Documentation string
#   $2: Command name
#   $3: Newline-separated list of subcommands (from bach::get_subcommands)
# Returns:
#   Prints resolved documentation with usage section and help/version options
bach::resolve_docstring() {
    local doc_string="$1"
    local cmd_name="$2"
    local subcommands_list="$3"

    # Convert newline-separated list to array
    local -a subcommands=()
    while IFS= read -r cmd; do
        [[ -n "$cmd" ]] && subcommands+=("$cmd")
    done <<< "$subcommands_list"

    # Detect sections
    local has_usage_section=false
    local has_options_section=false
    local has_user_options=false
    bach::__private::detect_sections_and_options "$doc_string" \
        has_usage_section has_options_section has_user_options

    # Process the docstring (usage will be injected at the right position)
    local output=$(bach::__private::process_docstring "$doc_string" "$cmd_name" subcommands "" "" "$has_usage_section" "$has_options_section" "$has_user_options")

    echo -n "$output"
}

# Export functions
export -f bach::get_version_from_doc
export -f bach::__private::is_excluded
export -f bach::__private::has_executable_main
export -f bach::__private::get_available_subcommands
export -f bach::__private::process_and_filter_subcommands
export -f bach::__private::detect_sections_and_options
export -f bach::__private::expand_nested_subcommands
export -f bach::__private::inject_usage_section
export -f bach::__private::process_docstring
export -f bach::build_documentation
export -f bach::resolve_docstring
export -f bach::__private::inject_subcommands
export -f bach::__private::get_subcommand_file
export -f bach::print_doc
export -f bach::print_version
