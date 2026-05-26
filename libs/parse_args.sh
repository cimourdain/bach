#!/bin/bash

################################################################################
# Arguments Parsing
################################################################################
# Description:
#   Parse command line arguments, with or without specification, into global
#   variables.
#
# Usage:
#   source /path/to/parse_args.sh
#   bach parse_args "$@"
#
# Dependencies:
#   - bash 4.0+
#   - bach function (bach.sh) for logging
#
# Author: BACHCLI Project
# Version: 1.0.0
################################################################################


# Prevent re-sourcing if functions already declared
if declare -F bach::parse_args &>/dev/null && \
   declare -F bach::parse_args::config::set_parsed_args_global_var_name &>/dev/null && \
   declare -F bach::parse_args::from_spec &>/dev/null; then
    return 0
fi

################################################################################
# Set the name of the global variable receiving the parsed arguments
# Arguments:
#   $1 - var_name: Name of the global associative array
# Globals:
#   __BACH_PARSE_ARGS_CONFIG[parsed_args_var_name] - Updated
# Returns:
#   0 on success, 1 if the name is empty
################################################################################
bach::parse_args::config::set_parsed_args_global_var_name() {
    local parsed_args_var_name
    parsed_args_var_name="${1:-""}"

    if [[ -z "${parsed_args_var_name}" ]]; then
        bach log --error "Parsed args global variable name cannot be empty"
        return 1
    fi

    bach log --debug "Parsed args global variable name set to ${parsed_args_var_name}"
    __BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]="$parsed_args_var_name"

    parsed_args_var_name="${__BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]}"
    # local -n parsed_args_var_name_ref="${parsed_args_var_name}"

    if [[ -z "${!parsed_args_var_name}" ]]; then
        bach log --verbose "Initializing ${parsed_args_var_name} to empty associative array"
        declare -gA "${parsed_args_var_name}"
    fi
    return 0
}
export -f bach::parse_args::config::set_parsed_args_global_var_name

if [[ -z "${__BACH_PARSE_ARGS_CONFIG}" ]]; then
    declare -gA __BACH_PARSE_ARGS_CONFIG=()
    bach::parse_args::config::set_parsed_args_global_var_name "__BACH_PARSED_ARGS"
    bach log --verbose --array-ref="${__BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]}"
fi


################################################################################
# Parse one command line element (private)
# Handles --key=value options, flags and positional arguments, and stores them in the parsed arguments variable.
# Arguments:
#   $1 - element: Element to parse
#   $2 - next_element: Following element (default: "")
# Globals:
#   __BACH_PARSE_ARGS_CONFIG[parsed_args_var_name] - Name of the parsed arguments variable (updated)
# Returns:
#   0 on success
################################################################################
bach::parse_args::__private::parse_element() {
    local element="$1"
    local next_element="${2:-""}"

    local -n parsed_args_var_ref="${__BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]}"
    local -n parsed_options_associative_array_ref="${parsed_args_var_ref["options"]}"
    local -n parsed_rest_associative_array_ref="${parsed_args_var_ref["rest"]}"

    bach log --verbose "Parse element: %s" "$element"
    if [[ "$element" =~ ^--([^=]+)=(.*)$ ]]; then
        local option_key="${BASH_REMATCH[1]}"
        local option_value="${BASH_REMATCH[2]}"
        bach log --verbose "Parsed long option: --${option_key} with value: ${option_value}"
        parsed_options_associative_array_ref["$option_key"]="$option_value"
    elif [[ "$element" =~ ^--(.+)$ ]]; then
        local flag_long_key="${BASH_REMATCH[1]}"
        bach log --verbose "Parsed long flag: --${flag_long_key}"
        parsed_options_associative_array_ref["$flag_long_key"]=true
    elif [[ "$element" =~ ^-([[:alnum:]]{1,})$ ]]; then
        local flags_short_keys="${BASH_REMATCH[1]}"
        bach log --verbose "Split short flags keys from: %s" "${element}"
        local flag_short_key
        for ((i=0; i<${#flags_short_keys}; i++)); do
            flag_short_key="${flags_short_keys:i:1}"
            bach log --verbose "[${i}]Parsed short flag: -${flag_short_key}"
            parsed_options_associative_array_ref["$flag_short_key"]=true
        done
    else
        bach log --verbose "Rest argument: ${element}"
        parsed_rest_associative_array_ref+=("$element")
    fi
    bach log --verbose "End of parsing of: %s" "$element"
    return 0
}

################################################################################
# Log the content of the parsed arguments variables at debug level
# Arguments:
#   None
# Globals:
#   __BACH_PARSE_ARGS_CONFIG[parsed_args_var_name] - Name of the parsed arguments variable
# Outputs:
#   Debug logs on stderr
# Returns:
#   0 always
################################################################################
bach::parse_args::debug_parsed() {
    local parsed_args_var_name="${__BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]}"
    local -n parsed_args_var_ref="${parsed_args_var_name}"
    bach log --debug "Inspect keys of parsed args global variable %s." "${parsed_args_var_name}"
    bach log --debug --array-ref="${parsed_args_var_name}"

    bach log --debug "Get parsed options from global variable: %s" "${parsed_args_var_ref["options"]}"
    bach log --debug --array-ref="${parsed_args_var_ref["options"]}"

    bach log --debug "Get parsed rest arguments from global variable: %s" "${parsed_args_var_ref["rest"]}"
    bach log --debug --array-ref="${parsed_args_var_ref["rest"]}"
}
export -f bach::parse_args::debug_parsed

################################################################################
# Reset the parsed arguments variables (private)
# Arguments:
#   None
# Globals:
#   __BACH_PARSE_ARGS_CONFIG[parsed_args_var_name] - Name of the parsed arguments variable (reset)
# Returns:
#   0 always
################################################################################
bach::parse_args::__private::reset_parsed_args_global_var() {
    bach log --verbose "Reset parsed args global variable"

    local parsed_args_global_associative_array_var_name="${__BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]}"
    local parsed_options_global_associative_array_var_name="${parsed_args_global_associative_array_var_name}_options"
    local parsed_rest_global_associative_array_var_name="${parsed_args_global_associative_array_var_name}_rest"

    # Unset before declaring: declaring an existing array would keep the values of the previous parsing
    unset "${parsed_options_global_associative_array_var_name}" "${parsed_rest_global_associative_array_var_name}"
    declare -gA "${parsed_options_global_associative_array_var_name}"
    declare -ga "${parsed_rest_global_associative_array_var_name}"

    local -n parsed_args_global_associative_array="${__BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]}"
    parsed_args_global_associative_array=(
        ["options"]="${parsed_options_global_associative_array_var_name}"
        ["rest"]="${parsed_rest_global_associative_array_var_name}"
    )
}

################################################################################
# Parse command line arguments without specification
# Options, flags and positional arguments are stored in the parsed arguments variable.
# Arguments:
#   $@ - Command line arguments to parse
# Globals:
#   __BACH_PARSE_ARGS_CONFIG[parsed_args_var_name] - Name of the parsed arguments variable (updated)
# Returns:
#   0 always
################################################################################
bach::parse_args() {

    bach log --verbose "Parse arguments without specification."

    bach::parse_args::__private::reset_parsed_args_global_var

    local -a elements=("$@")
    local element_idx
    for ((element_idx=0; element_idx<${#elements[@]}; element_idx++)); do
        # echo "DEBUG:Inspect argument with index ${element_idx}/${#elements[@]}: ${elements[element_idx]}" >&2
        bach::parse_args::__private::parse_element "${elements[element_idx]}" "${elements[element_idx+1]:-""}"
    done

    return 0
}
export -f bach::parse_args

################################################################################
# Parse command line arguments against an arguments specification
# Arguments:
#   $1 - arguments_spec: Specification (docstring) of the expected arguments
#   $@ - Command line arguments to parse
# Globals:
#   __BACH_PARSE_ARGS_CONFIG[parsed_args_var_name] - Name of the parsed arguments variable (updated)
# Returns:
#   0 on success
################################################################################
bach::parse_args::from_spec() {
    local arguments_spec
    arguments_spec="$1"
    shift

    bach::parse_args::__private::reset_parsed_args_global_var

    local current_arg
    while [[ $# -gt 0 ]]; do
        current_arg="$1"
        bach::parse_args::__private::parse_element "${arguments_spec}" "$current_arg" "${2:-""}"
        shift
    done
    return 0
}

export -f bach::parse_args::from_spec


# bach::parse_args::_private::get_next_spec_part() {
#     local spec_string
#     spec_string="$1"

#     local next_part_leading_char_index
#     next_part_leading_char_index=0

#     spec_string=$(bach bash_utils::string::trim_leading_whitespaces "$spec_string")
#     if [[ -z "$spec_string" || "$spec_string" == "" ]]; then
#         return 2
#     elif [[ "${#spec_string}" -ne "${#1}" ]]; then
#         local diff=$(( ${#1} - ${#spec_string} ))
#         next_part_leading_char_index=$diff
#     fi

#     local next_part_leading_char
#     next_part_leading_char="${spec_string:0:1}"

#     local -A substring_matching=(
#         ["<"]=">"
#         ["["]="]"
#         ["("]=")"
#     )
#     local -a possible_closing_substrings
#     if [[ -n "${substring_matching[$next_part_leading_char]}" ]]; then
#         possible_closing_substrings+=("${substring_matching[$next_part_leading_char]}")
#     else
#         possible_closing_substrings+=(" ")
#     fi

#     local next_part_closing_char_idx
#     next_part_closing_char_idx=$(bach bash_utils::string::index_of_any_substring "$spec_string" possible_closing_substrings "0")
#     if [[ -n "$next_part_closing_char_idx" && "$next_part_closing_char_idx" -ge 0 ]]; then
#         local next_part_length
#         next_part_length=$(( next_part_leading_char_index + next_part_closing_char_idx + ${#closing_substring} ))

#         local substring
#         substring="${spec_string:0:next_part_length}"
#         bach log --verbose "In string: '${spec_string}', found substring: '${substring}'"

#         local trimmed_substring
#         trimmed_substring="${spec_string:next_part_length}"
#         if [[ "$trimmed_substring" == "..." ]]; then
#             bach log --verbose "In string: '${spec_string}', return code 1 to indicate this is the last part as '>...' indicates rest of string is one part."
#             next_part_length=$(( next_part_length + 3 ))
#             echo "${next_part_length}"
#             return 1
#         fi
#         echo "${next_part_length}"
#         return 0
#     elif [[ -z "${substring_matching[$next_part_leading_char]}" ]];then
#         bach log --verbose "In string: '${spec_string}', the leading character '${next_part_leading_char}' is not a recognized opening character and no space found, return the string length."
#         echo "${#spec_string}"
#         return 0
#     fi

#     bach log --error "No closing character found for spec part starting with '${next_part_leading_char}' in string: '${spec_string}'"
#     echo "-1"
#     return 3
# }


# bach::parse_args::from_spec() {
#     bach log --verbose "Parse arguments against specification."
#     local specification_string
#     specification_string="${1:-""}"
#     # TODO: handle [] () a-Z <> <>...

#     local pattern_matching_result
#     bach log --verbose "Grep pattern matching result before running grep from %s with args %s" "${specification_string}" "$@"
#     if pattern_matching_result=$(grep -P -o "${specification_string}" "$@" 2>/dev/null); then
#         bach log --verbose "Pattern matching result: ${pattern_matching_result}"
#     else
#         pattern_matching_result=""
#         bach log --warning "No pattern matching result found using regex \"%s\" with arguments \"%s\"" "${specification_string}" "$@"
#         return 1
#     fi

#     local unparsed_spec_string="${specification_string}"
#     local current_spec_part=""
#     local next_substring_length
#     local next_substring_length_exit_code
#     while [[ $next_substring_length -ge 0 ]]; do
#         bach log --verbose "Inspect unparsed spec string: ${unparsed_spec_string}, pattern matching result: ${pattern_matching_result}"
#         next_substring_length=$(bach::parse_args::_private::get_next_spec_part "$unparsed_spec_string")
#         next_substring_length_exit_code=$?

#         # case "$next_substring_length_exit_code" in
#         #     0|1)
#         #         current_spec_part="${unparsed_spec_string:0:next_substring_length}"
#         #         current_spec_part=$(bach bash_utils::string::trim_leading_whitespaces "$current_spec_part")
#         #         unparsed_spec_string="${unparsed_spec_string:next_substring_length}"
#         #         unparsed_spec_string=$(bach bash_utils::string::trim_leading_whitespaces "$unparsed_spec_string")
#         #         bach log --debug "Current spec part: '${current_spec_part}', remaining spec string: '${unparsed_spec_string}'"
#         #         ;;
#         #     2)
#         #         bach log --debug "No more spec parts as no leading character was found, treating entire remaining string as one part."
#         #         break
#         #         ;;
#         #     3)
#         #         bach log --error "No closing character found for current spec part: '${current_spec_part}', treating entire remaining string as one part."
#         #         return 1
#         #         ;;
#         # esac
#     done
#     return 0
# }
# export -f bach::parse_args::from_spec



# # Extract version from documentation string
# # Arguments:
# #   $1: Documentation string
# # Returns:
# #   Version string (e.g., "1.2.3")
# bach::parse_args::get_version_from_doc() {
#     local doc_string="$1"
#     local version=""

#     # Look for version after the "----" separator
#     local after_separator=false
#     while IFS= read -r line; do
#         if [[ "$line" =~ ^-+$ ]]; then
#             after_separator=true
#             continue
#         fi

#         if [[ "$after_separator" == true && -n "$line" ]]; then
#             # Extract version (should be in semver format)
#             if [[ "$line" =~ ^[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)[[:space:]]*$ ]]; then
#                 version="${BASH_REMATCH[1]}"
#                 break
#             fi
#         fi
#     done <<< "$doc_string"

#     echo "${version}"
# }

# # Extract valid flags and options from documentation (private)
# # Arguments:
# #   $1: Documentation string
# #   $2: Name reference to valid_args array
# #   $@: Arguments to parse
# bach::parse_args::__private::extract_valid_args() {
#     local doc_string="$1"
#     local -n vf="$2"

#     shift 2
#     local -a args_to_parse=("$@")

#     local in_usage_section=false
#     local usage_line_delimiter=" "
#     local cleaned_line
#     local -a cleaned_line_without_cmd=()
#     local usage_line_item
#     while IFS= read -r line; do
#         if [[ "$line" =~ ^[[:space:]]*Usage:[[:space:]]*$ ]]; then
#             in_usage_section=true
#             continue
#         fi
#         if [[ "$in_usage_section" == true && -n "$line" ]]; then
#             # Strip comment
#             cleaned_line="$line"
#             [[ "$line" =~ ^([^#]*)#.*$ ]] && cleaned_line="${BASH_REMATCH[1]}"
#             [[ -z "${cleaned_line// /}" ]] && continue

#             # Strip command name (first word)
#             cleaned_line="${cleaned_line#* }"
#             cleaned_line="${cleaned_line#"${cleaned_line%%[![:space:]]*}"}"


#             for word in $cleaned_line; do
#                 # if <arg>
#                 if [[ $s =~ ^\<[[:alnum:]]+\>$ ]]; then

#                 fi

#                 # if ( ... ) - indicates a required or optional argument, not a flag/option
#                 # if [ ... ] - indicates an optional argument, not a flag/option
#                 # else: hardcoded string, could be a flag/option if it matches args_to_parse
#             done
#             # # split line by space
#             # mapfile -td"$usage_line_delimiter" cleaned_line_array < <(printf '%s%s' "$cleaned_line" "$usage_line_delimiter")

#             # # first part should be command name, rest are args
#             # usage_line_cmd_name="${cleaned_line_array[0]}"
#             # cleaned_line_without_cmd=("${cleaned_line_array[@]:1}")

#             # for ((i=0; i<${#cleaned_line_without_cmd[@]}; i++)); do
#             #     usage_line_item="${cleaned_line_without_cmd[i]}"

#             #     for ((j=0; j<${#args_to_parse[@]}; j++)); do
#             #         local valid_arg="${args_to_parse[j]}"
#             #         if [[ "$arg" == "$valid_arg" ]]; then
#             #             vf["$arg"]="$arg"
#             #         fi
#             #     done
#             # done
#         fi
#     done <<< "$doc_string"
# }

# # Extract valid flags and options from documentation (private)
# # Arguments:
# #   $1: Documentation string
# #   $2: Name reference to valid_flags associative array
# #   $3: Name reference to valid_options associative array
# #   $4: Name reference to flag_defaults associative array
# #   $5: Name reference to option_defaults associative array
# bach::parse_args::__private::extract_valid_options() {
#     local doc_string="$1"
#     local -n vf="$2"
#     local -n vo="$3"
#     local -n fd="$4"
#     local -n od="$5"

#     local in_options_section=false
#     while IFS= read -r line; do
#         if [[ "$line" =~ ^[[:space:]]*Options:[[:space:]]*$ ]]; then
#             in_options_section=true
#             continue
#         fi

#         [[ "$in_options_section" == true && "$line" =~ ^-+$ ]] && break

#         if [[ "$in_options_section" == true && -n "$line" ]]; then
#             # Strip comment
#             local cleaned_line="$line"
#             [[ "$line" =~ ^([^#]*)#.*$ ]] && cleaned_line="${BASH_REMATCH[1]}"
#             [[ -z "${cleaned_line// /}" ]] && continue

#             # Split by comma
#             local -a parts=()
#             local temp_line="$cleaned_line"
#             while [[ "$temp_line" =~ ^[[:space:]]*([^,]*),(.*)$ ]]; do
#                 local part="${BASH_REMATCH[1]%%*( )}"
#                 parts+=("$part")
#                 temp_line="${BASH_REMATCH[2]}"
#             done
#             temp_line="${temp_line%%*( )}"
#             [[ -n "$temp_line" ]] && parts+=("$temp_line")

#             # Parse format
#             local short_flag="" long_flag="" requires_value=false
#             local has_default=false default_value="" idx=0

#             # Check first part for short flag
#             if [[ "${parts[0]}" =~ ^[[:space:]]*-([a-z])$ ]]; then
#                 short_flag="${BASH_REMATCH[1]}"
#                 idx=1
#             fi

#             # Next part should be long flag
#             if [[ ${idx} -lt ${#parts[@]} ]]; then
#                 if [[ "${parts[$idx]}" =~ ^[[:space:]]*--([a-z_-]+)=$ ]]; then
#                     long_flag="${BASH_REMATCH[1]}"
#                     requires_value=true
#                     ((idx++))
#                 elif [[ "${parts[$idx]}" =~ ^[[:space:]]*--([a-z_-]+)$ ]]; then
#                     long_flag="${BASH_REMATCH[1]}"
#                     ((idx++))
#                 fi
#             fi

#             [[ -z "$long_flag" ]] && continue

#             # Parse remaining for default/enum
#             while [[ ${idx} -lt ${#parts[@]} ]]; do
#                 local part="${parts[$idx]}"
#                 if [[ "$part" =~ ^[[:space:]]*enum=\"([^\"]*)\"[[:space:]]*$ ]]; then
#                     :  # Enum not used yet
#                 elif [[ "$part" =~ ^[[:space:]]*default=\"([^\"]*)\"[[:space:]]*$ ]]; then
#                     has_default=true
#                     default_value="${BASH_REMATCH[1]}"
#                 else
#                     break
#                 fi
#                 ((idx++))
#             done

#             # Register the flag/option
#             if [[ "$requires_value" == true ]]; then
#                 vo["--${long_flag}"]="${long_flag}"
#                 [[ "$has_default" == true ]] && od["${long_flag}"]="$default_value"
#             else
#                 [[ -n "$short_flag" ]] && vf["-${short_flag}"]="${long_flag}"
#                 vf["--${long_flag}"]="${long_flag}"
#                 if [[ "$has_default" == true ]]; then
#                     fd["${long_flag}"]="$default_value"
#                 else
#                     fd["${long_flag}"]="false"
#                 fi
#             fi
#         fi
#     done <<< "$doc_string"
# }

# Parse command line arguments (private)
# Arguments:
#   $1: Name reference to args_array
#   $2: Name reference to valid_flags
#   $3: Name reference to valid_options
#   $4: Name reference to path_args array
#   $@: Arguments to parse
# Returns:
#   0 if parsed successfully, sets seen_path_arg_ref to true/false
# bach::parse_args::__private::parse_command_line() {
#     local -n aa="$1"
#     local -n vf="$2"
#     local -n vo="$3"
#     local -n pa="$4"
#     shift 4

#     local seen_path_arg=false
#     while [[ $# -gt 0 ]]; do
#         local arg="$1"
#         local handled=false

#         if [[ "$seen_path_arg" == true ]]; then
#             bach log --verbose "Encountered path argument: $arg, when seen_path_arg is true, adding to path_args."
#             pa+=("$arg")
#             shift
#             continue
#         fi

#         if [[ "$arg" =~ ^- ]]; then
#             # Long option with value: --option=value
#             if [[ "$arg" =~ ^--([a-zA-Z0-9-]+)=(.+)$ ]]; then
#                 local opt_name="${BASH_REMATCH[1]}"
#                 local opt_value="${BASH_REMATCH[2]}"
#                 if [[ -n "${vo[--${opt_name}]}" ]]; then
#                     aa["${opt_name}"]="${opt_value}"
#                     handled=true
#                 fi
#             # Long flag: --flag
#             elif [[ "$arg" =~ ^--([a-zA-Z0-9-]+)$ ]]; then
#                 local flag_name="${BASH_REMATCH[1]}"
#                 if [[ -n "${vf[--${flag_name}]}" ]]; then
#                     aa["${flag_name}"]="true"
#                     handled=true
#                 fi
#             # Short flags: -a or -abc
#             elif [[ "$arg" =~ ^-([a-zA-Z]+)$ ]]; then
#                 local flags="${BASH_REMATCH[1]}"
#                 local all_valid=true
#                 for ((i=0; i<${#flags}; i++)); do
#                     [[ -z "${vf[-${flags:$i:1}]}" ]] && all_valid=false && break
#                 done
#                 if [[ "$all_valid" == true ]]; then
#                     for ((i=0; i<${#flags}; i++)); do
#                         local long_name="${vf[-${flags:$i:1}]}"
#                         aa["${long_name}"]="true"
#                     done
#                     handled=true
#                 fi
#             fi

#             [[ "$handled" == false ]] && pa+=("$arg") && seen_path_arg=true
#         else
#             bach log --verbose "Encountered path argument: $arg, adding to path_args & setting seen_path_arg to true"
#             pa+=("$arg")
#             seen_path_arg=true
#         fi
#         shift
#     done

#     return 0
# }

# Set default values for flags and options (private)
# Arguments:
#   $1: Name reference to args_array
#   $2: Name reference to flag_defaults
#   $3: Name reference to option_defaults
# bach::parse_args::__private::set_default_values() {
#     local -n aa="$1"
#     local -n fd="$2"
#     local -n od="$3"

#     for flag in "${!fd[@]}"; do
#         aa["${flag}"]="${fd[$flag]}"
#     done
#     for opt in "${!od[@]}"; do
#         aa["${opt}"]="${od[$opt]}"
#     done
# }

# Handle help and version requests (private)
# Arguments:
#   $1: Name reference to args_array
#   $2: Name reference to path_args
#   $3: Documentation string (already built with subcommands)
# Returns:
#   0 if no help/version, 2 for help, 3 for version
# bach::parse_args::__private::handle_help_version() {
#     local -n aa="$1"
#     local -n pa="$2"
#     local doc_string="$3"

#     [[ ${#pa[@]} -gt 0 ]] && return 0

#     bach log --debug "As no path arguments were provided, checking for help/version flags."
#     if [[ "${aa[help]}" == "true" ]]; then
#         bach log --debug "Help requested, printing documentation string"
#         echo "$doc_string"
#         return 2
#     elif [[ "${aa[version]}" == "true" ]]; then
#         bach log --debug "Version requested, printing version"
#         local version=$(bach::parse_args::get_version_from_doc "$doc_string")
#         echo "${version}"
#         return 3
#     fi

#     return 0
# }


# # Parse arguments and separate options from path arguments
# # Arguments:
# #   $1: Documentation string (already built using bach::build_documentation)
# #   $@: All arguments to parse
# # Returns:
# #   0 - Parsing successful, continue execution
# #   1 - Parse error occurred
# #   2 - Help was requested and printed
# #   3 - Version was requested and printed
# # Side Effects:
# #   Sets global associative array with parsed options
# #   Stores path arguments in global __PATH_ARGS array
# bach::parse_args::from_docstring() {
#     local doc_string="$1"
#     bach log --verbose "Parse arguments using docstring: $doc_string"
#     shift 1

#     bach log --verbose "Arguments to match against docstring: $@"

#     local -n args_array="${__ARGS_VAR_NAME}"
#     local -a path_args=()
#     local -A valid_flags=()
#     local -A valid_options=()
#     local -A flag_defaults=()
#     local -A option_defaults=()

#     # Extract valid flags and options from documentation
#     bach::parse_args::__private::extract_valid_options "$doc_string" \
#         valid_flags valid_options flag_defaults option_defaults

#     # Auto-inject help and version flags
#     valid_flags["-h"]="help"
#     valid_flags["--help"]="help"
#     flag_defaults["help"]="false"
#     valid_flags["-v"]="version"
#     valid_flags["--version"]="version"
#     flag_defaults["version"]="false"

#     # Set default values
#     bach::parse_args::__private::set_default_values args_array flag_defaults option_defaults

#     # Parse command line arguments
#     bach log --verbose "Parse command line arguments"
#     bach::parse_args::__private::parse_command_line args_array valid_flags valid_options path_args "$@"
#     bach log --verbose --array-ref=path_args "path_args count: ${#path_args[@]}"

#     # Store path arguments in global array
#     bach log --verbose "Store path arguments to global variable __PATH_ARGS"
#     declare -ga __PATH_ARGS=("${path_args[@]}")
#     local path_args_count=${#__PATH_ARGS[@]}
#     bach log --verbose --array-ref=__PATH_ARGS "__PATH_ARGS count: ${path_args_count}"

#     # Handle help/version if no path args
#     bach::parse_args::__private::handle_help_version args_array path_args "$doc_string"
#     local hv_result=$?
#     if [[ $hv_result -ne 0 ]]; then
#         bach log --debug "Help or version was requested and printed, exiting with code 2"
#         return 1
#     fi

#     bach log --warning "TODO: Ensure that path arguments are valid against spec."

#     return 0
# }

# Check if help flag is set
# bach::parse_args::is_help_requested() {
#     local -n args_array="${__ARGS_VAR_NAME}"
#     [[ "${args_array[help]}" == "true" ]]
# }

# # Check if version flag is set
# bach::parse_args::is_version_requested() {
#     local -n args_array="${__ARGS_VAR_NAME}"
#     [[ "${args_array[version]}" == "true" ]]
# }

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
# bach::parse_args() {
#     local -n args_array="${__ARGS_VAR_NAME}"
#     local -a path_args=()
#     local in_path_args=false

#     # Clear previous values
#     for key in "${!args_array[@]}"; do
#         unset args_array["$key"]
#     done

#     while [[ $# -gt 0 ]]; do
#         local arg="$1"

#         # Check if we've hit the path arguments section
#         if [[ "$in_path_args" == true ]]; then
#             path_args+=("$1")
#             shift
#             continue
#         fi

#         # Double dash means rest are path args
#         if [[ "$arg" == "--" ]]; then
#             in_path_args=true
#             shift
#             continue
#         fi

#         # Long option with equals: --key=value
#         if [[ "$arg" =~ ^--([^=]+)=(.*)$ ]]; then
#             local key="${BASH_REMATCH[1]}"
#             local value="${BASH_REMATCH[2]}"
#             args_array["$key"]="$value"
#             shift
#             continue
#         fi

#         # Long flag or option: --key
#         if [[ "$arg" =~ ^--(.+)$ ]]; then
#             local key="${BASH_REMATCH[1]}"
#             # Check if next arg is a value (doesn't start with -)
#             if [[ $# -gt 1 && ! "$2" =~ ^- ]]; then
#                 args_array["$key"]="$2"
#                 shift 2
#             else
#                 args_array["$key"]="true"
#                 shift
#             fi
#             continue
#         fi

#         # Short option(s): -f or -abc
#         if [[ "$arg" =~ ^-(.+)$ ]]; then
#             local flags="${BASH_REMATCH[1]}"
#             # Check if it's a single flag with a value
#             if [[ ${#flags} -eq 1 && $# -gt 1 && ! "$2" =~ ^- ]]; then
#                 args_array["$flags"]="$2"
#                 shift 2
#             else
#                 # Split into individual flags
#                 for ((i=0; i<${#flags}; i++)); do
#                     local flag="${flags:$i:1}"
#                     args_array["$flag"]="true"
#                 done
#                 shift
#             fi
#             continue
#         fi

#         # If we get here, it's a path argument
#         path_args+=("$arg")
#         in_path_args=true
#         shift
#     done

#     # Store path arguments in global array
#     declare -ga __PATH_ARGS=("${path_args[@]}")

#     return 0
# }

# # Export functions
# export -f bach::parse_args::get_version_from_doc
# export -f bach::parse_args::from_docstring
# export -f bach::parse_args
# export -f bach::parse_args::is_help_requested
# export -f bach::parse_args::is_version_requested
