#!/bin/bash

################################################################################
# Assert Library Demo
# Demonstrates assertion and testing capabilities
################################################################################

# Source bach.sh to get the bach command which dynamically loads libraries
# For sourcing libraries in your local context, see the README at ../../README.md
source ../../bach.sh

# Configure local library path for this demo
__BACH_CONFIG["libs_local_path_default"]="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.libs/bach"

main() {
    printf '\n%s\n\n' "========================================"
    printf '%s\n' "BACH Assert Library Demonstration"
    printf '%s\n\n' "========================================"

    # Section 1: Assert Contains
    printf '%s\n' "1. Testing with bach assert::contains"
    printf '%s\n' "==============================="
    printf '%s\n\n' "bach assert::contains checks if a string contains a substring:"

    # Start test section
    bach assert::section "String Containment Tests"

    local test_string="The quick brown fox jumps over the lazy dog"

    printf "Test string: '%s'\n\n" "$test_string"

    printf "Testing: 'brown' in string... "
    bach assert::contains "$test_string" "brown"
    printf "✓ PASSED\n"

    printf "Testing: 'fox' in string... "
    bach assert::contains "$test_string" "fox"
    printf "✓ PASSED\n"

    printf "Testing: 'The' in string... "
    bach assert::contains "$test_string" "The"
    printf "✓ PASSED\n"

    # Section 2: Assert Not Contains
    printf '\n%s\n' "2. Testing with bach assert::not_contains"
    printf '%s\n' "==================================="
    printf '%s\n\n' "bach assert::not_contains verifies a string does NOT contain a substring:"

    bach assert::section "Negative String Matching"

    printf "Test string: '%s'\n\n" "$test_string"

    printf "Testing: 'invisible' NOT in string... "
    bach assert::not_contains "$test_string" "invisible"
    printf "✓ PASSED\n"

    printf "Testing: 'XYZ' NOT in string... "
    bach assert::not_contains "$test_string" "XYZ"
    printf "✓ PASSED\n"

    printf "Testing: '12345' NOT in string... "
    bach assert::not_contains "$test_string" "12345"
    printf "✓ PASSED\n"

    # Section 3: Assert Empty
    printf '\n%s\n' "3. Testing with bach assert::empty"
    printf '%s\n' "============================"
    printf '%s\n\n' "bach assert::empty verifies that a variable is empty:"

    bach assert::section "Empty Variable Tests"

    local empty_var=""
    local filled_var="not empty"

    printf "Testing empty variable... "
    bach assert::empty "$empty_var"
    printf "✓ PASSED\n\n"

    printf "Testing non-empty variable (should fail in real tests):\n"
    printf "Variable content: '%s'\n\n" "$filled_var"

    # Section 4: Practical Testing Scenario
    printf '%s\n' "4. Practical Use Case - Function Validation"
    printf '%s\n' "========================================="
    printf '%s\n\n' "Using assertions to validate function behavior:"

    bach assert::section "Function Testing Scenario"

    # Test function
    process_input() {
        local input="$1"
        if [[ -z "$input" ]]; then
            echo "ERROR"
        else
            echo "PROCESSED: $input"
        fi
    }

    printf "Test 1: Process valid input\n"
    local result
    result=$(process_input "test_data")
    printf "Result: '%s'\n" "$result"
    bach assert::contains "$result" "PROCESSED"
    printf "✓ PASSED - Contains 'PROCESSED'\n\n"

    printf "Test 2: Verify error handling for empty input\n"
    result=$(process_input "")
    printf "Result: '%s'\n" "$result"
    bach assert::contains "$result" "ERROR"
    printf "✓ PASSED - Contains 'ERROR'\n\n"

    # Section 5: Email Validation Example
    printf '%s\n' "5. Validation Example - Email Patterns"
    printf '%s\n' "======================================"
    printf '%s\n\n' "Using assertions with pattern matching:"

    bach assert::section "Pattern Validation Tests"

    validate_email() {
        local email="$1"
        if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "VALID"
        else
            echo "INVALID"
        fi
    }

    local test_emails=("user@example.com" "test.user+tag@domain.co.uk" "invalid@" "@nodomain.com")

    for email in "${test_emails[@]}"; do
        result=$(validate_email "$email")
        printf "Email: %s -> %s\n" "$email" "$result"
        if [[ "$result" == "VALID" ]]; then
            bach assert::contains "$result" "VALID"
            printf "  ✓ Correctly identified as valid\n"
        else
            bach assert::contains "$result" "INVALID"
            printf "  ✓ Correctly identified as invalid\n"
        fi
    done

    # Section 6: Configuration Validation
    printf '\n%s\n' "6. Use Case - Configuration Validation"
    printf '%s\n' "======================================"
    printf '%s\n\n' "Testing application configuration:"

    bach assert::section "Configuration Validation"

    check_config() {
        local required_key="$1"
        local config_value="$2"
        if [[ -n "$config_value" ]]; then
            echo "CONFIG_OK: $required_key"
        else
            echo "CONFIG_MISSING: $required_key"
        fi
    }

    local db_host="localhost"
    local db_port="5432"
    local api_key=""

    printf "Checking database configuration...\n"
    result=$(check_config "DB_HOST" "$db_host")
    bach assert::contains "$result" "CONFIG_OK"
    printf "✓ DB_HOST configured\n"

    result=$(check_config "DB_PORT" "$db_port")
    bach assert::contains "$result" "CONFIG_OK"
    printf "✓ DB_PORT configured\n\n"

    printf "Checking API configuration...\n"
    result=$(check_config "API_KEY" "$api_key")
    bach assert::contains "$result" "CONFIG_MISSING"
    printf "✓ Correctly detected missing API_KEY\n"

    # Section 7: Test Summary
    printf '\n%s\n' "7. Printing Test Summary"
    printf '%s\n' "========================"
    printf '%s\n\n' "Using bach assert::print_test_summary to display overall results:"

    bach assert::print_test_summary

    # Summary
    printf '\n%s\n' "========================================"
    printf '%s\n' "Demo Complete!"
    printf '%s\n\n' "========================================"
}

# Direct execution guard
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
