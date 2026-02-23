# assert.sh - Test Assertion Library

A comprehensive test assertion library providing color-coded test output and result tracking for bash test suites.

## Overview

The assert library provides functions for writing test assertions in bash scripts. It includes assertions for content verification, empty checks, and test result management with beautiful color-coded output.

## Features

- ✅ Content assertions (`assert_contains`, `assert_not_contains`)
- ✅ Empty value assertions (`assert_empty`)
- ✅ Color-coded test output (green for pass, red for fail)
- ✅ Automatic test counting and statistics
- ✅ Section headers for test organization
- ✅ Summary reports

## Installation

```bash
# Source the assertion library
source assert.sh
```

## API Reference

### assert_contains

Assert that output contains an expected string.

**Signature:**
```bash
assert_contains "$output" "$expected" "test_description"
```

**Parameters:**
- `$1` (output): The actual output to test
- `$2` (expected): String expected to be contained in output
- `$3` (test_name): Description of the test

**Returns:** 0 if assertion passes, 1 if it fails

### assert_not_contains

Assert that output does NOT contain a specific string.

**Signature:**
```bash
assert_not_contains "$output" "$unexpected" "test_description"
```

**Parameters:**
- `$1` (output): The actual output to test
- `$2` (unexpected): String that should NOT be in output
- `$3` (test_name): Description of the test

**Returns:** 0 if assertion passes, 1 if it fails

### assert_empty

Assert that output is empty.

**Signature:**
```bash
assert_empty "$output" "test_description"
```

**Parameters:**
- `$1` (output): The actual output to test
- `$2` (test_name): Description of the test

**Returns:** 0 if assertion passes, 1 if it fails

### section

Print a formatted section header for organizing tests.

**Signature:**
```bash
section "Section Name"
```

**Parameters:**
- `$1` (name): Name of the test section

### print_test_summary

Print a summary of test results including total, passed, and failed counts.

**Signature:**
```bash
print_test_summary
```

**Returns:** 0 if all tests passed, 1 if any failed

## Basic Examples

### Simple Test File

```bash
#!/bin/bash
source assert.sh

# Test a simple command
test_echo_command() {
    section "Testing echo command"

    local output=$(echo "Hello World")
    assert_contains "$output" "Hello" "Echo should contain Hello"
    assert_contains "$output" "World" "Echo should contain World"
}

test_echo_command
print_test_summary
```

### Testing Command Output

```bash
#!/bin/bash
source assert.sh

test_grep_functionality() {
    section "Testing grep command"

    # Test that grep finds matches
    local output=$(echo -e "line1\nline2\nline3" | grep "line2")
    assert_contains "$output" "line2" "Grep should find line2"
    assert_not_contains "$output" "line1" "Grep should not include line1"
}

test_grep_functionality
print_test_summary
```

### Testing Empty Output

```bash
#!/bin/bash
source assert.sh

test_silent_command() {
    section "Testing silent commands"

    # Test command that produces no output
    local output=$(true)
    assert_empty "$output" "True command should produce no output"

    # Test command with output
    local output2=$(echo "text")
    # This will fail
    assert_empty "$output2" "Echo should not be empty"
}

test_silent_command
print_test_summary
```

## Advanced Examples

### Multi-Section Test Suite

```bash
#!/bin/bash
source assert.sh

# Test string manipulation
test_string_operations() {
    section "String Operations"

    local str="Hello, World!"

    # Test substring extraction
    local result="${str:0:5}"
    assert_contains "$result" "Hello" "Substring should contain Hello"
    assert_not_contains "$result" "World" "Substring should not contain World"

    # Test case conversion
    local upper="${str^^}"
    assert_contains "$upper" "HELLO, WORLD" "Uppercase conversion"

    local lower="${str,,}"
    assert_contains "$lower" "hello, world" "Lowercase conversion"
}

# Test array operations
test_array_operations() {
    section "Array Operations"

    local -a arr=("apple" "banana" "cherry")

    # Test array length
    assert_contains "${#arr[@]}" "3" "Array should have 3 elements"

    # Test array joining
    local joined="${arr[*]}"
    assert_contains "$joined" "apple" "Joined array should contain apple"
    assert_contains "$joined" "banana" "Joined array should contain banana"
    assert_contains "$joined" "cherry" "Joined array should contain cherry"
}

# Test file operations
test_file_operations() {
    section "File Operations"

    # Create temporary file
    local tmpfile="/tmp/test_$$"
    echo "test content" > "$tmpfile"

    # Test file exists
    if [[ -f "$tmpfile" ]]; then
        local content=$(cat "$tmpfile")
        assert_contains "$content" "test content" "File should contain test content"
    fi

    # Cleanup
    rm -f "$tmpfile"

    # Test file doesn't exist after deletion
    local check=$(ls "$tmpfile" 2>&1 || echo "not found")
    assert_contains "$check" "not found" "File should not exist after deletion"
}

# Test command exit codes
test_exit_codes() {
    section "Exit Code Testing"

    # Test successful command
    if true; then
        assert_empty "" "True command should succeed (no error message)"
    fi

    # Test failed command with error capture
    local output=$(false 2>&1 || echo "failed")
    assert_contains "$output" "failed" "False command should fail"
}

# Run all tests
test_string_operations
test_array_operations
test_file_operations
test_exit_codes

# Print final summary
print_test_summary
exit $?
```

### Testing Functions with Complex Output

```bash
#!/bin/bash
source assert.sh

# Function to test
calculate_sum() {
    local a=$1
    local b=$2
    echo $((a + b))
}

# Function with multi-line output
generate_report() {
    echo "Report Summary"
    echo "=============="
    echo "Status: OK"
    echo "Items: 42"
    echo "Errors: 0"
}

test_calculator() {
    section "Calculator Tests"

    local result=$(calculate_sum 5 3)
    assert_contains "$result" "8" "5 + 3 should equal 8"

    result=$(calculate_sum 10 -5)
    assert_contains "$result" "5" "10 + (-5) should equal 5"

    result=$(calculate_sum 0 0)
    assert_contains "$result" "0" "0 + 0 should equal 0"
}

test_report_generation() {
    section "Report Generation Tests"

    local report=$(generate_report)

    # Test multiple aspects of the output
    assert_contains "$report" "Report Summary" "Report should have header"
    assert_contains "$report" "Status: OK" "Report should show status"
    assert_contains "$report" "Items: 42" "Report should contain item count"
    assert_contains "$report" "Errors: 0" "Report should show zero errors"
    assert_not_contains "$report" "WARNING" "Report should not contain warnings"
    assert_not_contains "$report" "FAILED" "Report should not contain failures"
}

test_calculator
test_report_generation
print_test_summary
```

### Integration with Test Runner

```bash
#!/bin/bash
# This file can be run standalone or via the test runner

# When run standalone, we need to initialize test counters
if [[ -z "$total_tests" ]]; then
    total_tests=0
    passed_tests=0
    failed_tests=0
fi

source assert.sh

test_feature_a() {
    section "Feature A Tests"

    # Your tests here
    assert_contains "$(echo 'test')" "test" "Basic test"
}

test_feature_b() {
    section "Feature B Tests"

    # Your tests here
    local output=$(date +%Y)
    assert_contains "$output" "20" "Year should start with 20"
}

# Main function to run all tests
main() {
    test_feature_a
    test_feature_b

    print_test_summary
    return $?
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
```

## Test Counter Management

The library uses three global variables to track test results:

- `total_tests`: Total number of assertions run
- `passed_tests`: Number of passing assertions
- `failed_tests`: Number of failing assertions

These are automatically incremented by assertion functions and can be initialized manually for standalone test files:

```bash
# Initialize counters for standalone execution
total_tests=0
passed_tests=0
failed_tests=0
```

## Color Codes

The library uses ANSI color codes for output:

- `GREEN`: ✓ Passed tests
- `RED`: ✗ Failed tests
- `YELLOW`: Section headers
- `BLUE`: Additional information
- `RESET`: Reset to default

Colors are automatically exported by the library or can be customized if needed.

## Best Practices

1. **Use descriptive test names**: Make it easy to identify which test failed
2. **Organize with sections**: Group related tests under section headers
3. **Test one thing at a time**: Each assertion should verify a single behavior
4. **Clean up resources**: Remove temporary files and data after tests
5. **Return proper exit codes**: Use `exit $?` after `print_test_summary`

## See Also

- [tests.md](tests.md) - Test runner for executing multiple test files
- [parse_args.md](parse_args.md) - For testing CLI argument parsing
- [log.md](log.md) - For testing logging functionality
