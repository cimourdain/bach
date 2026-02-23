---
name: bash-skill
description: Apply comprehensive bash scripting standards including main function pattern, usage documentation, argument parsing, dependency checking, and error handling. Triggers when creating/editing .sh files, bash scripts, or discussing shell scripting, deployment scripts, automation tasks, or bash conventions.
---

# Bash Best Practices Skill

This skill ensures all bash scripts follow enterprise-grade best practices for maintainability, reliability, and user-friendliness.

## When This Skill Applies

This skill should be automatically invoked when:
- Creating new bash scripts or shell scripts
- Editing existing .sh, .bash or files without extension but containing bash shebang (`#!/bin/bash` or similar) as first line
- User requests scripts for automation, deployment, backup, or system tasks
- Reviewing or refactoring bash code
- User mentions: bash, shell script, main function, argument parsing, script structure


## Script Complexity Guidelines

This skill recognizes two categories of scripts with different structural requirements:

### All scripts

The following best practices apply to all bash scripts regardless of complexity.

#### Structure and organization

**Characteristics:**
- Must start with a shebang line (e.g., `#!/bin/bash`) to specify the interpreter
- Must contains a comment block at the top of the file that includes:
  - A brief description of the script's purpose and functionality
  - Usage instructions with examples
  - A list of dependencies (external commands, environment variables, files)
  - Author and version information
- Must define a `main` function that serves as the entry point for the script, encapsulating the primary logic and flow of the script

#### Direct execution guard clause

All scripts must include a guard clause to prevent execution when sourced, allowing them to be safely included in other scripts without side effects. This is typically done by checking if the script is being executed directly or sourced:
```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

#### Multiple sourcing prevention

All scripts must prevent multiple sourcing by using a check of the script exported function names and variables, eg:
```bash
# Prevent re-sourcing if functions already declared
if declare -F prefix::my_public_func &>/dev/null && \
   [ -z "$MY_PUBLIC_VAR" ] ; then
    return 0
fi

prefix::__private::my_private_func() {
    # Function implementation
}

prefix::my_public_func() {
    # Function implementation
}
export -f prefix::my_public_func

MY_PUBLIC_VAR="value"
export MY_PUBLIC_VAR
```

#### Messaging and logging

The following guidelines apply to all messaging and logging within the script:

**Characteristics:**
- Must use printf to log messages:
  - Should include a timestamp, log level (INFO, WARNING, ERROR), and the message content
  - Should use color coding for different log levels (grey for DEBUG, blue for INFO, yellow for WARNING, red for ERROR) to enhance readability in the terminal using tput
- Apart from identified exceptions, messages must be routed to stderr with >&2 to avoid mixing with stdout output
- In order to ease debugging, commented log messages should be left in the code with a clear indication that they are for debugging purposes and should not be removed

#### Functions

The following guidelines apply to all functions within the script:

**Characteristics:**
- Should have a single responsibility and be reusable where possible
- Must not exceed ~30 lines of actual logic (excluding comments and whitespace)
- Must have a docstring comment immediately preceding the function definition that describes its purpose, parameters, required/expected and impacted global variables, and return values
- Naming:
  - Must be named using a project specific prefix followed by `::` and a descriptive name (e.g., `bachcli::my_function`)
  - For private function names, use a double underscore prefix (e.g., `bachcli::__private::my_helper_function`)
- Arguments:
  - Arguments must be stored in local variables at the beginning of the function with descriptive names
  - Should use `local` keyword to avoid polluting global namespace
  - Arguments must have default values where appropriate, and the function should handle missing or invalid arguments gracefully
- Must avoid at maximum the use of subshells and command substitution to improve performance and reduce complexity
- Must return status codes (0 for success, non-zero for failure) and output results via stdout or stderr, not by modifying global variables

#### Testing

For each bash file, an associated test file should be created in the same directory with the same name but with a `.test.sh` suffix (e.g., `myscript.sh` would have a corresponding `myscript.test.sh`). This test file should contain unit tests for the functions defined in the main script, following similar best practices for structure, logging, and function design.

Functions defined in tests files must be prefixed with the test file name to avoid naming conflicts with the main script functions. For example, if the main script is `myscript.sh`, the test functions in `myscript.test.sh` should be prefixed with `myscript_test::` (e.g., `myscript_test::test_my_function`).


