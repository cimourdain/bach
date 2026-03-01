#!/bin/bash

# Source the main bash library to ensure all core functions are available
source "$(dirname "${BASH_SOURCE[0]}")/../../bach.sh"
__BACH_CONFIG["libs_local_path_default"]="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/lib/bach"

main() {
    bach log --info "Enter main command"

    local exclude_list="const.sh,statics.sh,lib"

    local doc_string="
Cli entrypoint

Description of commands

----
1.0.0
"
    bach log --info "Setup CLI from docstring"
    bach cli::setup::from_docstring "${doc_string}" "${exclude_list}" "$@"

    # Access parsed options
    declare -n args="${__ARGS_VAR_NAME}"

    bach log --debug "Parsed options:"
    printf -v fmtStr '[%s]=%%q\\n' "${!args[@]}";printf "$fmtStr" "${args[@]}"

    bach log --debug "Actions BEFORE executing subcommands"

    bach log --debug  "Executing subcommands"
    bach cli::execute_subcommand

    bach log --debug   "Actions AFTER executing subcommands"

    bach log --debug   "Finished executing command"


}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi