#!/bin/bash

main() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local lib_dir="$(cd "${script_dir}/../../.." && pwd)/lib"

    # Source required libraries
    source "${lib_dir}/parse_args.sh"
    source "${lib_dir}/doc_helper.sh"

    local doc_string="
YAYA - Yaya Command

Execute yaya operations in the deeply nested context.

Usage:
    yaya [options] <action>

Options:
    -r|--recursive||Process recursively
    -p|--parallel|default=false|Run in parallel mode
    --threads=|default=\"4\"|Number of threads to use

----
3.0.0
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
    
    printf '%s\n' "=== YAYA Command Executed ===" >&2
    printf '%s\n' "Path: cp -> cmd -> stwo -> ssx -> yaya" >&2
    printf '%s\n' "Options:" >&2
    printf '%s\n' "  --recursive: ${args[recursive]}" >&2
    printf '%s\n' "  --parallel: ${args[parallel]}" >&2
    printf '%s\n' "  --threads: ${args[threads]}" >&2
    
    if [[ ${#__PATH_ARGS[@]} -gt 0 ]]; then
        printf '%s\n' "Action: ${__PATH_ARGS[*]}" >&2
    fi
    
    if [[ "${args[parallel]}" == "true" ]]; then
        printf '%s\n' "Running in parallel mode with ${args[threads]} threads" >&2
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
