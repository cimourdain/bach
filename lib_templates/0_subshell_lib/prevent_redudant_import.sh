#!/bin/bash
#
# Prevent multiple imports of a library.
#
# The following logic returns
#
# TIP: uncomment the vars & printf statements to debug.
#
# Globals:
#   None
# Arguments:
#   1 (str): Script file path of the caller script being sourced.
#   2 (str): Comma-separated list of declared function names of the caller
#       script being sourced.
# Outputs:
#   None
# Returns:
#    1 In either of the following cases meaning that the caller script is
#       already declared as a function:
#       a. The caller script filename is "main" &&
#           the caller script's parent directory name is already declared
#           as a function;
#       b. The caller script filename is already declared as a function
#    0 Otherwise.
#
#######################################
if [[ "$(basename -- "${1}" ".sh")" == "main" ]];then
    # __current_script_filename=$(basename -- "${1}")
    # __current_script_dirname=$(basename $(dirname -- "${1}"))
    # printf "[${1}]Current script is named main, check if folder name ${__current_script_dirname} is already declared as function name.\n" >&2
    if [[ ${2:-""} == *"$(basename $(dirname -- "${1}"))"* ]]; then
    # if test "$(type -t "$(basename $(dirname -- "${1}"))")" = "function";then
        # printf "[${1}]Current script directory: ${__current_script_dirname} is already declared as function name, do not import.\n" >&2
        exit 1
    fi
    # printf "[${1}]Current script directory name ${__current_script_dirname}, is not declared as function name.\n" >&2
elif [[ ${2:-""} == *"$(basename -- "${1}" ".sh")"* ]] ; then
    # __current_script_filename=$(basename -- "${1}")
    # __current_script_name_type="$(type -t "${__current_script_filename}")"
    # printf "[${1}]Current script filename ${__current_script_filename} is already declared as a function, DO NOT import lib.\n" >&2
    exit 1
# else
#     __current_script_filename=$(basename -- "${1}")
#     __current_script_dirname=$(basename $(dirname -- "${1}"))
#     printf "[${1}]Current script filename (${__current_script_filename} != main || ${__current_script_dirname} is not declared as function name) && ${__current_script_filename} is not a declared function.\n" >&2
#     printf "[${1}]Declared functions:\n$(typeset -F).\n" >&2
fi
exit 0