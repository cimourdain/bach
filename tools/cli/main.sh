#!/bin/bash

main() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Source required libraries
    source "${script_dir}/lib/parse_args.sh"
    source "${script_dir}/lib/doc_helper.sh"
    source "${script_dir}/lib/router.sh"

    # Subcommands directory - where the command scripts are located
    local subcommand_dir="${script_dir}/cmd"

    # Configurable exclusions - add files/patterns to exclude from execution
    local exclude_list="const.sh,statics.sh"

    local doc_string="
CP - Command Processor

A flexible command routing system that executes scripts based on directory structure.

Usage:
    cp [options]
    cp [options] <command> [--] [<args>...]
----
1.0.0
"

    # Parse arguments (parse_args handles --help and --version internally)
    # local subcommand_dir=$(get_subcommand_dir "${subcommand_dir}")
    parse_args "$doc_string" "$subcommand_dir" "$exclude_list" "$@"

    case $? in
        0) ;;  # Continue execution
        2|3) return 0 ;;  # Help or version was handled
        *) return 1 ;;  # Parse error
    esac

    # Route to appropriate subcommand
    route_to_subcommand "${subcommand_dir}" "$exclude_list" "${__PATH_ARGS[@]}"
}

# Only execute main if this script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
