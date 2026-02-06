#!/bin/bash
#
# Example function declared in a different file of the same lib.
# This file MUST declare a function named with the following naming convention:
#     - <LIB_FUNC_NAME>::<SCRIPT_FILENAME>::main

#######################################
# Example function declared in a different file of the same lib.
#
#
# Globals:
#   lib_name (str): Name of the lib, defined in the root function of the lib.
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   None
#
#######################################
function ex2::other::main {
    printf "[libEx2]Hello from function in other.sh\n" >&2
    printf "[libEx2]This function can use local scoped variables of the lib root function, eg: lib_name=${lib_name}\n" >&2
}