#!/bin/bash

################################################################################
# STWO FOO - Two Foo Command
################################################################################
# Description:
#   Execute foo operations in the stwo context with configurable operation
#   mode and immediate execution option.
#
# Usage:
#   foo [options] [arguments...]
#
# Examples:
#   # Execute immediately
#   foo --execute
#
#   # Use performance mode
#   foo --mode=performance
#
#   # Combine options
#   foo -e --mode=debug target1 target2
#
# Dependencies:
#   - bash 4.0+
#   - bachcli::import (../../lib/import.sh)
#   - bach::parse_args_from_docstring (../../lib/parse_args.sh)
#   - bachcli::doc_helper (../../lib/doc_helper.sh)
#
# Author: BACHCLI Project
# Version: 1.2.0
################################################################################

################################################################################
# Main function
# Executes stwo foo operations with parsed command-line options.
# Arguments:
#   $@ - Command-line arguments
# Globals:
#   __ARGS_VAR_NAME - Name of the associative array containing parsed arguments
#   __PATH_ARGS - Array of positional arguments
# Returns:
#   0 on success, 1 on parse error
################################################################################
main() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local lib_dir="$(cd "${script_dir}/../.." && pwd)/lib"

    # Calculate relative path for logging (from workspace root)
    local log_path="${script_dir##*/tools/cli/}"

    # Source import library and load dependencies
    source "${lib_dir}/import.sh"
    bachcli::import "parse_args,doc_helper,router,executor"

    # Subcommands directory - where the command scripts are located
    local subcommand_dir="${script_dir}"

    # Configurable exclusions - add files/patterns to exclude from execution
    local exclude_list="const.sh,statics.sh"

    local doc_string="
Command ${log_path}

Description of commands defined in ${script_dir}

Options:
    -e,--execute,Execute immediately
    --mode=,default="standard",Operation mode

----
1.2.0
"
    printf '[%s]%s\n' "${log_path}" "Enter command execution" >&2
    # Build documentation
    printf '[%s]%s\n' "${log_path}" "Build documentation" >&2
    local available_subcommands
    available_subcommands=$(bachcli::get_subcommands "" "${exclude_list}")

    printf '[%s]%s\n' "${log_path}" "Resolve docstring" >&2
    local resolved_docstring
    resolved_docstring=$(bach::resolve_docstring "${doc_string}" "${script_dir}" "${available_subcommands}")

    printf '[%s]%s\n' "${log_path}" "Parse arguments from docstring" >&2
    # Parse arguments (bach::parse_args_from_docstring handles --help and --version internally)
    bach::parse_args_from_docstring "${resolved_docstring}" "$@"

    case $? in
        0) ;;  # Continue execution
        2|3) return 0 ;;  # Help or version was handled
        *) return 1 ;;  # Parse error
    esac

    # Access parsed options
    declare -n args="${__ARGS_VAR_NAME}"

    printf '[%s]%s\n' "${log_path}" "Parsed options:" >&2
    printf -v fmtStr '[%s]=%%q\\n' "${!args[@]}";printf "$fmtStr" "${args[@]}"

    printf '[%s]%s\n' "${log_path}" "Actions BEFORE executing subcommands" >&2

    printf '[%s]%s\n' "${log_path}" "Executing subcommands:" >&2
    bachcli::execute_subcommand "${subcommand_dir}" "$exclude_list" "${__PATH_ARGS[@]}"

    printf '[%s]%s\n' "${log_path}" "Actions AFTER executing subcommands" >&2

    printf '[%s]%s\n' "${log_path}" "Finished executing command" >&2
}

# Direct execution guard clause
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
