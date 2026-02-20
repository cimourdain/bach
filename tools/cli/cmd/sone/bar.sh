#!/bin/bash

main() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local lib_dir="$(cd "${script_dir}/../.." && pwd)/lib"

    # Source required libraries
    source "${lib_dir}/parse_args.sh"
    source "${lib_dir}/doc_helper.sh"

    local doc_string="
BAR - Bar Command

Execute bar operations.

Usage:
    bar [options]

Options:
    -q|--quiet||Suppress output
    -d|--dry-run||Show what would be done without executing
    --config=|default=\"default.conf\"|Configuration file to use

----
1.5.0
"

    # Parse arguments (parse_args handles --help and --version internally)
    parse_args "$doc_string" "" "" "$@"
    
    case $? in
        0) ;;  # Continue execution
        2|3) return 0 ;;  # Help or version was handled
        *) return 1 ;;  # Parse error
    esac
    
    # Access parsed options
    declare -n args="${__ARGS_VAR_NAME}"
    
    if [[ "${args[quiet]}" != "true" ]]; then
        printf '%s\n' "=== BAR Command Executed ===" >&2
        printf '%s\n' "Config file: ${args[config]}" >&2
        
        if [[ "${args[dry-run]}" == "true" ]]; then
            printf '%s\n' "[DRY RUN] Would execute bar operations" >&2
        else
            printf '%s\n' "Executing bar operations..." >&2
        fi
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
