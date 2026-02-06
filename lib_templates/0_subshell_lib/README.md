# Bash library using a subshell

The current folder contains examples and templates of bash libraries declared as a function in a subshell.

## Usage usecases

As this design re-create a subshell that re-redeclare all internal variables and functions for each execution. It should be reserved to small libraries:

-  do not impact performance when re-declaring & executing the lib in a subshell
-  do not requires to impact the main execution context


## Execution naming conflicts insights

- 🟠 Library main name:
  - The library function name is hardcoded in its declaration
  - In case of conflict, changing the following can be used to give the library another name:
      - Folder/file name
      - Lib function name
- 🟢 Library variables and functions kept in a subshell.
  - Apart from the library name (exposed function name) they will not interfere with the main script execution


## Examples in this directory

> [!TIP]
> View all examples usage in action executing the `usage.sh` script.

### `ex1.sh` Unique file library

This example document how to create a subshell library using one unique file.

### `ex2/` Multi file library

This example document how to create a subshell library using multiple files to define its internal functions.