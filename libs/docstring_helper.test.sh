#!/bin/bash

# Test suite for docstring_helper functions

test_re_sourcing_prevention() {
    section "Test re-sourcing prevention"
    if declare -F bach::get_version_from_doc &>/dev/null && \
       declare -F bach::build_documentation &>/dev/null; then
        local result="exists"
    else
        local result="missing"
    fi
    assert_contains "$result" "exists" "docstring_helper functions exist after first source"

    # Source again and verify functions still exist
    source "${script_dir}/docstring_helper.sh" 2>&1
    if declare -F bach::get_version_from_doc &>/dev/null && \
       declare -F bach::build_documentation &>/dev/null; then
        result="exists"
    else
        result="missing"
    fi
    assert_contains "$result" "exists" "docstring_helper functions exist after re-sourcing"
}

test_get_version_from_doc() {
    section "Test bach::get_version_from_doc"
    local doc="Test Command

Description

Usage:
    test [options]
----
1.2.3"

    local version
    version=$(bach::get_version_from_doc "$doc")
    assert_contains "$version" "1.2.3" "Extract version 1.2.3"

    local doc2="Another
----
2.0.0"
    version=$(bach::get_version_from_doc "$doc2")
    assert_contains "$version" "2.0.0" "Extract version 2.0.0"
}

test_print_version() {
    section "Test bach::print_version"
    local doc="Test
----
1.2.3"
    local output
    output=$(bach::print_version "$doc" 2>&1)
    assert_contains "$output" "1.2.3" "bach::print_version outputs version"
}

test_print_doc() {
    section "Test bach::print_doc"
    local doc="Test Command

Description

Usage:
    test [options]
----
1.0.0"
    local output
    output=$(bach::print_doc "$doc" 2>&1)
    assert_contains "$output" "Test Command" "bach::print_doc outputs doc string"
    assert_contains "$output" "Usage:" "bach::print_doc contains Usage"
}

test_build_documentation_without_subcommands() {
    section "Test bach::build_documentation without subcommands"
    local doc="Test Command

Usage:
    test [options]
----
1.0.0"
    local output
    output=$(bach::build_documentation "$doc" "" "")
    assert_contains "$output" "Test Command" "Documentation contains title"
    assert_contains "$output" "Usage:" "Documentation contains usage"
}

test_build_documentation_with_subcommands() {
    section "Test bach::build_documentation with subcommands"
    mkdir -p /tmp/test_docs
    touch /tmp/test_docs/cmd1.sh
    touch /tmp/test_docs/cmd2.sh
    chmod +x /tmp/test_docs/cmd1.sh /tmp/test_docs/cmd2.sh

    local doc_with_usage="Test
Usage:
    test [command]
----
1.0.0"

    local output
    output=$(bach::build_documentation "$doc_with_usage" "/tmp/test_docs" "")
    assert_contains "$output" "cmd1" "Documentation shows cmd1"
    assert_contains "$output" "cmd2" "Documentation shows cmd2"

    rm -rf /tmp/test_docs
}

test_exclusion_list() {
    section "Test exclusion list"
    mkdir -p /tmp/test_excludes
    touch /tmp/test_excludes/cmd1.sh
    touch /tmp/test_excludes/const.sh
    touch /tmp/test_excludes/statics.sh
    chmod +x /tmp/test_excludes/cmd1.sh /tmp/test_excludes/const.sh /tmp/test_excludes/statics.sh

    local doc_with_usage="Test
Usage:
    test [command]
----
1.0.0"

    local output
    output=$(bach::build_documentation "$doc_with_usage" "/tmp/test_excludes" "const.sh,statics.sh")
    assert_contains "$output" "cmd1" "Shows cmd1"
    assert_not_contains "$output" "const" "Excludes const.sh"
    assert_not_contains "$output" "statics" "Excludes statics.sh"

    rm -rf /tmp/test_excludes
}

test_auto_injection_help_version() {
    section "Test auto-injection of help and version options"
    local doc="Test
Usage:
    test [command]
Options:
    -d|--debug||Debug mode
----
1.0.0"

    local output
    output=$(bach::build_documentation "$doc" "" "")
    assert_contains "$output" "-h, --help" "Auto-injected help option"
    assert_contains "$output" "--version" "Auto-injected version option"
    assert_contains "$output" "debug" "Original option preserved"
}

test_version_extraction_variations() {
    section "Test version extraction variations"
    local doc1="Test
----
  1.2.3  "
    local version
    version=$(bach::get_version_from_doc "$doc1")
    assert_contains "$version" "1.2.3" "Extract version with spaces"

    local doc2="Test
----
	2.0.0	"
    version=$(bach::get_version_from_doc "$doc2")
    assert_contains "$version" "2.0.0" "Extract version with tabs"
}

test_empty_subcommand_directory() {
    section "Test empty subcommand directory"
    mkdir -p /tmp/test_empty
    local doc_with_usage="Test
Usage:
    test [command]
----
1.0.0"
    local output
    output=$(bach::build_documentation "$doc_with_usage" "/tmp/test_empty" "")
    assert_not_contains "$output" "test_empty" "Empty directory shows no subcommands"
    rmdir /tmp/test_empty
}

test_non_executable_files_excluded() {
    section "Test non-executable files excluded"
    mkdir -p /tmp/test_perms
    touch /tmp/test_perms/executable.sh
    touch /tmp/test_perms/nonexec.sh
    chmod +x /tmp/test_perms/executable.sh
    # nonexec.sh is not executable

    local doc_with_usage="Test
Usage:
    test [command]
----
1.0.0"
    local output
    output=$(bach::build_documentation "$doc_with_usage" "/tmp/test_perms" "")
    assert_contains "$output" "executable" "Executable file shown"
    assert_not_contains "$output" "nonexec" "Non-executable file excluded"

    rm -rf /tmp/test_perms
}

test_main_sh_always_excluded() {
    section "Test main.sh always excluded"
    mkdir -p /tmp/test_main
    touch /tmp/test_main/main.sh
    touch /tmp/test_main/other.sh
    chmod +x /tmp/test_main/main.sh /tmp/test_main/other.sh

    local doc_with_usage="Test
Usage:
    test [command]
----
1.0.0"
    local output
    output=$(bach::build_documentation "$doc_with_usage" "/tmp/test_main" "")
    assert_not_contains "$output" "main" "main.sh is excluded"
    assert_contains "$output" "other" "other.sh is shown"

    rm -rf /tmp/test_main
}

main() {
    # Get script directory and source required files
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Export for use in test functions (for compatibility with existing tests)
    TEST_ROOT="${script_dir}/../tools/cli"

    # Source the docstring_helper library and test assertions
    source "${script_dir}/docstring_helper.sh"
    source "${script_dir}/assert.sh"

    # Start tests
    printf '%b\n' "${YELLOW}Running docstring_helper tests...${RESET}"

    # Run all tests
    test_re_sourcing_prevention
    test_get_version_from_doc
    test_print_version
    test_print_doc
    test_build_documentation_without_subcommands
    test_build_documentation_with_subcommands
    test_exclusion_list
    test_auto_injection_help_version
    test_version_extraction_variations
    test_empty_subcommand_directory
    test_non_executable_files_excluded
    test_main_sh_always_excluded

    # Print summary and exit
    print_test_summary
    exit $?
}

# Run main function
main "$@"
