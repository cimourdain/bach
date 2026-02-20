#!/bin/bash

main() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local lib_dir="$(cd "${script_dir}/.." && pwd)/lib"

    # Source required libraries
    source "${lib_dir}/parse_args.sh"
    source "${lib_dir}/doc_helper.sh"

    local doc_string="
CMD1 - First Command

A simple example command that demonstrates option parsing.

Usage:
    cmd1 [options] [<file>...]

Options:
    -a|--all|default=false|Process all items
    -f|--force||Force execution without confirmation
    -v|--verbose||Enable verbose output
    --output-format=|default=\"text\"|Output format (text, json, xml)

----
1.0.0
"

    # Parse arguments (parse_args handles --help and --version internally)
    parse_args "$doc_string" "" "" "$@"
    
    case $? in
        0) ;;  # Continue execution
        2|3) return 0 ;;  # Help or version was handled
        *) return 1 ;;  # Parse error
    esac
    
    # Access parsed options from global array
    declare -n args="${__ARGS_VAR_NAME}"
    
    printf '%s\n' "=== CMD1 Executed ===" >&2
    printf '%s\n' "Options parsed:" >&2
    printf '%s\n' "  --all: ${args[all]}" >&2
    printf '%s\n' "  --force: ${args[force]}" >&2
    printf '%s\n' "  --verbose: ${args[verbose]}" >&2
    printf '%s\n' "  --output-format: ${args[output-format]}" >&2
    
    if [[ ${#__PATH_ARGS[@]} -gt 0 ]]; then
        printf '%s\n' "Path arguments: ${__PATH_ARGS[*]}" >&2
    fi
    
    # Conditional output based on flags
    if [[ "${args[verbose]}" == "true" ]]; then
        printf '%s\n' "[VERBOSE] Executing with verbose mode" >&2
    fi
    
    if [[ "${args[all]}" == "true" ]]; then
        printf '%s\n' "Processing all items..." >&2
    fi
    
    printf '%s\n' "Output format: ${args[output-format]}" >&2
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
