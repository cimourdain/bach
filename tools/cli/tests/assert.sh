#!/bin/bash

# Prevent re-sourcing if functions already declared
if declare -F assert_contains &>/dev/null && \
   declare -F assert_not_contains &>/dev/null && \
   declare -F assert_empty &>/dev/null && \
   declare -F section &>/dev/null && \
   declare -F print_test_summary &>/dev/null; then
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

# Assert that output contains expected string
assert_contains() {
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

# Assert that output does not contain unexpected string
assert_not_contains() {
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

# Assert that output is empty
assert_empty() {
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

# Print test section header
section() {
    printf '\n'
    printf '%b\n' "${BLUE}━━━ $1 ━━━${RESET}"
}

# Print test summary
print_test_summary() {
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
