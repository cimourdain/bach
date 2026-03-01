#!/bin/bash

# Global associative array for storing parsed options
# Can be overridden by setting __ARGS_VAR_NAME before sourcing this library
__ARGS_VAR_NAME="${__ARGS_VAR_NAME:-__ARGS}"

# Initialize the global args array if not already declared
if ! declare -p "${__ARGS_VAR_NAME}" &>/dev/null; then
    declare -gA "${__ARGS_VAR_NAME}"
fi

# Prevent re-sourcing if functions already declared
if declare -F bach::parse_args::from_docstring &>/dev/null && \
   declare -F bach::parse_args::is_help_requested &>/dev/null && \
   declare -F bach::parse_args::is_version_requested &>/dev/null; then
    return 0
fi

# Extract version from documentation string
# Arguments:
#   $1: Documentation string
# Returns:
#   Version string (e.g., "1.2.3")
bach::parse_args::get_version_from_doc() {
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

# Extract valid flags and options from documentation (private)
# Arguments:
#   $1: Documentation string
#   $2: Name reference to valid_flags associative array
#   $3: Name reference to valid_options associative array
#   $4: Name reference to flag_defaults associative array
#   $5: Name reference to option_defaults associative array
bach::parse_args::__private::extract_valid_options() {
    local doc_string="$1"
    local -n vf="$2"
    local -n vo="$3"
    local -n fd="$4"
    local -n od="$5"

    local in_options_section=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*Options:[[:space:]]*$ ]]; then
            in_options_section=true
            continue
        fi

        [[ "$in_options_section" == true && "$line" =~ ^-+$ ]] && break

        if [[ "$in_options_section" == true && -n "$line" ]]; then
            # Strip comment
            local cleaned_line="$line"
            [[ "$line" =~ ^([^#]*)#.*$ ]] && cleaned_line="${BASH_REMATCH[1]}"
            [[ -z "${cleaned_line// /}" ]] && continue

            # Split by comma
            local -a parts=()
            local temp_line="$cleaned_line"
            while [[ "$temp_line" =~ ^[[:space:]]*([^,]*),(.*)$ ]]; do
                local part="${BASH_REMATCH[1]%%*( )}"
                parts+=("$part")
                temp_line="${BASH_REMATCH[2]}"
            done
            temp_line="${temp_line%%*( )}"
            [[ -n "$temp_line" ]] && parts+=("$temp_line")

            # Parse format
            local short_flag="" long_flag="" requires_value=false
            local has_default=false default_value="" idx=0

            # Check first part for short flag
            if [[ "${parts[0]}" =~ ^[[:space:]]*-([a-z])$ ]]; then
                short_flag="${BASH_REMATCH[1]}"
                idx=1
            fi

            # Next part should be long flag
            if [[ ${idx} -lt ${#parts[@]} ]]; then
                if [[ "${parts[$idx]}" =~ ^[[:space:]]*--([a-z_-]+)=$ ]]; then
                    long_flag="${BASH_REMATCH[1]}"
                    requires_value=true
                    ((idx++))
                elif [[ "${parts[$idx]}" =~ ^[[:space:]]*--([a-z_-]+)$ ]]; then
                    long_flag="${BASH_REMATCH[1]}"
                    ((idx++))
                fi
            fi

            [[ -z "$long_flag" ]] && continue

            # Parse remaining for default/enum
            while [[ ${idx} -lt ${#parts[@]} ]]; do
                local part="${parts[$idx]}"
                if [[ "$part" =~ ^[[:space:]]*enum=\"([^\"]*)\"[[:space:]]*$ ]]; then
                    :  # Enum not used yet
                elif [[ "$part" =~ ^[[:space:]]*default=\"([^\"]*)\"[[:space:]]*$ ]]; then
                    has_default=true
                    default_value="${BASH_REMATCH[1]}"
                else
                    break
                fi
                ((idx++))
            done

            # Register the flag/option
            if [[ "$requires_value" == true ]]; then
                vo["--${long_flag}"]="${long_flag}"
                [[ "$has_default" == true ]] && od["${long_flag}"]="$default_value"
            else
                [[ -n "$short_flag" ]] && vf["-${short_flag}"]="${long_flag}"
                vf["--${long_flag}"]="${long_flag}"
                if [[ "$has_default" == true ]]; then
                    fd["${long_flag}"]="$default_value"
                else
                    fd["${long_flag}"]="false"
                fi
            fi
        fi
    done <<< "$doc_string"
}

# Parse command line arguments (private)
# Arguments:
#   $1: Name reference to args_array
#   $2: Name reference to valid_flags
#   $3: Name reference to valid_options
#   $4: Name reference to path_args array
#   $@: Arguments to parse
# Returns:
#   0 if parsed successfully, sets seen_path_arg_ref to true/false
bach::parse_args::__private::parse_command_line() {
    local -n aa="$1"
    local -n vf="$2"
    local -n vo="$3"
    local -n pa="$4"
    shift 4

    local seen_path_arg=false
    while [[ $# -gt 0 ]]; do
        local arg="$1"
        local handled=false

        if [[ "$seen_path_arg" == true ]]; then
            pa+=("$arg")
            shift
            continue
        fi

        if [[ "$arg" =~ ^- ]]; then
            # Long option with value: --option=value
            if [[ "$arg" =~ ^--([a-zA-Z0-9-]+)=(.+)$ ]]; then
                local opt_name="${BASH_REMATCH[1]}"
                local opt_value="${BASH_REMATCH[2]}"
                if [[ -n "${vo[--${opt_name}]}" ]]; then
                    aa["${opt_name}"]="${opt_value}"
                    handled=true
                fi
            # Long flag: --flag
            elif [[ "$arg" =~ ^--([a-zA-Z0-9-]+)$ ]]; then
                local flag_name="${BASH_REMATCH[1]}"
                if [[ -n "${vf[--${flag_name}]}" ]]; then
                    aa["${flag_name}"]="true"
                    handled=true
                fi
            # Short flags: -a or -abc
            elif [[ "$arg" =~ ^-([a-zA-Z]+)$ ]]; then
                local flags="${BASH_REMATCH[1]}"
                local all_valid=true
                for ((i=0; i<${#flags}; i++)); do
                    [[ -z "${vf[-${flags:$i:1}]}" ]] && all_valid=false && break
                done
                if [[ "$all_valid" == true ]]; then
                    for ((i=0; i<${#flags}; i++)); do
                        local long_name="${vf[-${flags:$i:1}]}"
                        aa["${long_name}"]="true"
                    done
                    handled=true
                fi
            fi

            [[ "$handled" == false ]] && pa+=("$arg") && seen_path_arg=true
        else
            pa+=("$1")
            seen_path_arg=true
        fi
        shift
    done

    return 0
}

# Set default values for flags and options (private)
# Arguments:
#   $1: Name reference to args_array
#   $2: Name reference to flag_defaults
#   $3: Name reference to option_defaults
bach::parse_args::__private::set_default_values() {
    local -n aa="$1"
    local -n fd="$2"
    local -n od="$3"

    for flag in "${!fd[@]}"; do
        aa["${flag}"]="${fd[$flag]}"
    done
    for opt in "${!od[@]}"; do
        aa["${opt}"]="${od[$opt]}"
    done
}

# Handle help and version requests (private)
# Arguments:
#   $1: Name reference to args_array
#   $2: Name reference to path_args
#   $3: Documentation string (already built with subcommands)
# Returns:
#   0 if no help/version, 2 for help, 3 for version
bach::parse_args::__private::handle_help_version() {
    local -n aa="$1"
    local -n pa="$2"
    local doc_string="$3"

    [[ ${#pa[@]} -gt 0 ]] && return 0

    if [[ "${aa[help]}" == "true" ]]; then
        bach log --debug "Help requested, printing documentation string"
        echo "$doc_string"
        return 2
    elif [[ "${aa[version]}" == "true" ]]; then
        bach log --debug "Version requested, printing version"
        local version=$(bach::parse_args::get_version_from_doc "$doc_string")
        echo "${version}"
        return 3
    fi

    return 0
}

# Parse arguments and separate options from path arguments
# Arguments:
#   $1: Documentation string (already built using bach::build_documentation)
#   $@: All arguments to parse
# Returns:
#   0 - Parsing successful, continue execution
#   1 - Parse error occurred
#   2 - Help was requested and printed
#   3 - Version was requested and printed
# Side Effects:
#   Sets global associative array with parsed options
#   Stores path arguments in global __PATH_ARGS array
bach::parse_args::from_docstring() {
    local doc_string="$1"
    bach log --verbose "Parse arguments using docstring: $doc_string"
    shift 1

    bach log --verbose "Arguments to match against docstring: $@"

    local -n args_array="${__ARGS_VAR_NAME}"
    local -a path_args=()
    local -A valid_flags=()
    local -A valid_options=()
    local -A flag_defaults=()
    local -A option_defaults=()

    # Extract valid flags and options from documentation
    bach::parse_args::__private::extract_valid_options "$doc_string" \
        valid_flags valid_options flag_defaults option_defaults

    # Auto-inject help and version flags
    valid_flags["-h"]="help"
    valid_flags["--help"]="help"
    flag_defaults["help"]="false"
    valid_flags["-v"]="version"
    valid_flags["--version"]="version"
    flag_defaults["version"]="false"

    # Set default values
    bach::parse_args::__private::set_default_values args_array flag_defaults option_defaults

    # Parse command line arguments
    bach::parse_args::__private::parse_command_line args_array valid_flags valid_options path_args "$@"

    # Store path arguments in global array
    bach log --verbose "Store path arguments to global variable __PATH_ARGS"
    declare -ga __PATH_ARGS=("${path_args[@]}")

    # Handle help/version if no path args
    bach::parse_args::__private::handle_help_version args_array path_args "$doc_string"
    return $?
}

# Check if help flag is set
bach::parse_args::is_help_requested() {
    local -n args_array="${__ARGS_VAR_NAME}"
    [[ "${args_array[help]}" == "true" ]]
}

# Check if version flag is set
bach::parse_args::is_version_requested() {
    local -n args_array="${__ARGS_VAR_NAME}"
    [[ "${args_array[version]}" == "true" ]]
}

# Parse arguments without docstring validation
#
# A simpler argument parser that doesn't require a docstring.
# Automatically detects flags (boolean) and options (key=value).
# Does not validate against documentation.
#
# Arguments:
#   $@: All arguments to parse
#
# Returns:
#   0 - Parsing successful
#
# Side Effects:
#   Sets global associative array with parsed options
#   Stores path arguments in global __PATH_ARGS array
#
# Parsing Rules:
#   - Flags: -f, --flag (sets to "true")
#   - Options: --key=value, --key value (sets key to value)
#   - Merged flags: -abc (sets a, b, c to "true")
#   - Path args: Everything after first non-option or after --
bach::parse_args() {
    local -n args_array="${__ARGS_VAR_NAME}"
    local -a path_args=()
    local in_path_args=false

    # Clear previous values
    for key in "${!args_array[@]}"; do
        unset args_array["$key"]
    done

    while [[ $# -gt 0 ]]; do
        local arg="$1"

        # Check if we've hit the path arguments section
        if [[ "$in_path_args" == true ]]; then
            path_args+=("$1")
            shift
            continue
        fi

        # Double dash means rest are path args
        if [[ "$arg" == "--" ]]; then
            in_path_args=true
            shift
            continue
        fi

        # Long option with equals: --key=value
        if [[ "$arg" =~ ^--([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            args_array["$key"]="$value"
            shift
            continue
        fi

        # Long flag or option: --key
        if [[ "$arg" =~ ^--(.+)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            # Check if next arg is a value (doesn't start with -)
            if [[ $# -gt 1 && ! "$2" =~ ^- ]]; then
                args_array["$key"]="$2"
                shift 2
            else
                args_array["$key"]="true"
                shift
            fi
            continue
        fi

        # Short option(s): -f or -abc
        if [[ "$arg" =~ ^-(.+)$ ]]; then
            local flags="${BASH_REMATCH[1]}"
            # Check if it's a single flag with a value
            if [[ ${#flags} -eq 1 && $# -gt 1 && ! "$2" =~ ^- ]]; then
                args_array["$flags"]="$2"
                shift 2
            else
                # Split into individual flags
                for ((i=0; i<${#flags}; i++)); do
                    local flag="${flags:$i:1}"
                    args_array["$flag"]="true"
                done
                shift
            fi
            continue
        fi

        # If we get here, it's a path argument
        path_args+=("$arg")
        in_path_args=true
        shift
    done

    # Store path arguments in global array
    declare -ga __PATH_ARGS=("${path_args[@]}")

    return 0
}

# Export functions
export -f bach::parse_args::get_version_from_doc
export -f bach::parse_args::from_docstring
export -f bach::parse_args
export -f bach::parse_args::is_help_requested
export -f bach::parse_args::is_version_requested
