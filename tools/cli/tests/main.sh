#!/bin/bash

# Main test runner
# Usage: ./tests/main.sh [pattern]
# Default pattern: tests/**/*.test.sh

set -euo pipefail

run_test_file() {
    local test_file="$1"
    local project_root="$2"
    
    local rel_path="${test_file#$project_root/}"
    
    # Headers go to fd 3 (will be mapped to stdout by caller)
    printf '\n' >&3
    printf '%b\n' "${CYAN}┌─────────────────────────────────────────┐${RESET}" >&3
    printf '%b\n' "${CYAN}│${RESET} ${BLUE}Running:${RESET} ${rel_path}" >&3
    printf '%b\n' "${CYAN}└─────────────────────────────────────────┘${RESET}" >&3
    
    # Run the test file and capture both output and exit status
    local output
    output=$("$test_file" 2>&1)
    local exit_code=$?
    
    # Display the output to fd 3 (will be mapped to stdout by caller)
    printf '%s\n' "$output" >&3
    
    # Strip ANSI color codes for parsing
    local output_clean
    output_clean=$(printf '%s' "$output" | sed 's/\x1b\[[0-9;]*m//g')
    
    # Extract test counts from the output (looking for the summary section)
    local suite_total=0
    local suite_pass=0
    local suite_fail=0
    
    if [[ "$output_clean" =~ Total\ tests:[[:space:]]+([0-9]+) ]]; then
        suite_total="${BASH_REMATCH[1]}"
    fi
    
    if [[ "$output_clean" =~ Passed:[[:space:]]+([0-9]+) ]]; then
        suite_pass="${BASH_REMATCH[1]}"
    fi
    
    if [[ "$output_clean" =~ Failed:[[:space:]]+([0-9]+) ]]; then
        suite_fail="${BASH_REMATCH[1]}"
    fi
    
    # Output results to stderr (so they don't interfere with test output)
    printf '%s\n' "$exit_code $suite_total $suite_pass $suite_fail" >&2
}

print_overall_summary() {
    local suite_count="$1"
    local suite_passed="$2"
    local suite_failed="$3"
    local total_tests="$4"
    local passed_tests="$5"
    local failed_tests="$6"
    
    printf '\n' >&2
    printf '%b\n' "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
    printf '%b\n' "${BLUE}Overall Test Summary${RESET}" >&2
    printf '%b\n' "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
    printf '%b\n' "Test Suites:  ${suite_count}" >&2
    printf '%b\n' "${GREEN}  Passed:${RESET}     ${suite_passed}" >&2
    printf '%b\n' "${RED}  Failed:${RESET}     ${suite_failed}" >&2
    printf '\n' >&2
    printf '%b\n' "Total Tests:  ${total_tests}" >&2
    printf '%b\n' "${GREEN}  Passed:${RESET}     ${passed_tests}" >&2
    printf '%b\n' "${RED}  Failed:${RESET}     ${failed_tests}" >&2

    if [[ $failed_tests -eq 0 && $suite_failed -eq 0 ]]; then
        printf '\n' >&2
        printf '%b\n' "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
        printf '%b\n' "${GREEN}All tests passed! ✓${RESET}" >&2
        printf '%b\n' "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
        printf '\n' >&2
        return 0
    else
        printf '\n' >&2
        printf '%b\n' "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
        printf '%b\n' "${RED}Some tests failed! ✗${RESET}" >&2
        printf '%b\n' "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
        printf '\n' >&2
        return 1
    fi
}

main() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(dirname "$script_dir")"
    
    # Mark that we're running from test runner (exported for conditional behavior)
    export TEST_RUNNER=1
    
    # Color codes for test output - exported for test files
    export GREEN="\033[0;32m"
    export RED="\033[0;31m"
    export YELLOW="\033[0;33m"
    export BLUE="\033[0;34m"
    export CYAN="\033[0;36m"
    export RESET="\033[0m"
    
    # Source assertion helpers
    source "$script_dir/assert.sh"
    
    # Get test pattern from argument or use default
    local pattern="${1:-tests/**/*.test.sh}"
    
    # Find all test files matching the pattern
    printf '%b\n' "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
    printf '%b\n' "${BLUE}Running Test Suite${RESET}" >&2
    printf '%b\n' "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
    printf '%b\n' "Pattern: ${YELLOW}$pattern${RESET}" >&2
    printf '\n' >&2
    
    # Convert pattern to find arguments
    local -a find_args
    if [[ "$pattern" == *".test.sh" ]]; then
        # Specific .test.sh pattern
        local base_pattern="${pattern%.test.sh}"
        find_args=( "$project_root" -type f \( -name "*.test.sh" -o -name "*.test" \) -path "$project_root/${base_pattern}*" )
    elif [[ "$pattern" == *".test" ]]; then
        # Specific .test pattern
        local base_pattern="${pattern%.test}"
        find_args=( "$project_root" -type f \( -name "*.test.sh" -o -name "*.test" \) -path "$project_root/${base_pattern}*" )
    else
        # General pattern - use as glob pattern
        find_args=( "$project_root" -type f \( -name "*.test.sh" -o -name "*.test" \) -path "$project_root/$pattern" )
    fi
    
    # Find and sort test files
    local -a test_files
    mapfile -t test_files < <(find "${find_args[@]}" 2>/dev/null | sort)
    
    if [[ ${#test_files[@]} -eq 0 ]]; then
        printf '%b\n' "${RED}No test files found matching pattern: $pattern${RESET}" >&2
        exit 1
    fi
    
    printf '%b\n' "${BLUE}Found ${#test_files[@]} test file(s)${RESET}" >&2
    
    # Track test suites
    local suite_count=0
    local suite_passed=0
    local suite_failed=0
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    # Run each test file
    for test_file in "${test_files[@]}"; do
        if [[ ! -x "$test_file" ]]; then
            printf '%b\n' "${YELLOW}⚠${RESET} Skipping non-executable: $(basename "$test_file")" >&2
            continue
        fi
        
        suite_count=$((suite_count + 1))
        
        # Run test and capture results from stderr
        local results
        results=$(run_test_file "$test_file" "$project_root" 2>&1 1>&3)
        
        # Parse results
        read -r exit_code suite_total suite_pass suite_fail <<< "$results"
        
        # Update overall counters
        total_tests=$((total_tests + suite_total))
        passed_tests=$((passed_tests + suite_pass))
        failed_tests=$((failed_tests + suite_fail))
        
        if [[ $exit_code -eq 0 ]]; then
            suite_passed=$((suite_passed + 1))
            printf '%b\n' "${GREEN}✓${RESET} Suite completed: ${suite_pass}/${suite_total} passed" >&2
        else
            suite_failed=$((suite_failed + 1))
            printf '%b\n' "${RED}✗${RESET} Suite failed: ${suite_pass}/${suite_total} passed" >&2
        fi
    done 3>&1
    
    # Print overall summary and exit with appropriate code
    if print_overall_summary "$suite_count" "$suite_passed" "$suite_failed" "$total_tests" "$passed_tests" "$failed_tests"; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"

