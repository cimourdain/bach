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

## Script Coding Guidelines

### Structure and organization

#### Headers and comments

**Characteristics:**

- Must start with a shebang line (e.g., `#!/bin/bash`) to specify the interpreter
- Must contains a comment block at the top of the file that includes:
  - A brief description of the script's purpose and functionality
  - Usage instructions with examples
  - A list of dependencies (external commands, environment variables, files)
  - Author and version information

#### Functions design and naming conventions

The following guidelines apply to all functions of bash scripts in the repository:

**Characteristics:**

- Should have a single responsibility and be reusable where possible
- Must not exceed ~30 lines of actual logic (excluding comments and whitespace)
- Must have a docstring comment immediately preceding the function definition that describes its purpose, parameters, required/expected and impacted global variables, and return values
- Naming:
  - Must be named using a project specific prefix `<PREFIX>::` and a descriptive name (e.g., `<PREFIX>::my_function`)
  - For private function names, use a double underscore prefix (e.g., `<PREFIX>::__private::my_helper_function`)
- Arguments:
  - Arguments must be stored in local variables at the beginning of the function with descriptive names
  - Should use `local` keyword to avoid polluting global namespace
  - Arguments must have default values where appropriate, and the function should handle missing or invalid arguments gracefully
- Must avoid at maximum the use of subshells and command substitution to improve performance and reduce complexity
- Must return status codes (0 for success, non-zero for failure) and output results via stdout or stderr, not by modifying global variables

#### Messaging

The following guidelines apply to all messaging and logging within the script:

**Characteristics:**

- Must use printf for user messages
- Use `tput` for colors: Terminal compatibility instead of ANSI codes
- Apart from identified exceptions, messages must be routed to stderr with >&2 to avoid mixing with stdout output

##### Debug messages

**Characteristics:**

- In order to ease debugging, commented messages should be left in the code with a clear indication that they are for debugging purposes and should not be removed

### Script execution and sourcing

#### Executables scripts guard clause

When script is executable, it must define at least one public function that serves as the entry point for the script, encapsulating the primary logic and flow of the script.

#### Direct execution guard clause

Executable scripts must include a guard clause to prevent execution when sourced, allowing them to be safely included in other scripts without side effects. This is typically done by checking if the script is being executed directly or sourced, eg:

```bash
<PREFIX>::main() {
    # Main function implementation
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    <PREFIX>::main "$@"
fi
```

#### Multiple sourcing prevention

All scripts must prevent multiple sourcing by using a check of the script exported function names and variables, eg:

```bash
# Prevent re-sourcing if functions and variables already declared
if declare -F prefix::my_public_func &>/dev/null && \
   [ -n "$MY_PUBLIC_VAR" ] ; then
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

## Testing

### Test File Naming and Location

Test files follow a consistent naming convention to associate them with the code they test:

- Test file format: `<script-or-library-name>.test.sh`
- Test file location: Same directory as the code being tested
- Example: Library `my-lib.sh` has tests `my-lib.test.sh`

### Test File Structure

All test files must follow this structure:

```bash
#!/usr/bin/env bash

# Test suite for <library/script name>
# Tests <description of what is tested>

set -o pipefail

# Source dependencies
<source the script/library being tested>

# Test counter and tracking
_test_tests_run=0
_test_tests_passed=0
_test_tests_failed=0

# Test helper function
_test_run_case() {
    local -r test_name="$1"
    # Test implementation
}

# Run tests
echo "Running tests for <library/script name>..."

# Test cases
_test_run_case "Test 1 description" ...
_test_run_case "Test 2 description" ...

# Print results
echo ""
echo "Test Results: $_test_tests_passed/$_test_tests_run passed"
```

### Test Function Naming

Test functions should follow naming conventions based on context:

#### Library Tests

- Prefix: `<library-name>_test::<function-name>`
- Example: For `user_messages.sh`, use `user_messages_test::test_emoji_output`

#### Script Tests

- Prefix: `<script-name>_test::<function-name>`
- Example: For `deploy.sh`, use `deploy_test::test_config_loading`

### Test Coverage Requirements

Each library or script must include tests covering:

1. **Happy Path**: Normal usage with valid inputs
2. **Edge Cases**: Boundary conditions and special values
3. **Error Handling**: Invalid inputs and error scenarios
4. **Integration**: Interaction with other components

### Test Assertions

For assertions and test utilities, use:

- `bach::assert` functions from the assert library when available
- Manual assertions with clear error messages
- Exit codes to indicate success (0) or failure (non-zero)

### Test Execution

Tests should be:

- **Executable**: Include proper shebang and permissions
- **Isolated**: Each test independent from others
- **Repeatable**: Same result on multiple runs
- **Deterministic**: No random or time-dependent failures
- **Fast**: Complete quickly for rapid feedback

### Tests scope

#### Unit Tests

- Test individual functions in isolation
- Use mocks/stubs for external dependencies
- Fast execution
- Located with the code being tested

### Test Results and Reporting

Test suites must:

- Count and report total tests run
- Count and report tests passed
- Count and report tests failed
- Exit with code 0 if all tests pass
- Exit with code 1 if any test fails
- Provide clear error messages on failure

### Continuous Testing

All test suites should:

- Be executable independently: `bash ./script.test.sh`
- Print clear output showing pass/fail status
- Use consistent emoji/symbols for status indication (✓ for pass, ✗ for fail)

## Documentation

Scripts must be accompanied by a documentation file in the same directory with the same name but with a `.md` suffix (e.g., `myscript.sh` would have a corresponding `myscript.md`). This documentation file should provide detailed information about the script, including its purpose, usage, parameters, examples, and any other relevant details.

# Checklist for any bash script creation or update

- [ ] Code structure and organization
  - [ ] Does the script start with a shebang line specifying the interpreter?
  - [ ] Does the script contain a comment block at the top with description, usage, dependencies, author, and version information?
  - [ ] Source conflicts and multiple sourcing prevention:
    - [ ] Does the script have a check to prevent multiple sourcing by checking exported function names and variables?
    - [ ] Apart from identified exceptions, does the script ensure it does not define global variables but instead uses local variables within functions?
    - [ ] Does public functions have a `declare -F` check to prevent re-declaration when sourced multiple times?
    - [ ] Does functions have a prefix :
      - [ ] global prefix to prevent naming conflicts?
      - [ ] For private functions, is the prefix followed by `__private::`
  - [ ] When a script only expose one public function, does it have a direct execution guard clause ?
  - [ ] Logging and messaging:
    - [ ] Does the script use printf for logging messages?
    - [ ] Are messages routed to stderr with >&2 to avoid mixing with stdout output?
    - [ ] Are commented log messages left in the code with clear indication that they are for debugging purposes?
- [ ] Tests
  - [ ] Does the script have an associated test file with the same name but with a `.test.sh` suffix with unit tests for its functions?
  - [ ] Are all the updates performed impacted in the test file as well to ensure coverage and prevent regressions?
  - [ ] Are the test functions in the test file prefixed with the test file name to avoid naming conflicts with the main script functions?
- [ ] Documentation
  - [ ] Does the script have a clear and comprehensive comment block at the top with description, usage, dependencies, author, and version information?
  - [ ] Is there a documentation file in the same directory with the same name but with a `.md` suffix (e.g., `myscript.sh` would have a corresponding `myscript.md`) that provides detailed documentation for the script, including examples and explanations of its functionality and usage?
  - [ ] Does the documentation reflect all the updates performed in the script to ensure it is up to date and accurate for users?
    - [ ] Does the documentation explain all features of the script?
    - [ ] Does the documentation contains examples of usage for all the features of the script, including edge cases and error handling scenarios?
