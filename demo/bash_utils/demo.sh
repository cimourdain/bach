#!/bin/bash

################################################################################
# Bash Utils Library Demo
# Demonstrates string manipulation utilities
################################################################################

# Source bach.sh to get the bach command which dynamically loads libraries
# For sourcing libraries in your local context, see the README at ../../README.md
source ../../bach.sh

# Configure local library path for this demo
__BACH_CONFIG["libs_local_path_default"]="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.libs/bach"

main() {
    printf '\n%s\n\n' "========================================"
    printf '%s\n' "BACH Bash Utils Library Demonstration"
    printf '%s\n\n' "========================================"

    # Section 1: Finding First Index of Substring
    printf '%s\n' "1. Finding First Index of Substring"
    printf '%s\n' "===================================="
    printf '%s\n\n' "bach bash_utils::string::first_index_of_substring finds the first occurrence of a substring:"

    test_string="The quick brown fox jumps over the lazy dog"
    printf "String: '%s'\n\n" "$test_string"

    local idx
    idx=$(bach bash_utils::string::first_index_of_substring "$test_string" "brown")
    printf "Index of 'brown': %d\n" "$idx"

    idx=$(bach bash_utils::string::first_index_of_substring "$test_string" "quick")
    printf "Index of 'quick': %d\n" "$idx"

    idx=$(bach bash_utils::string::first_index_of_substring "$test_string" "dog")
    printf "Index of 'dog': %d\n" "$idx"

    idx=$(bach bash_utils::string::first_index_of_substring "$test_string" "notfound")
    printf "Index of 'notfound' (not in string): %d\n" "$idx"

    # Section 2: Extract Only Alphabetic Characters
    printf '\n%s\n' "2. Extract Only Alphabetic Characters"
    printf '%s\n' "======================================"
    printf '%s\n\n' "bach bash_utils::string::only_alpha removes all non-alphabetic characters:"

    test_string="Hello-World_123!"
    printf "Original: '%s'\n" "$test_string"
    local result
    result=$(bach bash_utils::string::only_alpha "$test_string")
    printf "Alpha only: '%s'\n\n" "$result"

    test_string="Version 2.5.3-beta+build.42"
    printf "Original: '%s'\n" "$test_string"
    result=$(bach bash_utils::string::only_alpha "$test_string")
    printf "Alpha only: '%s'\n\n" "$result"

    test_string="user@example.com"
    printf "Original: '%s'\n" "$test_string"
    result=$(bach bash_utils::string::only_alpha "$test_string")
    printf "Alpha only: '%s'\n" "$result"

    # Section 3: Extract Only Alphanumeric Characters
    printf '\n%s\n' "3. Extract Only Alphanumeric Characters"
    printf '%s\n' "========================================"
    printf '%s\n\n' "bach bash_utils::string::only_alphanumeric removes all non-alphanumeric characters:"

    test_string="Project-Name_v2.1.0"
    printf "Original: '%s'\n" "$test_string"
    result=$(bach bash_utils::string::only_alphanumeric "$test_string")
    printf "Alphanumeric only: '%s'\n\n" "$result"

    test_string="Email: user@domain.com (active)"
    printf "Original: '%s'\n" "$test_string"
    result=$(bach bash_utils::string::only_alphanumeric "$test_string")
    printf "Alphanumeric only: '%s'\n\n" "$result"

    test_string="Price: $99.99"
    printf "Original: '%s'\n" "$test_string"
    result=$(bach bash_utils::string::only_alphanumeric "$test_string")
    printf "Alphanumeric only: '%s'\n" "$result"

    # Section 4: Trim Leading Whitespace
    printf '\n%s\n' "4. Trim Leading Whitespace"
    printf '%s\n' "============================"
    printf '%s\n\n' "bach bash_utils::string::trim_leading_whitespaces removes leading spaces and tabs:"

    test_string="    Hello World"
    printf "Original (with markers): '|%s|'\n" "$test_string"
    result=$(bach bash_utils::string::trim_leading_whitespaces "$test_string")
    printf "Trimmed (with markers): '|%s|\n\n" "$result"

    test_string=$'\t\t\tTabbed line'
    printf "Original (with tabs): '|%s|'\n" "$test_string"
    result=$(bach bash_utils::string::trim_leading_whitespaces "$test_string")
    printf "Trimmed: '|%s|'\n\n" "$result"

    test_string="   Multiple   Spaces   Between"
    printf "Original: '|%s|'\n" "$test_string"
    result=$(bach bash_utils::string::trim_leading_whitespaces "$test_string")
    printf "Trimmed: '|%s|'\n" "$result"

    # Section 5: Generate Unique Hash
    printf '\n%s\n' "5. Generate Unique Hash for Strings"
    printf '%s\n' "===================================="
    printf '%s\n\n' "bach bash_utils::string::unique_hash generates a unique identifier for strings:"

    local -a test_strings=(
        "hello"
        "world"
        "bach library demo"
        "The quick brown fox"
        "hello"  # Duplicate - should produce same hash
    )

    for str in "${test_strings[@]}"; do
        local hash
        hash=$(bach bash_utils::string::unique_hash "$str")
        printf "Hash of '%s': %s\n" "$str" "$hash"
    done

    printf '\n%s\n\n' "Note: Same strings produce the same hash (see 'hello' appearing twice)"

    # Section 6: Practical Use Case - Filename Sanitization
    printf '%s\n' "6. Practical Use Case - Filename Sanitization"
    printf '%s\n' "=============================================="
    printf '%s\n\n' "Using string utilities to clean user input for filenames:"

    user_input="User-Data_v2.1.0-Report!@#"
    printf "User input: '%s'\n" "$user_input"

    local safe_name
    safe_name=$(bach bash_utils::string::only_alphanumeric "$user_input")
    printf "Sanitized filename: '%s.txt'\n" "$safe_name"

    # Section 7: Practical Use Case - Configuration Key Validation
    printf '\n%s\n' "7. Practical Use Case - Configuration Key Validation"
    printf '%s\n' "====================================================="
    printf '%s\n\n' "Ensuring configuration keys are valid (alphanumeric only):"

    local -a config_keys=("api_key" "db-host" "MAX_CONNECTIONS" "user@domain" "port_8080")

    for key in "${config_keys[@]}"; do
        local valid_key
        valid_key=$(bach bash_utils::string::only_alphanumeric "$key")

        if [[ "$key" == "$valid_key" ]]; then
            printf "✓ '%s' is valid\n" "$key"
        else
            printf "✗ '%s' contains invalid characters (sanitized: '%s')\n" "$key" "$valid_key"
        fi
    done

    # Summary
    printf '\n%s\n' "========================================"
    printf '%s\n' "Demo Complete!"
    printf '%s\n\n' "========================================"
}

# Direct execution guard
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
