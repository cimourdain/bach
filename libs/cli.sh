#!/bin/bash

# Prevent re-sourcing if functions already declared
if declare -F bach::cli::get_subcommands &>/dev/null && declare -F bach::cli::execute_subcommand &>/dev/null; then
    return 0
fi

if [[ -z "${__BACH_CLI_CONFIG}" ]]; then
    declare -ga __BACH_CLI_PATH_ARGS=() # Global array to store path arguments for subcommand execution

    declare -gA __BACH_CLI_CONFIG=(
        [commands_scripts_extensions]=",.sh," # Default log level for program execution, can be overridden by setting the BACH_LOG_LEVEL environment variable or by passing a log level as the first argument when invoking a bach function
        [command_directory_main_file_root_name]="main" # Default name for main command file without extension, e.g. "main" for "main.sh"
        [exclude_list]="const.sh,statics.sh,lib" # Default comma-separated list of files/directories to exclude when searching for subcommands
        [commands_path_args_array_global_var_name]="__BACH_CLI_PATH_ARGS" # Name of the global variable to store path arguments for subcommand execution
    )
fi

# Helper function to check if item is excluded (private)
bach::cli::__private::is_excluded() {
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

bach::cli::__private::get_exclude_list_array() {
    local exclude_list_comma_separated_string_default
    exclude_list_comma_separated_string_default="${__BACH_CLI_CONFIG[exclude_list]}"

    local exclude_list_comma_separated_string="${1:-$exclude_list_comma_separated_string_default}"
    IFS=',' read -ra exclude_array <<< "$exclude_list_comma_separated_string"
    echo "${exclude_array[@]}"
}


bach::cli::__private::get_valid_subcommand_script_path() {
    local path="$1"

    local allowed_extensions_comma_separated_string_default
    allowed_extensions_comma_separated_string_default="${__BACH_CLI_CONFIG[commands_scripts_extensions]}"

    local allowed_extensions_comma_separated_string
    allowed_extensions_comma_separated_string="${2:-$allowed_extensions_comma_separated_string_default}"
    IFS=',' read -ra allowed_extensions_array <<< "$allowed_extensions_comma_separated_string"

    local path_with_extension
    for ext in "${allowed_extensions_array[@]}"; do
        path_with_extension="${path}${ext}"
        if [[ -f "$path_with_extension" && -x "$path_with_extension" ]]; then
            echo "$path_with_extension"
            return 0
        fi
    done

    echo ""
    return 1
}


# Check if directory has an executable main script (private)
#
# Dependencies:
#   - __BACH_CLI_CONFIG[command_directory_main_file_root_name]
#   - bach::remove_trailing_slashes (from bach.sh)
#
# Arguments:
#   $1: Directory path
# Returns:
#   0 if has executable main, 1 otherwise
bach::cli::__private::get_directory_main_script_path() {
    local dir
    dir="$1"
    dir=$(bach::remove_trailing_slashes "$dir")

    local main_filenames_without_ext=${__BACH_CLI_CONFIG[command_directory_main_file_root_name]}

    local path_with_extension
    path_with_extension=$(bach::cli::__private::get_valid_subcommand_script_path "${dir}/${main_filenames_without_ext}")
    if [[ -n "$path_with_extension" ]]; then
        echo "$path_with_extension"
        return 0
    fi

    echo ""
    return 1
}

# Get list of available subcommands in a directory
# Arguments:
#   $1: Base directory to search
#   $2: Comma-separated list of excluded files/patterns
# Returns:
#   Prints newline-separated list of subcommand names
bach::cli::__private::get_available_subcommands() {
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
        bach::cli::__private::is_excluded "$item" "${exclude_array[@]}" && continue

        local item_name=$(basename "$item")

        # Check if it's a directory
        if [[ -d "$item" ]]; then
            # Include directory if it has main.sh or if it contains any subcommands
            if bach::cli::__private::get_directory_main_script_path "$item"; then
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

# Get expanded list of subcommands (PUBLIC API)
# Arguments:
#   $1: Script directory
#   $2: Comma-separated exclude list
# Returns:
#   Prints newline-separated list of expanded subcommands (includes nested like "stwo foo")
bach::cli::get_subcommands() {
    local script_dir="$1"
    local exclude_list="$2"

    [[ ! -d "$script_dir" ]] && return

    # Get base subcommands
    local -a subcommands=()
    while IFS= read -r cmd; do
        [[ -n "$cmd" ]] && subcommands+=("$cmd")
    done < <(bach::cli::__private::get_available_subcommands "$script_dir" "$exclude_list")

    # Expand nested subcommands
    local -a expanded_subcommands=()
    for subcmd in "${subcommands[@]}"; do
        local subcmd_path="$script_dir/$subcmd"

        # Check if it's a directory
        if [[ ! -d "$subcmd_path" ]]; then
            expanded_subcommands+=("$subcmd")
            continue
        fi

        # Check if directory has main.sh
        if bach::cli::__private::get_directory_main_script_path "$subcmd_path"; then
            expanded_subcommands+=("$subcmd")
            continue
        fi

        # Directory without main.sh - expand its subcommands
        local -a nested_subcommands=()
        while IFS= read -r nested_cmd; do
            [[ -n "$nested_cmd" ]] && nested_subcommands+=("$nested_cmd")
        done < <(bach::cli::__private::get_available_subcommands "$subcmd_path" "$exclude_list")

        for nested in "${nested_subcommands[@]}"; do
            expanded_subcommands+=("$subcmd $nested")
        done
    done

    # Output expanded subcommands, one per line
    for cmd in "${expanded_subcommands[@]}"; do
        echo "$cmd"
    done
}

# Export only public function
export -f bach::cli::get_subcommands


bach::cli::__private::execute_subcommand_script(){
    local script_path="$1"
    local args_array_index="$2"
    local -n path_args_array="${__BACH_CONFIG[commands_path_args_array_global_var_name]}"

    bach log --verbose "[execute_subcommand]Update path arguments array, remove ${args_array_index} leading segments, remaining args: ${path_args_array[*]:$args_array_index}"
    path_args_array=("${path_args_array[@]:$args_array_index}")

    bach log --verbose "[execute_subcommand]Executing subcommand script at path: ${script_path}"
    # TODO: replace exec with ./
    exec "${script_path}"

    return $?
}


bach::cli::execute_subcommand(){
    local caller_script_path
    caller_script_path="${BASH_SOURCE[1]}"

    local -n path_args_array="${__BACH_CONFIG[commands_path_args_array_global_var_name]}"

    if [[ -z "${path_args_array[*]}" ]] || [[ "${#path_args_array[@]}" -eq 0 ]]; then
        bach log --verbose "In ${caller_script_path}: No arguments provided to execute_subcommand. Nothing to execute."
        return 0
    fi

    local caller_script_dir
    caller_script_dir="$(dirname -- "$(readlink -f -- "$caller_script_path")")"

    local next_command_path
    next_command_path="${caller_script_dir}/"

    local next_command_directory_main_script_path
    local next_command_script_path
    for ((i=0; i<${#path_args_array[@]}; i++)); do
        next_command_path+="${path_args_array[i]}"
        bach log --verbose "[execute_subcommand]Inspect path: ${next_command_path}, remaining args: ${path_args_array[*]}"

        if [[ -d "$next_command_path" ]]; then
            bach log --verbose "[execute_subcommand]Inspect path: ${next_command_path}, search for main script in directory"
            next_command_directory_main_script_path=$(bach::cli::__private::get_directory_main_script_path "$next_command_path")
            if [[ -n "$next_command_directory_main_script_path" ]]; then
                bach log --debug "[execute_subcommand]Inspect path: ${next_command_path}, execute the found main script: ${next_command_directory_main_script_path}"
                bach::cli::__private::execute_subcommand_script "$next_command_directory_main_script_path" "$((i+1))"
                return $?
            fi
        fi

        next_command_script_path=$(bach::cli::__private::get_valid_subcommand_script_path "$next_command_path")
        if [[ -n "$next_command_script_path" ]]; then
            bach log --verbose "[execute_subcommand]Inspect path: ${next_command_path}, execute script ${next_command_script_path}"
            bach::cli::__private::execute_subcommand_script "$next_command_script_path" "$((i+1))"
            return $?
        else
            bach log --verbose "[execute_subcommand] ${next_command_path} is neither a directory with main script nor an executable file, continue searching with next path segment"
        fi
        next_command_path+="/"
    done

    bach log --error "[execute_subcommand]Command '$next_command_name' not found as executable file or directory in ${caller_script_dir}"
    return 1
}

# # Execute a subcommand based on path arguments
# # Arguments:
# #   $1: Script directory
# #   $2: Comma-separated exclude list
# #   $@: Path arguments
# # Returns:
# #   0 if script was found and executed successfully, or if no path arguments
# #   1 if no script was found or execution failed
# bach::cli::execute_subcommand() {
#     local script_dir="$1"
#     local exclude_list="$2"
#     shift 2
#     local -a path_args=("$@")

#     # If no path arguments, nothing to execute
#     [[ ${#path_args[@]} -eq 0 ]] && return 0

#     # Setup exclusion list
#     local -a exclude_array=()
#     if [[ -n "$exclude_list" ]]; then
#         IFS=',' read -ra exclude_array <<< "$exclude_list"
#     fi

#     local current_dir="$script_dir"
#     local -a remaining_args=()
#     local script_found=false

#     for ((i=0; i<${#path_args[@]}; i++)); do
#         local arg="${path_args[$i]}"
#         local found=false

#         # Try to find .sh file
#         if [[ -f "$current_dir/${arg}.sh" && -x "$current_dir/${arg}.sh" ]]; then
#             # Check if excluded
#             local excluded=false
#             for pattern in "${exclude_array[@]}"; do
#                 if [[ "${arg}.sh" == $pattern ]] || [[ "$current_dir/${arg}.sh" == *"$pattern"* ]]; then
#                     excluded=true
#                     break
#                 fi
#             done

#             if [[ "$excluded" == false ]]; then
#                 # Collect remaining arguments
#                 remaining_args=("${path_args[@]:$((i+1))}")
#                 exec "$current_dir/${arg}.sh" "${remaining_args[@]}"
#                 return $?
#             fi
#         fi

#         # Try to find file without extension
#         if [[ -f "$current_dir/${arg}" && -x "$current_dir/${arg}" ]]; then
#             local excluded=false
#             for pattern in "${exclude_array[@]}"; do
#                 if [[ "$arg" == $pattern ]] || [[ "$current_dir/${arg}" == *"$pattern"* ]]; then
#                     excluded=true
#                     break
#                 fi
#             done

#             if [[ "$excluded" == false ]]; then
#                 remaining_args=("${path_args[@]:$((i+1))}")
#                 exec "$current_dir/${arg}" "${remaining_args[@]}"
#                 return $?
#             fi
#         fi

#         # Try to find directory
#         if [[ -d "$current_dir/${arg}" ]]; then
#             # Check for main.sh in directory
#             if [[ -f "$current_dir/${arg}/main.sh" && -x "$current_dir/${arg}/main.sh" ]]; then
#                 remaining_args=("${path_args[@]:$((i+1))}")
#                 exec "$current_dir/${arg}/main.sh" "${remaining_args[@]}"
#                 return $?
#             elif [[ -f "$current_dir/${arg}/main" && -x "$current_dir/${arg}/main" ]]; then
#                 remaining_args=("${path_args[@]:$((i+1))}")
#                 exec "$current_dir/${arg}/main" "${remaining_args[@]}"
#                 return $?
#             else
#                 # Directory without main - continue routing
#                 current_dir="$current_dir/${arg}"
#                 found=true
#             fi
#         fi

#         if [[ "$found" == false ]]; then
#             break
#         fi
#     done

#     # If we get here, no script was found or executed
#     echo "Error: Could not find or execute command: ${path_args[*]}" >&2
#     return 1
# }

# Export function
export -f bach::cli::execute_subcommand


bach::cli::setup::from_docstring() {
    local caller_script_relative_path
    caller_script_relative_path="${BASH_SOURCE[2]}"
    local caller_script_path
    caller_script_path="$(readlink -f -- "$caller_script_relative_path")"

    local caller_script_filename
    caller_script_filename="$(basename -- "$caller_script_path")"

    local caller_script_dirpath
    caller_script_dirpath="$(dirname -- "$caller_script_path")"
    local caller_script_dirname
    caller_script_dirname="$(basename -- "$caller_script_dirpath")"

    bach log --verbose "[bach::cli::setup::from_docstring]I was executed from script: ${caller_script_path} located in directory: ${caller_script_dirpath}"

    local doc_string="$1"
    shift 1

    bach log --verbose "[bach::cli::setup::from_docstring]Get available subcommands reading directory ${caller_script_dirpath}"
    local available_subcommands
    available_subcommands=$(bach cli::get_subcommands "${caller_script_dirpath}")
    bach log --verbose "[bach::cli::setup::from_docstring]Available subcommands found: ${available_subcommands//$'\n'/, }"

    bach log --verbose "[bach::cli::setup::from_docstring]Get command name from script ${caller_script_path}"
    local cmd_name
    local caller_script_filename_without_ext="${caller_script_filename%.*}"
    if [[ "$caller_script_filename_without_ext" == "${__BACH_CLI_CONFIG[command_directory_main_file_root_name]}" ]]; then
        cmd_name="$caller_script_dirname"
    else
        cmd_name="$caller_script_filename_without_ext"
    fi
    bach log --verbose "[bach::cli::setup::from_docstring]${caller_script_path}Determined command name: ${cmd_name}"

    bach log --verbose "[bach::cli::setup::from_docstring]${caller_script_path}Resolve docstring for command: ${cmd_name}"
    local resolved_docstring
    resolved_docstring=$(bach docstring_helper::resolve_docstring "${doc_string}" "${cmd_name}" "${available_subcommands}")
    bach log --verbose "[bach::cli::setup::from_docstring]Resolved docstring for CLI setup ${resolved_docstring}"

    # TODO: How to ensure this function is declared?
    bach parse_args::from_docstring "${resolved_docstring}" "$@"
    bach log --verbose "[bach::cli::setup::from_docstring]Resolved docstring for CLI setup ${resolved_docstring}"
    case $? in
        0) ;;  # Continue execution
        2|3) return 0 ;;  # Help or version was handled
        *) return 1 ;;  # Parse error
    esac
}
export -f bach::cli::setup::from_docstring