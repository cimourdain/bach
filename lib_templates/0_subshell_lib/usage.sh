#!/bin/bash
#
# Usage of the example libraries in this directory.

current_filepath=$(readlink -f -- "$BASH_SOURCE")
current_dirpath=$(dirname -- "${current_filepath}")
current_filename=$(basename -- "${current_filepath}")

#######################################
#
# Example 1 Usage
#
#######################################
printf "[${current_filename}]############### 1. Usage of example1 lib:\n" >&2
printf "[${current_filename}]1.1 Import the library:\n" >&2
ex1_path="${current_dirpath}/ex1.sh"
source "${ex1_path}"
if [ $? -ne 0 ]; then
    printf "[ERROR][${current_filename}]Library import received a return code indicating failure [received status code $?].\n" >&2
    exit 1
else
    printf "[SUCCESS][${current_filename}]Library import was successful.\n" >&2
fi

printf "[${current_filename}]1.2 Call lib with argument matching an existing function name:\n" >&2
ex1 main

printf "[${current_filename}]1.3 Call lib without argument to execute the default function:\n" >&2
ex1

printf "[${current_filename}]1.4 Source again the example1 lib to demonstrate prevention of redundant imports:\n" >&2
source "${ex1_path}"
if [ $? -ne 0 ]; then
    printf "[${current_filename}][SUCCESS]Redundant import of lib was prevented successfully, the import prevention logic is working as expected.\n" >&2
else
    printf "[ERROR][${current_filename}]Library was imported again when it should not have been [received status code $?], there is an issue with the import prevention logic.\n" >&2
fi

#############################################################################
#
# Example 2 Usage
#
############################################################################
printf "[${current_filename}]############### 2. Usage of example2 lib:\n" >&2
ex2_path="${current_dirpath}/ex2/main.sh"
printf "[${current_filename}]2.1 Import the library from ${ex2_path}:\n" >&2
source "${ex2_path}"
if [ $? -ne 0 ]; then
    printf "[ERROR][${current_filename}]Library import received a return code indicating failure [received status code $?].\n" >&2
    exit 1
else
    printf "[SUCCESS][${current_filename}]Library import was successful.\n" >&2
fi

printf "[${current_filename}]2.2 Call lib with argument matching an existing function name:\n" >&2
ex2 main

printf "[${current_filename}]2.3 Call lib without argument to execute the default function:\n" >&2
ex2

printf "[${current_filename}]2.4 Call lib with argument pointing to external file:\n" >&2
ex2 other

printf "[${current_filename}]2.5 Source again the lib to demonstrate prevention of redundant imports:\n" >&2
source "${ex2_path}"
if [ $? -ne 0 ]; then
    printf "[${current_filename}][SUCCESS]Redundant import of lib was prevented successfully, the import prevention logic is working as expected.\n" >&2
else
    printf "[ERROR][${current_filename}]Library was imported again when it should not have been [received status code $?], there is an issue with the import prevention logic.\n" >&2
fi