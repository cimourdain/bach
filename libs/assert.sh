#!/bin/bash

################################################################################
# Test Assertion Helper Functions
################################################################################
# Description:
#   Provides assertion helper functions for test suites. Includes assertions
#   for content verification (contains, not contains, empty), section headers,
#   and test result summarization. Functions use color-coded output for
#   better readability.
#
# Usage:
#   source /path/to/assert.sh
#   bach::assert::contains "$output" "expected" "Test description"
#
# Examples:
#   # Test that output contains a string
#   output=$(my_command)
#   bach::assert::contains "$output" "success" "Command should succeed"
#
#   # Test that output is empty
#   output=$(silent_command)
#   bach::assert::empty "$output" "Command should produce no output"
#
#   # Print test section header
#   bach::assert::section "Testing feature X"
#
# Dependencies:
#   - bash 4.0+
#
# Author: BACHCLI Project
# Version: 1.0.0
################################################################################

# Prevent re-sourcing if functions already declared
if declare -F bach::assert::contains &>/dev/null && \
   declare -F bach::assert::not_contains &>/dev/null && \
   declare -F bach::assert::empty &>/dev/null && \
   declare -F bach::assert::section &>/dev/null && \
   declare -F bach::assert::print_test_summary &>/dev/null; then
    return 0
fi

# Test assertion helper functions
# Note: Test counters and colors are managed by tests/main.sh when running via test runner
# Individual test files can still define them locally if run standalone

# Test counters (use exported values if available, otherwise initialize)
: "${total_tests:=0}"
: "${passed_tests:=0}"
: "${failed_tests:=0}"

# Color codes for test output (use exported values if available, otherwise initialize)
: "${GREEN:=\033[0;32m}"
: "${RED:=\033[0;31m}"
: "${YELLOW:=\033[0;33m}"
: "${BLUE:=\033[0;34m}"
: "${RESET:=\033[0m}"

################################################################################
# Assert that output contains expected string
# Arguments:
#   $1 - output: Actual output to test
#   $2 - expected: String expected to be contained in output
#   $3 - test_name: Description of the test
# Globals:
#   total_tests - Incremented test counter
#   passed_tests - Incremented on success
#   failed_tests - Incremented on failure
# Returns:
#   0 if output contains expected string, 1 otherwise
################################################################################
bach::assert::contains() {
    local output="$1"
    local expected="$2"
    local test_name="$3"

    total_tests=$((total_tests + 1))

    if [[ "$output" == *"$expected"* ]]; then
        printf '%b\n' "${GREEN}✓${RESET} $test_name"
        passed_tests=$((passed_tests + 1))
        return 0
    else
        printf '%b\n' "${RED}✗${RESET} $test_name"
        printf '%b\n' "  ${RED}Expected to contain:${RESET} $expected"
        printf '%b\n' "  ${RED}Got:${RESET} $output"
        failed_tests=$((failed_tests + 1))
        return 1
    fi
}
export -f bach::assert::contains

################################################################################
# Assert that output does not contain unexpected string
# Arguments:
#   $1 - output: Actual output to test
#   $2 - unexpected: String that should NOT be in output
#   $3 - test_name: Description of the test
# Globals:
#   total_tests - Incremented test counter
#   passed_tests - Incremented on success
#   failed_tests - Incremented on failure
# Returns:
#   0 if output does not contain unexpected string, 1 otherwise
################################################################################
bach::assert::not_contains() {
    local output="$1"
    local unexpected="$2"
    local test_name="$3"

    total_tests=$((total_tests + 1))

    if [[ "$output" != *"$unexpected"* ]]; then
        printf '%b\n' "${GREEN}✓${RESET} $test_name"
        passed_tests=$((passed_tests + 1))
        return 0
    else
        printf '%b\n' "${RED}✗${RESET} $test_name"
        printf '%b\n' "  ${RED}Expected NOT to contain:${RESET} $unexpected"
        printf '%b\n' "  ${RED}Got:${RESET} $output"
        failed_tests=$((failed_tests + 1))
        return 1
    fi
}
export -f bach::assert::not_contains

################################################################################
# Assert that output is empty
# Arguments:
#   $1 - output: Actual output to test
#   $2 - test_name: Description of the test
# Globals:
#   total_tests - Incremented test counter
#   passed_tests - Incremented on success
#   failed_tests - Incremented on failure
# Returns:
#   0 if output is empty, 1 otherwise
################################################################################
bach::assert::empty() {
    local output="$1"
    local test_name="$2"

    total_tests=$((total_tests + 1))

    if [[ -z "$output" ]]; then
        printf '%b\n' "${GREEN}✓${RESET} $test_name"
        passed_tests=$((passed_tests + 1))
        return 0
    else
        printf '%b\n' "${RED}✗${RESET} $test_name"
        printf '%b\n' "  ${RED}Expected empty output${RESET}"
        printf '%b\n' "  ${RED}Got:${RESET} $output"
        failed_tests=$((failed_tests + 1))
        return 1
    fi
}
export -f bach::assert::empty

################################################################################
# Print test section header
# Displays a formatted section header for organizing test output
# Arguments:
#   $1 - section_title: Title of the test section
# Globals:
#   BLUE, RESET - Color codes for formatting
# Returns:
#   0 always
################################################################################
bach::assert::section() {
    printf '\n'
    printf '%b\n' "${BLUE}━━━ $1 ━━━${RESET}"
}
export -f bach::assert::section

################################################################################
# Print test summary
# Displays a formatted summary of test results including total, passed, and failed counts
# Arguments:
#   None
# Globals:
#   total_tests - Total number of tests run
#   passed_tests - Number of tests that passed
#   failed_tests - Number of tests that failed
#   YELLOW, BLUE, GREEN, RED, RESET - Color codes for formatting
# Returns:
#   0 if all tests passed, non-zero if any tests failed
################################################################################
bach::assert::print_test_summary() {
    printf '\n'
    printf '%b\n' "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    printf '%b\n' "${BLUE}Test Summary${RESET}"
    printf '%b\n' "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    printf '%b\n' "Total tests:  $total_tests"
    printf '%b\n' "${GREEN}Passed:${RESET}       $passed_tests"
    printf '%b\n' "${RED}Failed:${RESET}       $failed_tests"

    if [[ $failed_tests -eq 0 ]]; then
        printf '%b\n' "\n${GREEN}All tests passed! ✓${RESET}\n"
        return 0
    else
        printf '%b\n' "\n${RED}Some tests failed! ✗${RESET}\n"
    fi
}
export -f bach::assert::print_test_summary
