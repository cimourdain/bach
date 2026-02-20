#!/bin/bash

main() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local lib_dir="$(cd "${script_dir}/../.." && pwd)/lib"

    # Source required libraries
    source "${lib_dir}/parse_args.sh"
    source "${lib_dir}/doc_helper.sh"

    # Exclusion list for this directory
    local exclude_list="const.sh,statics.sh"

    # Subcommands directory - where the command scripts are located
    local subcommand_dir="${script_dir}"

    local doc_string="
SONE - Subcommand One

Main handler for the sone subcommand group.

Usage:
    sone [options]
    sone <subcommand> [options]

Options:
    -o|--sone-main-flag|default=false|Enable main flag for sone
    --sone-val=|default=\"sone_is_great\"|Sone value for processing
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

    declare -n args="${__ARGS_VAR_NAME}"

    printf '%s\n' "=== SONE Command Executed ===" >&2
    printf '%s\n' "Options:" >&2
    printf -v fmtStr '[%s]=%%q\\n' "${!args[@]}";printf "$fmtStr" "${args[@]}"

    printf '%s\n' "Path Arguments: ${__PATH_ARGS[@]}" >&2
    # Route to appropriate subcommand
    # route_to_subcommand "${subcommand_dir}" "$exclude_list" "${__PATH_ARGS[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
