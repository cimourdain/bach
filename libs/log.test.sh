#!/bin/bash

# Test suite for bach::log function

# Global variable for script directory
SCRIPT_DIR=""

test_re_sourcing_prevention() {
    section "Test re-sourcing prevention"
    if declare -F bach::log &>/dev/null; then
        local result="exists"
    else
        local result="missing"
    fi
    assert_contains "$result" "exists" "bach::log function exists after first source"

    # Source again and verify function still exists
    source "${SCRIPT_DIR}/log.sh" 2>&1
    if declare -F bach::log &>/dev/null; then
        result="exists"
    else
        result="missing"
    fi
    assert_contains "$result" "exists" "bach::log function exists after re-sourcing"
}

test_default_log_level() {
    section "Test default log level"
    local output
    output=$(bach::log "Test message" 2>&1)
    assert_contains "$output" "INFO" "Default level should be INFO"
    assert_contains "$output" "Test message" "Default level should contain message"
}

test_all_log_levels() {
    section "Test all log levels"
    local output

    output=$(bach::log -v "Verbose test" 2>&1)
    assert_contains "$output" "VERBOSE" "Verbose level flag"
    assert_contains "$output" "Verbose test" "Verbose message"

    output=$(bach::log -t "Trace test" 2>&1)
    assert_contains "$output" "TRACE" "Trace level flag"
    assert_contains "$output" "Trace test" "Trace message"

    output=$(bach::log -d "Debug test" 2>&1)
    assert_contains "$output" "DEBUG" "Debug level flag"
    assert_contains "$output" "Debug test" "Debug message"

    output=$(bach::log -i "Info test" 2>&1)
    assert_contains "$output" "INFO" "Info level flag"
    assert_contains "$output" "Info test" "Info message"

    output=$(bach::log -w "Warning test" 2>&1)
    assert_contains "$output" "WARNING" "Warning level flag"
    assert_contains "$output" "Warning test" "Warning message"

    output=$(bach::log -e "Error test" 2>&1)
    assert_contains "$output" "ERROR" "Error level flag"
    assert_contains "$output" "Error test" "Error message"

    output=$(bach::log -f "Fatal test" 2>&1)
    assert_contains "$output" "FATAL" "Fatal level flag"
    assert_contains "$output" "Fatal test" "Fatal message"
}

test_long_form_flags() {
    section "Test long form flags"
    local output

    output=$(bach::log --verbose "Long verbose" 2>&1)
    assert_contains "$output" "VERBOSE" "Long verbose flag"

    output=$(bach::log --trace "Long trace" 2>&1)
    assert_contains "$output" "TRACE" "Long trace flag"

    output=$(bach::log --debug "Long debug" 2>&1)
    assert_contains "$output" "DEBUG" "Long debug flag"

    output=$(bach::log --info "Long info" 2>&1)
    assert_contains "$output" "INFO" "Long info flag"

    output=$(bach::log --warning "Long warning" 2>&1)
    assert_contains "$output" "WARNING" "Long warning flag"

    output=$(bach::log --error "Long error" 2>&1)
    assert_contains "$output" "ERROR" "Long error flag"

    output=$(bach::log --fatal "Long fatal" 2>&1)
    assert_contains "$output" "FATAL" "Long fatal flag"
}

test_log_level_verbose() {
    section "Test LOG_LEVEL=verbose (shows all)"
    local output

    output=$(LOG_LEVEL=verbose bach::log -v "Verbose msg" 2>&1)
    assert_contains "$output" "Verbose msg" "Verbose shown when LOG_LEVEL=verbose"

    output=$(LOG_LEVEL=verbose bach::log -t "Trace msg" 2>&1)
    assert_contains "$output" "Trace msg" "Trace shown when LOG_LEVEL=verbose"

    output=$(LOG_LEVEL=verbose bach::log -d "Debug msg" 2>&1)
    assert_contains "$output" "Debug msg" "Debug shown when LOG_LEVEL=verbose"

    output=$(LOG_LEVEL=verbose bach::log -i "Info msg" 2>&1)
    assert_contains "$output" "Info msg" "Info shown when LOG_LEVEL=verbose"
}

test_log_level_info() {
    section "Test LOG_LEVEL=info (filters verbose, trace, debug)"
    local output

    output=$(LOG_LEVEL=info bach::log -v "Verbose filtered" 2>&1)
    assert_empty "$output" "Verbose filtered when LOG_LEVEL=info"

    output=$(LOG_LEVEL=info bach::log -t "Trace filtered" 2>&1)
    assert_empty "$output" "Trace filtered when LOG_LEVEL=info"

    output=$(LOG_LEVEL=info bach::log -d "Debug filtered" 2>&1)
    assert_empty "$output" "Debug filtered when LOG_LEVEL=info"

    output=$(LOG_LEVEL=info bach::log -i "Info shown" 2>&1)
    assert_contains "$output" "Info shown" "Info shown when LOG_LEVEL=info"

    output=$(LOG_LEVEL=info bach::log -w "Warning shown" 2>&1)
    assert_contains "$output" "Warning shown" "Warning shown when LOG_LEVEL=info"
}

test_log_level_error() {
    section "Test LOG_LEVEL=error (only error and fatal)"
    local output

    output=$(LOG_LEVEL=error bach::log -d "Debug filtered" 2>&1)
    assert_empty "$output" "Debug filtered when LOG_LEVEL=error"

    output=$(LOG_LEVEL=error bach::log -i "Info filtered" 2>&1)
    assert_empty "$output" "Info filtered when LOG_LEVEL=error"

    output=$(LOG_LEVEL=error bach::log -w "Warning filtered" 2>&1)
    assert_empty "$output" "Warning filtered when LOG_LEVEL=error"

    output=$(LOG_LEVEL=error bach::log -e "Error shown" 2>&1)
    assert_contains "$output" "Error shown" "Error shown when LOG_LEVEL=error"

    output=$(LOG_LEVEL=error bach::log -f "Fatal shown" 2>&1)
    assert_contains "$output" "Fatal shown" "Fatal shown when LOG_LEVEL=error"
}

test_log_level_case_insensitivity() {
    section "Test LOG_LEVEL case insensitivity"
    local output

    output=$(LOG_LEVEL=INFO bach::log -i "Info message" 2>&1)
    assert_contains "$output" "Info message" "LOG_LEVEL=INFO (uppercase) works"

    output=$(LOG_LEVEL=WaRnInG bach::log -w "Warning message" 2>&1)
    assert_contains "$output" "Warning message" "LOG_LEVEL=WaRnInG (mixed case) works"

    output=$(LOG_LEVEL=WaRnInG bach::log -d "Debug filtered" 2>&1)
    assert_empty "$output" "Mixed case LOG_LEVEL filters correctly"
}

test_timestamp_format() {
    section "Test timestamp format"
    local output
    output=$(bach::log -i "Timestamp test" 2>&1)
    assert_contains "$output" "[20" "Timestamp starts with [20 (year)"
    assert_contains "$output" ":" "Timestamp contains colons"
}

test_empty_and_special_messages() {
    section "Test empty and special messages"
    local output

    output=$(bach::log -i "" 2>&1)
    assert_contains "$output" "INFO" "Empty message still shows log level"

    output=$(bach::log -i "Message with spaces" 2>&1)
    assert_contains "$output" "Message with spaces" "Message with spaces"

    output=$(bach::log -i "Special chars: !@#$%^&*()" 2>&1)
    assert_contains "$output" "Special chars: !@#$%^&*()" "Special characters in message"
}

test_invalid_log_level() {
    section "Test invalid LOG_LEVEL"
    local output

    output=$(LOG_LEVEL=invalid bach::log -v "Verbose shown" 2>&1)
    assert_contains "$output" "Verbose shown" "Invalid LOG_LEVEL doesn't filter"

    output=$(LOG_LEVEL=999 bach::log -d "Debug shown" 2>&1)
    assert_contains "$output" "Debug shown" "Numeric LOG_LEVEL doesn't filter"
}

test_argument_parsing() {
    section "Test argument parsing"
    local output
    output=$(bach::log -i "First message" "Second ignored" 2>&1)
    assert_contains "$output" "First message" "First message logged"
    assert_not_contains "$output" "Second ignored" "Second argument ignored"
}

main() {
    # Get script directory and source required files
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Source the log library and test assertions (both in same directory now)
    source "${SCRIPT_DIR}/log.sh"
    source "${SCRIPT_DIR}/assert.sh"

    # Start tests
    printf '%b\n' "${YELLOW}Running bach::log tests...${RESET}"

    # Run all tests
    test_re_sourcing_prevention
    test_default_log_level
    test_all_log_levels
    test_long_form_flags
    test_log_level_verbose
    test_log_level_info
    test_log_level_error
    test_log_level_case_insensitivity
    test_timestamp_format
    test_empty_and_special_messages
    test_invalid_log_level
    test_argument_parsing

    # Print summary and exit
    print_test_summary
    exit $?
}

# Run main function
main "$@"
