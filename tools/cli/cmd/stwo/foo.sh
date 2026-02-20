#!/bin/bash

main() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local lib_dir="$(cd "${script_dir}/../.." && pwd)/lib"

    # Source required libraries
    source "${lib_dir}/parse_args.sh"
    source "${lib_dir}/doc_helper.sh"

    local doc_string="
STWO FOO - Two Foo Command

Execute foo operations in the stwo context.

Usage:
    stwo foo [options]

Options:
    -e|--execute||Execute immediately
    --mode=|default=\"standard\"|Operation mode

----
1.2.0
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
    
    printf '%s\n' "=== STWO FOO Command Executed ===" >&2
    printf '%s\n' "Mode: ${args[mode]}" >&2
    printf '%s\n' "Execute: ${args[execute]}" >&2
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
