#!/bin/bash
#
# Example of a library that is spanning a subshell in a directory with
# multiple files.
# The `main` file of the lib is responsible for executing the functions
# declared inside the lib.
#
# To use this lib template:
#   - Bootstrap:
#       - copy the content of this folder
#   - copy the prevent_redudant_import script in the same directory as this file
#   - Search for <REPLACE_ME> comments to suit to your needs.
#   - Uncomment <DEBUG> lines for debugging purposes if needed.

# Prevent multiple imports of this library.
mapfile -t declared_functions < <(typeset -F)
declared_func_str=$(IFS=',';echo "${declared_functions[*]}";IFS=$' \t\n')
# TODO: execute script from relative path to current file instead of executing it from the current working directory to avoid issues when the lib is sourced from a different directory.
./prevent_redudant_import.sh "$(readlink -f -- "$BASH_SOURCE")" "${declared_func_str}" || return 1

#######################################
# Library template for a lib that is spanning a subshell. <REPLACE_ME>
#
#  - execute functions declared inside the lib
#  - execute scripts in the same directory as the lib.
#
# WARNING: The name of the function MUST match the following naming convention:
#     - If the script filename is "main":
#         >  The function name MUST be equal to its parent directory name
#     - Else:
#         >  The function name MUST be equal to the script filename
#
# Globals:
#   None
# Arguments:
#   1 (str, optional): Lib command to execute.
#         If not provided, the default function will be executed if defined,
#         otherwise an error will be raised.
#   @ (any, optional): Arguments to be passed to the function specified
#         in the first argument.
# Outputs: # Function output (= echo )
#   Depending on the function executed, the output can be different.
# Returns: # Return code
#   1 if no default function is set and the first argument match neither:
#         a __public:: prefixed function name
#         a filename in the same directory as this file
#
###################################################################
ex2()( # <REPLACE_ME>: name of the parent folder name
    local lib_name
    local current_func_name
    local default_function
    local current_dir

    current_func_name="$FUNCNAME"
    current_dir=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")
    lib_name="libEx2" # <REPLACE_ME>: name of your lib for logging prefix

    # Functions declared inside the lib are only accessible inside the lib,
    # and do not conflict with global functions declared outside the lib, due to the subshell scope of the lib.
    #
    # 💡 __private:: prefixed functions are not available for calling outside the lib, and are meant to be used only inside the lib.
    __private::is_subfunc()(
        test "$(type -t "$1")" = "function";
    )

    # 💡 __public:: prefixed functions are available for calling outside the lib.
    # These are the functions that the lib is exposing to the outside, and can be called by users of the lib.
    __public::default()(
        printf "[${lib_name}]Hello from default function"
    ) >&2

    # Set the previous function as the default function to be executed when calling the lib without specifying a function name
    default_function="__public::default"

    __public::main()(
        printf "[${lib_name}]Hello from main function"
    ) >&2

    # <REPLACE_ME>: Define here your public/private functions that you want to expose/use inside the lib.

    # Execute the function matching the first argument passed to the lib:
    #  1. If the first argument matches a __public:: function:
    #     execute that function with the rest of the arguments passed to the lib.
    #  2. If the first argument matches a filename in the same directory as the lib:
    #     execute the filename with all the arguments passed to the lib.
    #  3. If the default_function variable is set:
    #     execute the function stored in that variable with all the arguments passed to the lib.
    #  4. If none of the previous conditions are met, print the usage of the lib.
    if test "$(type -t "__public::${1}")" = "function"; then
        func_name="$1"
        shift
        # printf "[${lib_name}]: valid function name \"__public::${func_name}\"" >&2  # <DEBUG>
        "__public::${func_name}" "$@"
    elif [[ -f "${current_dir}/${1}.sh" ]];then
        subscript_name="${current_dir}/${1}.sh"
        shift
        # printf "[${lib_name}]: source subscript filename \"${subscript_name}\"" >&2  # <DEBUG>
        source "${subscript_name}"
        subscript_func_name="${current_func_name}::$(basename -- "${subscript_name}" ".sh")::main"
        # printf "[${lib_name}]: execute function  \"${subscript_func_name}\"" >&2  # <DEBUG>
        "${subscript_func_name}" "$@"
    elif [[ -n "${default_function}" ]];then
        # printf "[${lib_name}]: Execute default function\n" >&2  # <DEBUG>
        "${default_function}" "$@"
    else
        printf "[${lib_name}]: No valid function name, and no default function defined, raise an execution error.\n" >&2
        exit 1
    fi
)

########
# Example of how to use the lib:
#
# source "path/to/this/lib"
# # Execute content of the "other" file in the same directory as the lib:
# ex2_multi_files_lib other
# # Execute the main function of the lib:
# ex2_multi_files_lib main
# # Execute the default function of the lib by not specifying a function name:
# ex2_multi_files_lib
