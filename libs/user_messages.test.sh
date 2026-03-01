#!/usr/bin/env bash

# Test suite for user_messages.sh library
# Tests basic functionality, emoji combinations, headers, and edge cases

set -o pipefail

# Prevent re-sourcing if function already declared
if declare -F bach::user_msg &>/dev/null; then
    return 0
fi

# Source the library
_test_script_dir="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
source "${_test_script_dir}/user_messages.sh"

# Test counter and tracking
_test_tests_run=0
_test_tests_passed=0
_test_tests_failed=0

# Internal: Helper function to run a test
# Arguments:
#   $1: Test name
#   $2: Expected output substring
#   $@: Command to run
user_messages_test::run_case() {
    local -r test_name="$1"
    local -r expected_output="$2"
    shift 2

    ((_test_tests_run++))

    local actual_output
    # Run command directly in this shell instead of subshell
    actual_output=$("$@" 2>&1)

    if [[ "$actual_output" == *"$expected_output"* ]]; then
        ((_test_tests_passed++))
        echo "✓ $test_name"
    else
        ((_test_tests_failed++))
        echo "✗ $test_name"
        echo "  Expected substring: $expected_output"
        echo "  Got: $actual_output"
    fi
}

echo "Running user_messages.sh tests..."
echo ""

# Test 1: Basic message without emojis or headers
user_messages_test::run_case "Basic message output" "Hello world" \
    bach::user_msg "Hello world"

# Test 2: Message with single emoji
user_messages_test::run_case "Single emoji prefix" "🚀" \
    bach::user_msg --start "Building"

# Test 3: Message with multiple emojis
user_messages_test::run_case "Multiple emoji prefixes" "🚀 ⏳" \
    bach::user_msg --start --wait "Building project"

# Test 4: Success emoji
user_messages_test::run_case "Success emoji" "✅" \
    bach::user_msg --success "Done"

# Test 5: Warning emoji
user_messages_test::run_case "Warning emoji" "⚠" \
    bach::user_msg --warning "Caution"

# Test 6: Fail emoji
user_messages_test::run_case "Fail emoji" "❌" \
    bach::user_msg --fail "Error"

# Test 7: H1 header format
user_messages_test::run_case "H1 header - contains message" "I AM A HEADER" \
    bach::user_msg --h1 "I am a header"

# Test 8: H1 header contains border characters
user_messages_test::run_case "H1 header - contains # character" "#" \
    bach::user_msg --h1 "Title"

# Test 9: H2 header format
user_messages_test::run_case "H2 header - contains message" "Section Title" \
    bach::user_msg --h2 "Section Title"

# Test 10: H2 header contains underline
user_messages_test::run_case "H2 header - has # underline" "#" \
    bach::user_msg --h2 "Test"

# Test 11: H3 header format
user_messages_test::run_case "H3 header - contains message" "Subsection" \
    bach::user_msg --h3 "Subsection"

# Test 12: H3 header has underline
user_messages_test::run_case "H3 header - has # underline" "#" \
    bach::user_msg --h3 "Test"

# Test 13: H4 header format
user_messages_test::run_case "H4 header - contains message" "Minor Header" \
    bach::user_msg --h4 "Minor Header"

# Test 14: H4 header has dash underline
user_messages_test::run_case "H4 header - has - underline" "-" \
    bach::user_msg --h4 "Test"

# Test 15: H5 header format
user_messages_test::run_case "H5 header - contains message" "Minimal" \
    bach::user_msg --h5 "Minimal"

# Test 16: Case-insensitive emoji options
user_messages_test::run_case "Case-insensitive emoji option" "🚀" \
    bach::user_msg --START "test"

# Test 17: Message with special characters
user_messages_test::run_case "Message with special characters" "Building: project-v1.0" \
    bach::user_msg "Building: project-v1.0"

# Test 18: Empty message handling
user_messages_test::run_case "Empty message" "" \
    bach::user_msg ""

# Test 19: Message with numbers
user_messages_test::run_case "Message with numbers" "Process ID 12345" \
    bach::user_msg "Process ID 12345"

# Test 20: Emoji with long message
user_messages_test::run_case "Emoji with long message" "🚀 This is a longer message with more details about the operation" \
    bach::user_msg --start "This is a longer message with more details about the operation"

# Test 21: Multiple different emojis
user_messages_test::run_case "Multiple different emojis" "✅ ⚠" \
    bach::user_msg --success --warning "Mixed status"

# Test 22: Update emoji
user_messages_test::run_case "Update emoji" "♻" \
    bach::user_msg --update "Refreshing"

# Test 23: Repair emoji
user_messages_test::run_case "Repair emoji" "🔧" \
    bach::user_msg --repair "Fixing"

# Test 24: Clean emoji
user_messages_test::run_case "Clean emoji" "🧹" \
    bach::user_msg --clean "Cleaning"

# Test 25: Test emoji
user_messages_test::run_case "Test emoji" "🧪" \
    bach::user_msg --test "Running tests"

# Test 26: Secure emoji
user_messages_test::run_case "Secure emoji" "🔒" \
    bach::user_msg --secure "Encrypted"

# Test 27: Send emoji
user_messages_test::run_case "Send emoji" "📩" \
    bach::user_msg --send "Sending"

# Test 28: Call emoji
user_messages_test::run_case "Call emoji" "☎" \
    bach::user_msg --call "Contacting"

# Test 29: Save emoji
user_messages_test::run_case "Save emoji" "💾" \
    bach::user_msg --save "Saving"

# Test 30: Inspect emoji
user_messages_test::run_case "Inspect emoji" "👓" \
    bach::user_msg --inspect "Analyzing"

# Test 31: Extra emoji
user_messages_test::run_case "Extra emoji" "🎁" \
    bach::user_msg --extra "Bonus content"

# Test 32: Wait emoji
user_messages_test::run_case "Wait emoji" "⏳" \
    bach::user_msg --wait "Processing"

# Test 33: Build emoji
user_messages_test::run_case "Build emoji" "👷" \
    bach::user_msg --build "Constructing"

# Test 34: Kill emoji
user_messages_test::run_case "Kill emoji" "💀" \
    bach::user_msg --kill "Terminating"

# Test 35: H1 with uppercase conversion
user_messages_test::run_case "H1 header converts to uppercase" "TESTING UPPERCASE CONVERSION" \
    bach::user_msg --h1 "testing uppercase conversion"

# Summary
echo ""
echo "=================================="
echo "Test Results"
echo "=================================="
echo "Total tests run:    $_test_tests_run"
echo "Tests passed:       $_test_tests_passed"
echo "Tests failed:       $_test_tests_failed"
echo "=================================="

if [[ $_test_tests_failed -eq 0 ]]; then
    echo "✓ All tests passed!"
    exit 0
else
    echo "✗ Some tests failed"
    exit 1
fi
