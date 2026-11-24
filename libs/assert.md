# assert.sh - Test Assertion Library

A comprehensive test assertion library providing color-coded test output and result tracking for bash test suites.

## Overview

The assert library provides functions for writing test assertions in bash scripts. It includes assertions for content verification, empty checks, and test result management with beautiful color-coded output.

## Features

- ✅ Content assertions (`bach::assert::contains`, `bach::assert::not_contains`)
- ✅ Empty value assertions (`bach::assert::empty`)
- ✅ Color-coded test output (green for pass, red for fail)
- ✅ Automatic test counting and statistics
- ✅ Section headers for test organization
- ✅ Summary reports

## Usage Examples

### Simple Test File

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
# Test a simple command
test_echo_command() {
    bach assert::section "Testing echo command"

    local output=$(echo "Hello World")
    bach assert::contains "$output" "Hello" "Echo should contain Hello"
    bach assert::contains "$output" "World" "Echo should contain World"
}

test_echo_command
bach assert::print_test_summary
```

```bash [Standalone]
#!/bin/bash
source my-libs/assert.sh
# Test a simple command
test_echo_command() {
    bach::assert::section "Testing echo command"

    local output=$(echo "Hello World")
    bach::assert::contains "$output" "Hello" "Echo should contain Hello"
    bach::assert::contains "$output" "World" "Echo should contain World"
}

test_echo_command
bach::assert::print_test_summary
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="c-blue">━━━ Testing echo command ━━━</span>
<span class="c-green">✓</span> Echo should contain Hello
<span class="c-green">✓</span> Echo should contain World

<span class="c-yellow">━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>
<span class="c-blue">Test Summary</span>
<span class="c-yellow">━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>
Total tests:  2
<span class="c-green">Passed:</span>       2
<span class="c-red">Failed:</span>       0

<span class="c-green">All tests passed! ✓</span></pre>

:::

### Testing Command Output

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
test_grep_functionality() {
    bach assert::section "Testing grep command"

    # Test that grep finds matches
    local output=$(echo -e "line1\nline2\nline3" | grep "line2")
    bach assert::contains "$output" "line2" "Grep should find line2"
    bach assert::not_contains "$output" "line1" "Grep should not include line1"
}

test_grep_functionality
bach assert::print_test_summary
```

```bash [Standalone]
#!/bin/bash
source my-libs/assert.sh
test_grep_functionality() {
    bach::assert::section "Testing grep command"

    # Test that grep finds matches
    local output=$(echo -e "line1\nline2\nline3" | grep "line2")
    bach::assert::contains "$output" "line2" "Grep should find line2"
    bach::assert::not_contains "$output" "line1" "Grep should not include line1"
}

test_grep_functionality
bach::assert::print_test_summary
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="c-blue">━━━ Testing grep command ━━━</span>
<span class="c-green">✓</span> Grep should find line2
<span class="c-green">✓</span> Grep should not include line1

<span class="c-yellow">━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>
<span class="c-blue">Test Summary</span>
<span class="c-yellow">━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>
Total tests:  2
<span class="c-green">Passed:</span>       2
<span class="c-red">Failed:</span>       0

<span class="c-green">All tests passed! ✓</span></pre>

:::

### Testing Empty Output

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
test_silent_command() {
    bach assert::section "Testing silent commands"

    # Test command that produces no output
    local output=$(true)
    bach assert::empty "$output" "True command should produce no output"

    # Test command with output
    local output2=$(echo "text")
    # This will fail
    bach assert::empty "$output2" "Echo should not be empty"
}

test_silent_command
bach assert::print_test_summary
```

```bash [Standalone]
#!/bin/bash
source my-libs/assert.sh
test_silent_command() {
    bach::assert::section "Testing silent commands"

    # Test command that produces no output
    local output=$(true)
    bach::assert::empty "$output" "True command should produce no output"

    # Test command with output
    local output2=$(echo "text")
    # This will fail
    bach::assert::empty "$output2" "Echo should not be empty"
}

test_silent_command
bach::assert::print_test_summary
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="c-blue">━━━ Testing silent commands ━━━</span>
<span class="c-green">✓</span> True command should produce no output
<span class="c-red">✗</span> Echo should not be empty
  <span class="c-red">Expected empty output</span>
  <span class="c-red">Got:</span> text

<span class="c-yellow">━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>
<span class="c-blue">Test Summary</span>
<span class="c-yellow">━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>
Total tests:  2
<span class="c-green">Passed:</span>       1
<span class="c-red">Failed:</span>       1

<span class="c-red">Some tests failed! ✗</span></pre>

:::

### Multi-Section Test Suite

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
# Test string manipulation
test_string_operations() {
    bach assert::section "String Operations"

    local str="Hello, World!"

    # Test substring extraction
    local result="${str:0:5}"
    bach assert::contains "$result" "Hello" "Substring should contain Hello"
    bach assert::not_contains "$result" "World" "Substring should not contain World"

    # Test case conversion
    local upper="${str^^}"
    bach assert::contains "$upper" "HELLO, WORLD" "Uppercase conversion"

    local lower="${str,,}"
    bach assert::contains "$lower" "hello, world" "Lowercase conversion"
}

# Test array operations
test_array_operations() {
    bach assert::section "Array Operations"

    local -a arr=("apple" "banana" "cherry")

    # Test array length
    bach assert::contains "${#arr[@]}" "3" "Array should have 3 elements"

    # Test array joining
    local joined="${arr[*]}"
    bach assert::contains "$joined" "apple" "Joined array should contain apple"
    bach assert::contains "$joined" "banana" "Joined array should contain banana"
    bach assert::contains "$joined" "cherry" "Joined array should contain cherry"
}

# Test file operations
test_file_operations() {
    bach assert::section "File Operations"

    # Create temporary file
    local tmpfile="/tmp/test_$$"
    echo "test content" > "$tmpfile"

    # Test file exists
    if [[ -f "$tmpfile" ]]; then
        local content=$(cat "$tmpfile")
        bach assert::contains "$content" "test content" "File should contain test content"
    fi

    # Cleanup
    rm -f "$tmpfile"

    # Test file doesn't exist after deletion
    local check=$(ls "$tmpfile" 2>&1 || echo "not found")
    bach assert::contains "$check" "not found" "File should not exist after deletion"
}

# Test command exit codes
test_exit_codes() {
    bach assert::section "Exit Code Testing"

    # Test successful command
    if true; then
        bach assert::empty "" "True command should succeed (no error message)"
    fi

    # Test failed command with error capture
    local output=$(false 2>&1 || echo "failed")
    bach assert::contains "$output" "failed" "False command should fail"
}

# Run all tests
test_string_operations
test_array_operations
test_file_operations
test_exit_codes

# Print final summary
bach assert::print_test_summary
exit $?
```

```bash [Standalone]
#!/bin/bash
source my-libs/assert.sh
# Test string manipulation
test_string_operations() {
    bach::assert::section "String Operations"

    local str="Hello, World!"

    # Test substring extraction
    local result="${str:0:5}"
    bach::assert::contains "$result" "Hello" "Substring should contain Hello"
    bach::assert::not_contains "$result" "World" "Substring should not contain World"

    # Test case conversion
    local upper="${str^^}"
    bach::assert::contains "$upper" "HELLO, WORLD" "Uppercase conversion"

    local lower="${str,,}"
    bach::assert::contains "$lower" "hello, world" "Lowercase conversion"
}

# Test array operations
test_array_operations() {
    bach::assert::section "Array Operations"

    local -a arr=("apple" "banana" "cherry")

    # Test array length
    bach::assert::contains "${#arr[@]}" "3" "Array should have 3 elements"

    # Test array joining
    local joined="${arr[*]}"
    bach::assert::contains "$joined" "apple" "Joined array should contain apple"
    bach::assert::contains "$joined" "banana" "Joined array should contain banana"
    bach::assert::contains "$joined" "cherry" "Joined array should contain cherry"
}

# Test file operations
test_file_operations() {
    bach::assert::section "File Operations"

    # Create temporary file
    local tmpfile="/tmp/test_$$"
    echo "test content" > "$tmpfile"

    # Test file exists
    if [[ -f "$tmpfile" ]]; then
        local content=$(cat "$tmpfile")
        bach::assert::contains "$content" "test content" "File should contain test content"
    fi

    # Cleanup
    rm -f "$tmpfile"

    # Test file doesn't exist after deletion
    local check=$(ls "$tmpfile" 2>&1 || echo "not found")
    bach::assert::contains "$check" "not found" "File should not exist after deletion"
}

# Test command exit codes
test_exit_codes() {
    bach::assert::section "Exit Code Testing"

    # Test successful command
    if true; then
        bach::assert::empty "" "True command should succeed (no error message)"
    fi

    # Test failed command with error capture
    local output=$(false 2>&1 || echo "failed")
    bach::assert::contains "$output" "failed" "False command should fail"
}

# Run all tests
test_string_operations
test_array_operations
test_file_operations
test_exit_codes

# Print final summary
bach::assert::print_test_summary
exit $?
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="c-blue">━━━ String Operations ━━━</span>
<span class="c-green">✓</span> Substring should contain Hello
<span class="c-green">✓</span> Substring should not contain World
<span class="c-green">✓</span> Uppercase conversion
<span class="c-green">✓</span> Lowercase conversion

<span class="c-blue">━━━ Array Operations ━━━</span>
<span class="c-green">✓</span> Array should have 3 elements
<span class="c-green">✓</span> Joined array should contain apple
<span class="c-green">✓</span> Joined array should contain banana
<span class="c-green">✓</span> Joined array should contain cherry

<span class="c-blue">━━━ File Operations ━━━</span>
<span class="c-green">✓</span> File should contain test content
<span class="c-green">✓</span> File should not exist after deletion

<span class="c-blue">━━━ Exit Code Testing ━━━</span>
<span class="c-green">✓</span> True command should succeed (no error message)
<span class="c-green">✓</span> False command should fail

<span class="c-yellow">━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>
<span class="c-blue">Test Summary</span>
<span class="c-yellow">━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>
Total tests:  12
<span class="c-green">Passed:</span>       12
<span class="c-red">Failed:</span>       0

<span class="c-green">All tests passed! ✓</span></pre>

:::

### Testing Functions with Complex Output

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
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
    bach assert::section "Calculator Tests"

    local result=$(calculate_sum 5 3)
    bach assert::contains "$result" "8" "5 + 3 should equal 8"

    result=$(calculate_sum 10 -5)
    bach assert::contains "$result" "5" "10 + (-5) should equal 5"

    result=$(calculate_sum 0 0)
    bach assert::contains "$result" "0" "0 + 0 should equal 0"
}

test_report_generation() {
    bach assert::section "Report Generation Tests"

    local report=$(generate_report)

    # Test multiple aspects of the output
    bach assert::contains "$report" "Report Summary" "Report should have header"
    bach assert::contains "$report" "Status: OK" "Report should show status"
    bach assert::contains "$report" "Items: 42" "Report should contain item count"
    bach assert::contains "$report" "Errors: 0" "Report should show zero errors"
    bach assert::not_contains "$report" "WARNING" "Report should not contain warnings"
    bach assert::not_contains "$report" "FAILED" "Report should not contain failures"
}

test_calculator
test_report_generation
bach assert::print_test_summary
```

```bash [Standalone]
#!/bin/bash
source my-libs/assert.sh
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
    bach::assert::section "Calculator Tests"

    local result=$(calculate_sum 5 3)
    bach::assert::contains "$result" "8" "5 + 3 should equal 8"

    result=$(calculate_sum 10 -5)
    bach::assert::contains "$result" "5" "10 + (-5) should equal 5"

    result=$(calculate_sum 0 0)
    bach::assert::contains "$result" "0" "0 + 0 should equal 0"
}

test_report_generation() {
    bach::assert::section "Report Generation Tests"

    local report=$(generate_report)

    # Test multiple aspects of the output
    bach::assert::contains "$report" "Report Summary" "Report should have header"
    bach::assert::contains "$report" "Status: OK" "Report should show status"
    bach::assert::contains "$report" "Items: 42" "Report should contain item count"
    bach::assert::contains "$report" "Errors: 0" "Report should show zero errors"
    bach::assert::not_contains "$report" "WARNING" "Report should not contain warnings"
    bach::assert::not_contains "$report" "FAILED" "Report should not contain failures"
}

test_calculator
test_report_generation
bach::assert::print_test_summary
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="c-blue">━━━ Calculator Tests ━━━</span>
<span class="c-green">✓</span> 5 + 3 should equal 8
<span class="c-green">✓</span> 10 + (-5) should equal 5
<span class="c-green">✓</span> 0 + 0 should equal 0

<span class="c-blue">━━━ Report Generation Tests ━━━</span>
<span class="c-green">✓</span> Report should have header
<span class="c-green">✓</span> Report should show status
<span class="c-green">✓</span> Report should contain item count
<span class="c-green">✓</span> Report should show zero errors
<span class="c-green">✓</span> Report should not contain warnings
<span class="c-green">✓</span> Report should not contain failures

<span class="c-yellow">━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>
<span class="c-blue">Test Summary</span>
<span class="c-yellow">━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>
Total tests:  9
<span class="c-green">Passed:</span>       9
<span class="c-red">Failed:</span>       0

<span class="c-green">All tests passed! ✓</span></pre>

:::

### Integration with Test Runner

::: code-group

```bash [With bach]
#!/bin/bash
# This file can be run standalone or via the test runner

# When run standalone, we need to initialize test counters
if [[ -z "$total_tests" ]]; then
    total_tests=0
    passed_tests=0
    failed_tests=0
fi

source lib/bach/bach.sh
test_feature_a() {
    bach assert::section "Feature A Tests"

    # Your tests here
    bach assert::contains "$(echo 'test')" "test" "Basic test"
}

test_feature_b() {
    bach assert::section "Feature B Tests"

    # Your tests here
    local output=$(date +%Y)
    bach assert::contains "$output" "20" "Year should start with 20"
}

# Main function to run all tests
main() {
    test_feature_a
    test_feature_b

    bach assert::print_test_summary
    return $?
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
```

```bash [Standalone]
#!/bin/bash
# This file can be run standalone or via the test runner

# When run standalone, we need to initialize test counters
if [[ -z "$total_tests" ]]; then
    total_tests=0
    passed_tests=0
    failed_tests=0
fi

source my-libs/assert.sh
test_feature_a() {
    bach::assert::section "Feature A Tests"

    # Your tests here
    bach::assert::contains "$(echo 'test')" "test" "Basic test"
}

test_feature_b() {
    bach::assert::section "Feature B Tests"

    # Your tests here
    local output=$(date +%Y)
    bach::assert::contains "$output" "20" "Year should start with 20"
}

# Main function to run all tests
main() {
    test_feature_a
    test_feature_b

    bach::assert::print_test_summary
    return $?
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="c-blue">━━━ Feature A Tests ━━━</span>
<span class="c-green">✓</span> Basic test

<span class="c-blue">━━━ Feature B Tests ━━━</span>
<span class="c-green">✓</span> Year should start with 20

<span class="c-yellow">━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>
<span class="c-blue">Test Summary</span>
<span class="c-yellow">━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>
Total tests:  2
<span class="c-green">Passed:</span>       2
<span class="c-red">Failed:</span>       0

<span class="c-green">All tests passed! ✓</span></pre>

:::

## API Reference

### bach::assert::contains

Assert that output contains an expected string.

**Signature:**
```bash
bach::assert::contains "$output" "$expected" "test_description"
```

**Parameters:**
- `$1` (output): The actual output to test
- `$2` (expected): String expected to be contained in output
- `$3` (test_name): Description of the test

**Returns:** 0 if assertion passes, 1 if it fails

### bach::assert::not_contains

Assert that output does NOT contain a specific string.

**Signature:**
```bash
bach::assert::not_contains "$output" "$unexpected" "test_description"
```

**Parameters:**
- `$1` (output): The actual output to test
- `$2` (unexpected): String that should NOT be in output
- `$3` (test_name): Description of the test

**Returns:** 0 if assertion passes, 1 if it fails

### bach::assert::empty

Assert that output is empty.

**Signature:**
```bash
bach::assert::empty "$output" "test_description"
```

**Parameters:**
- `$1` (output): The actual output to test
- `$2` (test_name): Description of the test

**Returns:** 0 if assertion passes, 1 if it fails

### bach::assert::section

Print a formatted section header for organizing tests.

**Signature:**
```bash
bach::assert::section "Section Name"
```

**Parameters:**
- `$1` (name): Name of the test section

### bach::assert::print_test_summary

Print a summary of test results including total, passed, and failed counts.

**Signature:**
```bash
bach::assert::print_test_summary
```

**Returns:** 0 if all tests passed, 1 if any failed

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
5. **Return proper exit codes**: Use `exit $?` after `bach::assert::print_test_summary`

## Roadmap

_No feature planned for the moment._

## See Also

- [tests.md](tests.md) - Test runner for executing multiple test files
- [parse_args.md](parse_args.md) - For testing CLI argument parsing
- [log.md](log.md) - For testing logging functionality
