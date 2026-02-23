#!/bin/bash

# Test suite for bach::parse_args_from_docstring function

test_re_sourcing_prevention() {
    section "Test re-sourcing prevention"
    if declare -F bach::parse_args_from_docstring &>/dev/null; then
        local result="exists"
    else
        local result="missing"
    fi
    assert_contains "$result" "exists" "bach::parse_args_from_docstring function exists after first source"

    # Source again and verify function still exists
    source "${TEST_ROOT}/lib/parse_args.sh" 2>&1
    if declare -F bach::parse_args_from_docstring &>/dev/null; then
        result="exists"
    else
        result="missing"
    fi
    assert_contains "$result" "exists" "bach::parse_args_from_docstring function exists after re-sourcing"
}

test_basic_flag_parsing() {
    section "Test basic flag parsing"
    reset_args
    local doc="Test
Usage: test
Options:
    -a,--all,default=\"false\",All items
----
1.0.0"

    bach::parse_args_from_docstring "$doc" -a
    assert_contains "${__ARGS[all]}" "true" "Short flag -a sets all=true"
    assert_contains "${#__PATH_ARGS[@]}" "0" "No path args"

    reset_args
    bach::parse_args_from_docstring "$doc" --all
    assert_contains "${__ARGS[all]}" "true" "Long flag --all sets all=true"
}

test_valued_options() {
    section "Test valued options"
    reset_args
    local doc="Test
Usage: test
Options:
    --output=,default=\"text\",Output format
----
1.0.0"

    bach::parse_args_from_docstring "$doc" --output=json
    assert_contains "${__ARGS[output]}" "json" "Valued option --output=json"
}

test_default_values() {
    section "Test default values"
    reset_args
    local doc="Test
Usage: test
Options:
    -v,--verbose,default=\"false\",Verbose
    --format=,default=\"text\",Format
----
1.0.0"

    bach::parse_args_from_docstring "$doc"
    assert_contains "${__ARGS[verbose]}" "false" "Flag defaults to false"
    assert_contains "${__ARGS[format]}" "text" "Option defaults to text"
}

test_multiple_flags() {
    section "Test multiple flags"
    reset_args
    local doc="Test
Usage: test
Options:
    -a,--all,All
    -f,--force,Force
    -v,--verbose,Verbose
----
1.0.0"

    bach::parse_args_from_docstring "$doc" -a -f
    assert_contains "${__ARGS[all]}" "true" "Flag -a set"
    assert_contains "${__ARGS[force]}" "true" "Flag -f set"
    assert_contains "${__ARGS[verbose]:-false}" "false" "Flag -v not set"
}

test_merged_short_flags() {
    section "Test merged short flags"
    reset_args
    local doc="Test
Usage: test
Options:
    -a,--all,All
    -f,--force,Force
    -v,--verbose,Verbose
----
1.0.0"

    bach::parse_args_from_docstring "$doc" -af > /dev/null 2>&1
    assert_contains "${__ARGS[all]}" "true" "Merged flag a"
    assert_contains "${__ARGS[force]}" "true" "Merged flag f"
    # Check that -v was not set (should be false or empty)
    local v_value="${__ARGS[verbose]:-not_set}"
    if [[ "$v_value" == "false" || "$v_value" == "not_set" ]]; then
        assert_contains "ok" "ok" "Merged flag v not used (avoiding -v conflict with version)"
    else
        assert_contains "$v_value" "not_set" "Merged flag v not used (avoiding -v conflict with version)"
    fi
}

test_path_arguments() {
    section "Test path arguments"
    reset_args
    local doc="Test
Usage: test [files...]
----
1.0.0"

    bach::parse_args_from_docstring "$doc" file1 file2 file3
    assert_contains "${#__PATH_ARGS[@]}" "3" "Three path arguments"
    assert_contains "${__PATH_ARGS[0]}" "file1" "First path arg"
    assert_contains "${__PATH_ARGS[1]}" "file2" "Second path arg"
    assert_contains "${__PATH_ARGS[2]}" "file3" "Third path arg"
}

test_mixed_flags_and_paths() {
    section "Test mixed flags and path arguments"
    reset_args
    local doc="Test
Usage: test [options] [files...]
Options:
    -a,--all,All
    -v,--verbose,Verbose
----
1.0.0"

    bach::parse_args_from_docstring "$doc" -a file1 file2
    assert_contains "${__ARGS[all]}" "true" "Flag before path args"
    assert_contains "${#__PATH_ARGS[@]}" "2" "Two path arguments after flag"
    assert_contains "${__PATH_ARGS[0]}" "file1" "First path arg after flag"
}

test_options_after_path_args() {
    section "Test options after path arguments"
    reset_args
    local doc="Test
Usage: test [files...] [options]
Options:
    -a,--all,All
----
1.0.0"

    bach::parse_args_from_docstring "$doc" file1 -a
    assert_contains "${#__PATH_ARGS[@]}" "2" "Both file1 and -a are path args"
    assert_contains "${__PATH_ARGS[0]}" "file1" "Flag after path arg is treated as path arg"
    # Check that -a was not parsed as a flag
    local a_value="${__ARGS[all]:-not_set}"
    if [[ "$a_value" == "false" || "$a_value" == "not_set" ]]; then
        assert_contains "ok" "ok" "Flag -a not parsed after path arg"
    else
        assert_contains "$a_value" "not_set" "Flag -a not parsed after path arg"
    fi
}

test_auto_injected_help() {
    section "Test auto-injected help flag"
    reset_args
    local doc="Test
Usage: test
----
1.0.0"

    local output
    output=$(bach::parse_args_from_docstring "$doc" --help 2>&1)
    local ret=$?
    assert_contains "$ret" "2" "Help returns code 2"
    assert_contains "$output" "Usage:" "Help output contains Usage"
}

test_auto_injected_version() {
    section "Test auto-injected version flag"
    reset_args
    local doc="Test
Usage: test
----
1.0.0"

    local output
    output=$(bach::parse_args_from_docstring "$doc" --version 2>&1)
    local ret=$?
    assert_contains "$ret" "3" "Version returns code 3"
    assert_contains "$output" "1.0.0" "Version output contains version"
}

test_help_with_subcommands() {
    section "Test help with subcommand discovery"
    reset_args
    mkdir -p /tmp/test_subcommands
    cat > /tmp/test_subcommands/cmd1.sh << 'SCRIPT'
#!/bin/bash
echo "cmd1"
SCRIPT
    cat > /tmp/test_subcommands/cmd2.sh << 'SCRIPT'
#!/bin/bash
echo "cmd2"
SCRIPT
    chmod +x /tmp/test_subcommands/cmd1.sh /tmp/test_subcommands/cmd2.sh

    local doc_with_usage="Test
Usage:
    test [command]
----
1.0.0"

    # Build documentation with subcommands
    local built_doc=$(bach::build_documentation "$doc_with_usage" "/tmp/test_subcommands" "" "test")

    local output
    output=$(bach::parse_args_from_docstring "$built_doc" --help 2>&1)
    assert_contains "$output" "cmd1" "Help shows cmd1 subcommand"
    assert_contains "$output" "cmd2" "Help shows cmd2 subcommand"

    rm -rf /tmp/test_subcommands
}

test_is_help_requested() {
    section "Test bach::is_help_requested helper"
    reset_args
    local doc="Test
Usage: test
----
1.0.0"

    bach::parse_args_from_docstring "$doc" -a
    if bach::is_help_requested; then
        printf '%b\n' "${RED}✗${RESET} bach::is_help_requested should be false"
        failed_tests=$((failed_tests + 1))
    else
        printf '%b\n' "${GREEN}✓${RESET} bach::is_help_requested is false"
        passed_tests=$((passed_tests + 1))
    fi
    total_tests=$((total_tests + 1))
}

test_long_short_equivalence() {
    section "Test long and short form equivalence"
    reset_args
    local doc="Test
Usage: test
Options:
    -d,--debug,Debug mode
----
1.0.0"

    bach::parse_args_from_docstring "$doc" -d > /dev/null 2>&1
    local d_short="${__ARGS[debug]}"

    reset_args
    bach::parse_args_from_docstring "$doc" --debug > /dev/null 2>&1
    local d_long="${__ARGS[debug]}"

    assert_contains "$d_short" "$d_long" "Short and long forms are equivalent"
}

test_unknown_options() {
    section "Test unknown options"
    reset_args
    local doc="Test
Usage: test
Options:
    -a,--all,All
----
1.0.0"

    bach::parse_args_from_docstring "$doc" --unknown
    assert_contains "${#__PATH_ARGS[@]}" "1" "Unknown option becomes path arg"
    assert_contains "${__PATH_ARGS[0]}" "--unknown" "Unknown option value"
}

# Tests for bach::parse_args (without docstring)
test_parse_args_simple_flags() {
    section "Test bach::parse_args - simple flags"
    reset_args

    bach::parse_args -a -b --verbose
    assert_contains "${__ARGS[a]}" "true" "Flag -a is true"
    assert_contains "${__ARGS[b]}" "true" "Flag -b is true"
    assert_contains "${__ARGS[verbose]}" "true" "Flag --verbose is true"
    assert_contains "${#__PATH_ARGS[@]}" "0" "No path args"
}

test_parse_args_options_with_values() {
    section "Test bach::parse_args - options with values"
    reset_args

    bach::parse_args --name=john --age 25 -c red
    assert_contains "${__ARGS[name]}" "john" "Option --name=john"
    assert_contains "${__ARGS[age]}" "25" "Option --age 25"
    assert_contains "${__ARGS[c]}" "red" "Option -c red"
}

test_parse_args_merged_flags() {
    section "Test bach::parse_args - merged flags"
    reset_args

    bach::parse_args -abc
    assert_contains "${__ARGS[a]}" "true" "Merged flag a"
    assert_contains "${__ARGS[b]}" "true" "Merged flag b"
    assert_contains "${__ARGS[c]}" "true" "Merged flag c"
}

test_parse_args_path_arguments() {
    section "Test bach::parse_args - path arguments"
    reset_args

    bach::parse_args file1.txt file2.txt
    assert_contains "${#__PATH_ARGS[@]}" "2" "Two path args"
    assert_contains "${__PATH_ARGS[0]}" "file1.txt" "First path arg"
    assert_contains "${__PATH_ARGS[1]}" "file2.txt" "Second path arg"
}

test_parse_args_mixed() {
    section "Test bach::parse_args - mixed flags and paths"
    reset_args

    bach::parse_args -f --verbose --name=test file1.txt file2.txt
    assert_contains "${__ARGS[f]}" "true" "Flag -f is true"
    assert_contains "${__ARGS[verbose]}" "true" "Flag --verbose is true"
    assert_contains "${__ARGS[name]}" "test" "Option --name=test"
    assert_contains "${#__PATH_ARGS[@]}" "2" "Two path args"
    assert_contains "${__PATH_ARGS[0]}" "file1.txt" "First path arg"
    assert_contains "${__PATH_ARGS[1]}" "file2.txt" "Second path arg"
}

test_parse_args_double_dash() {
    section "Test bach::parse_args - double dash separator"
    reset_args

    bach::parse_args -a -- -b --file
    assert_contains "${__ARGS[a]}" "true" "Flag -a before -- is parsed"
    assert_empty "${__ARGS[b]:-}" "Flag -b after -- is not parsed"
    assert_contains "${#__PATH_ARGS[@]}" "2" "Two path args after --"
    assert_contains "${__PATH_ARGS[0]}" "-b" "First path arg is -b"
    assert_contains "${__PATH_ARGS[1]}" "--file" "Second path arg is --file"
}

test_parse_args_empty() {
    section "Test bach::parse_args - no arguments"
    reset_args

    bach::parse_args
    assert_contains "${#__ARGS[@]}" "0" "No args parsed"
    assert_contains "${#__PATH_ARGS[@]}" "0" "No path args"
}

# Helper to reset global arrays
reset_args() {
    declare -gA __ARGS=()
    declare -ga __PATH_ARGS=()
}

main() {
    # Get script directory and source required files
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Source the libraries (all in ~/bach/libs/)
    source "${script_dir}/docstring_helper.sh"
    source "${script_dir}/parse_args.sh"
    source "${script_dir}/assert.sh"

    # Set TEST_ROOT for compatibility with existing tests
    local project_root="${script_dir}/../tools/cli"
    TEST_ROOT="$project_root"

    # Start tests
    printf '%b\n' "${YELLOW}Running bach::parse_args_from_docstring tests...${RESET}"

    # Run all tests
    test_re_sourcing_prevention
    test_basic_flag_parsing
    test_valued_options
    test_default_values
    test_multiple_flags
    test_merged_short_flags
    test_path_arguments
    test_mixed_flags_and_paths
    test_options_after_path_args
    test_auto_injected_help
    test_auto_injected_version
    test_help_with_subcommands
    test_is_help_requested
    test_long_short_equivalence
    test_unknown_options

    # Tests for bach::parse_args
    test_parse_args_simple_flags
    test_parse_args_options_with_values
    test_parse_args_merged_flags
    test_parse_args_path_arguments
    test_parse_args_mixed
    test_parse_args_double_dash
    test_parse_args_empty

    # Print summary and exit
    print_test_summary
    exit $?
}

# Run main function
main "$@"
