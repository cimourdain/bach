#!/bin/bash

main() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local lib_dir="$(cd "${script_dir}/../../.." && pwd)/lib"

    # Source required libraries
    source "${lib_dir}/parse_args.sh"
    source "${lib_dir}/doc_helper.sh"

    # Exclusion list for this directory
    local exclude_list="const.sh,statics.sh"

    local doc_string="
SSX - Sub-Sub-X Command

Main handler for ssx nested subcommand group.

Usage:
    ssx [options]
    ssx <subcommand> [options]
----
1.0.0
"

    # Parse arguments (parse_args handles --help and --version internally)
    parse_args "$doc_string" "$script_dir" "$exclude_list" "$@"
    
    case $? in
        0) ;;  # Continue execution
        2|3) return 0 ;;  # Help or version was handled
        *) return 1 ;;  # Parse error
    esac
    
    printf '%s\n' "SSX main handler executed" >&2
    printf '%s\n' "This is a nested subcommand group" >&2
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
