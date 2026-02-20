#!/bin/bash

main() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local lib_dir="$(cd "${script_dir}/../.." && pwd)/lib"

    # Source required libraries
    source "${lib_dir}/parse_args.sh"
    source "${lib_dir}/doc_helper.sh"

    local doc_string="
FOO - Foo Command

Performs foo operations with various options.

Usage:
    foo [options] <target>

Options:
    -a|--all||Apply to all targets
    -b|--bizz||Enable bizz mode
    -f|--my-flag||Set my flag
    --my-value=||Set custom value for processing
----
2.1.0
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

    printf '%s\n' "=== FOO Command Executed ===" >&2
    printf '%s\n' "Options:" >&2
    printf '%s\n' "Options:" >&2
    printf -v fmtStr '[%s]=%%q\\n' "${!args[@]}";printf "$fmtStr" "${args[@]}"

    # Perform foo operation before routing to subcommands
    if [[ "${args[all]}" == "true" ]]; then
        printf "Subcommands of FOO will be executed with ALL mode enabled!\n" >&2
    else
        printf "Subcommands of FOO will be executed with ALL mode disabled.\n" >&2
    fi

    route_to_subcommand "${subcommand_dir}" "$exclude_list" "${__PATH_ARGS[@]}"

    # Perform foo operation after routing to subcommands
    if [[ "${args[bizz]}" == "true" ]]; then
        printf "Subcommands of FOO were executed with BIZZ mode enabled!\n" >&2
    else
        printf "Subcommands of FOO were executed with BIZZ mode disabled.\n" >&2
    fi

    printf '%s\n' "=== End of foo command ===" >&2
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
