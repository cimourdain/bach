#!/bin/bash

# Test suite for the bash_utils library

SCRIPT_DIR=""

test_re_sourcing_prevention() {
    bach::assert::section "Test re-sourcing prevention"
    local functions=(
        first_index_of_substring index_of_any_substring unique_hash
        only_alpha only_alphanumeric trim_leading_whitespaces
    )
    local func
    for func in "${functions[@]}"; do
        declare -F "bach::bash_utils::string::${func}" &>/dev/null
        bach::assert::contains "$?" "0" "string::${func} is declared after first source"
    done

    # Replace a function, then source again: the guard must prevent the redefinition
    bach::bash_utils::string::only_alpha() { echo "overridden"; }
    source "${SCRIPT_DIR}/bash_utils.sh"
    local output
    output=$(bach::bash_utils::string::only_alpha "abc")
    bach::assert::contains "$output" "overridden" "Re-sourcing does not redefine the functions"

    # Remove one function: sourcing again must restore the library
    unset -f bach::bash_utils::array::sort
    source "${SCRIPT_DIR}/bash_utils.sh"
    declare -F bach::bash_utils::array::sort &>/dev/null
    bach::assert::contains "$?" "0" "Sourcing with a missing function declares the library again"
}

test_first_index_of_substring() {
    bach::assert::section "Test first_index_of_substring"
    local output status

    output=$(bach::bash_utils::string::first_index_of_substring "hello world" "world")
    bach::assert::contains "$output" "6" "Substring in the middle returns its index"

    output=$(bach::bash_utils::string::first_index_of_substring "hello world" "hello")
    bach::assert::contains "$output" "0" "Substring at the start returns 0"

    output=$(bach::bash_utils::string::first_index_of_substring "abcabc" "bc")
    bach::assert::contains "$output" "1" "Only the first occurrence is returned"

    output=$(bach::bash_utils::string::first_index_of_substring "hello" "xyz")
    status=$?
    bach::assert::contains "$output" "-1" "Missing substring returns -1"
    bach::assert::contains "$status" "1" "Missing substring returns status 1"
}

test_index_of_any_substring() {
    bach::assert::section "Test index_of_any_substring"
    local output status
    local -a delimiters=("-" "_")

    output=$(bach::bash_utils::string::index_of_any_substring "foo-bar_baz" delimiters)
    bach::assert::contains "$output" "4" "Returns the index following the first delimiter found"

    output=$(bach::bash_utils::string::index_of_any_substring "foo-bar_baz" delimiters 1)
    bach::assert::contains "$output" "8" "Occurrence index 1 returns the second delimiter match"

    local -a words=("bar" "foo")
    output=$(bach::bash_utils::string::index_of_any_substring "foo-bar" words)
    bach::assert::contains "$output" "3" "Returns the end index of the earliest matching substring"

    local -a missing=("x" "y")
    output=$(bach::bash_utils::string::index_of_any_substring "foo-bar" missing)
    status=$?
    bach::assert::contains "$output" "-1" "No matching substring returns -1"
    bach::assert::contains "$status" "1" "No matching substring returns status 1"

    output=$(bach::bash_utils::string::index_of_any_substring "foo-bar" delimiters 5)
    bach::assert::contains "$output" "-1" "Out of range occurrence index returns -1"
}

test_unique_hash() {
    bach::assert::section "Test unique_hash"
    local hash1 hash2 hash3
    hash1=$(bach::bash_utils::string::unique_hash "hello")
    hash2=$(bach::bash_utils::string::unique_hash "hello")
    hash3=$(bach::bash_utils::string::unique_hash "world")

    bach::assert::contains "$hash1" "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824" "Hash is the sha256 of the string"
    bach::assert::contains "$hash1" "$hash2" "Same string gives the same hash"
    bach::assert::not_contains "$hash1" "$hash3" "Different strings give different hashes"
}

test_only_alpha() {
    bach::assert::section "Test only_alpha"
    local output

    output=$(bach::bash_utils::string::only_alpha "a1b2-c3 D!")
    bach::assert::contains "$output" "abcD" "Digits, symbols and spaces are removed"

    output=$(bach::bash_utils::string::only_alpha "123 !?")
    bach::assert::empty "$output" "String without letters gives an empty result"
}

test_only_alphanumeric() {
    bach::assert::section "Test only_alphanumeric"
    local output

    output=$(bach::bash_utils::string::only_alphanumeric "a1b2-c3 D!")
    bach::assert::contains "$output" "a1b2c3D" "Symbols and spaces are removed"

    output=$(bach::bash_utils::string::only_alphanumeric "-- !?")
    bach::assert::empty "$output" "String without alphanumeric characters gives an empty result"
}

test_trim_leading_whitespaces() {
    bach::assert::section "Test trim_leading_whitespaces"
    local output

    output=$(bach::bash_utils::string::trim_leading_whitespaces "   hello  ")
    bach::assert::contains "$output" "hello  " "Leading spaces are removed, trailing ones are kept"
    bach::assert::not_contains "${output:0:1}" " " "Result does not start with a space"

    output=$(bach::bash_utils::string::trim_leading_whitespaces $'\t\n  tabbed')
    bach::assert::contains "$output" "tabbed" "Tabs and newlines are removed"
    bach::assert::contains "${#output}" "6" "Only the text remains"

    output=$(bach::bash_utils::string::trim_leading_whitespaces "   ")
    bach::assert::empty "$output" "Whitespace only string gives an empty result"
}

test_array_sort() {
    bach::assert::section "Test array::sort"
    local -a numbers=(10 2 33 1)
    bach::bash_utils::array::sort numbers
    bach::assert::contains "${numbers[*]}" "1 2 10 33" "Array is sorted numerically in place"

    local -a already_sorted=(1 2 3)
    bach::bash_utils::array::sort already_sorted
    bach::assert::contains "${already_sorted[*]}" "1 2 3" "Sorted array is unchanged"
}

main() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    source "${SCRIPT_DIR}/assert.sh"
    source "${SCRIPT_DIR}/../bach.sh"
    # bash_utils relies on the `bach` function to load the libs it depends on
    __BACH_CONFIG["libs_local_path_default"]="${SCRIPT_DIR}"
    source "${SCRIPT_DIR}/bash_utils.sh"

    printf '%b\n' "${YELLOW}Running bach::bash_utils tests...${RESET}"

    test_re_sourcing_prevention
    test_first_index_of_substring
    test_index_of_any_substring
    test_unique_hash
    test_only_alpha
    test_only_alphanumeric
    test_trim_leading_whitespaces
    test_array_sort

    bach::assert::print_test_summary
    exit $?
}

main "$@"
