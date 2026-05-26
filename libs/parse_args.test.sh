#!/bin/bash

# Test suite for bach::parse_args

SCRIPT_DIR=""

# Get the value of an option of the parsed arguments
# Arguments:
#   $1: option name
test_get_option() {
    local -n parsed_options_ref="${__BACH_PARSED_ARGS[options]}"
    echo "${parsed_options_ref[$1]}"
}

# Get the number of rest (positional) arguments of the parsed arguments
test_count_rest() {
    local -n parsed_rest_ref="${__BACH_PARSED_ARGS[rest]}"
    echo "${#parsed_rest_ref[@]}"
}

# Get the rest (positional) arguments of the parsed arguments, space separated
test_get_rest() {
    local -n parsed_rest_ref="${__BACH_PARSED_ARGS[rest]}"
    echo "${parsed_rest_ref[*]}"
}

test_re_sourcing_prevention() {
    bach::assert::section "Test re-sourcing prevention"
    local functions=(
        bach::parse_args
        bach::parse_args::from_spec
        bach::parse_args::debug_parsed
        bach::parse_args::config::set_parsed_args_global_var_name
    )
    local func
    for func in "${functions[@]}"; do
        declare -F "$func" &>/dev/null
        bach::assert::contains "$?" "0" "${func} exists after first source"
    done

    # Replace a function, then source again: the guard must prevent the redefinition
    bach::parse_args() { echo "overridden"; }
    source "${SCRIPT_DIR}/parse_args.sh"
    local output
    output=$(bach::parse_args)
    bach::assert::contains "$output" "overridden" "Re-sourcing does not redefine the functions"
    unset -f bach::parse_args
    source "${SCRIPT_DIR}/parse_args.sh"
    declare -F bach::parse_args &>/dev/null
    bach::assert::contains "$?" "0" "Sourcing with a missing function declares the library again"
}

test_parse_args_simple_flags() {
    bach::assert::section "Test simple flags"
    bach::parse_args --verbose --debug
    bach::assert::contains "$(test_get_option verbose)" "true" "Long flag --verbose is true"
    bach::assert::contains "$(test_get_option debug)" "true" "Long flag --debug is true"
    bach::assert::empty "$(test_get_option quiet)" "Flag not given is not set"
    bach::assert::contains "$(test_count_rest)" "0" "No rest arguments"
}

test_parse_args_options_with_values() {
    bach::assert::section "Test options with values"
    bach::parse_args --output=json --config=my.yaml
    bach::assert::contains "$(test_get_option output)" "json" "Option --output=json"
    bach::assert::contains "$(test_get_option config)" "my.yaml" "Option --config=my.yaml"

    bach::parse_args --expr=a=b
    bach::assert::contains "$(test_get_option expr)" "a=b" "Value containing = is kept"

    bach::parse_args --empty=
    bach::assert::empty "$(test_get_option empty)" "Option with an empty value"
}

test_parse_args_short_flags() {
    bach::assert::section "Test short flags"
    bach::parse_args -a
    bach::assert::contains "$(test_get_option a)" "true" "Short flag -a is true"

    bach::parse_args -abc
    bach::assert::contains "$(test_get_option a)" "true" "Merged flags: a"
    bach::assert::contains "$(test_get_option b)" "true" "Merged flags: b"
    bach::assert::contains "$(test_get_option c)" "true" "Merged flags: c"
}

test_parse_args_rest_arguments() {
    bach::assert::section "Test rest arguments"
    bach::parse_args file1.txt file2.txt
    bach::assert::contains "$(test_count_rest)" "2" "Two rest arguments"
    bach::assert::contains "$(test_get_rest)" "file1.txt file2.txt" "Rest arguments keep their order"

    bach::parse_args "file with spaces.txt" other
    bach::assert::contains "$(test_count_rest)" "2" "An argument with spaces stays one argument"
    bach::assert::contains "$(test_get_rest)" "file with spaces.txt other" "Argument with spaces is kept as is"
}

test_parse_args_mixed() {
    bach::assert::section "Test mixed arguments"
    bach::parse_args -v input.txt --output=json output.txt
    bach::assert::contains "$(test_get_option v)" "true" "Flag before rest arguments"
    bach::assert::contains "$(test_get_option output)" "json" "Option between rest arguments"
    bach::assert::contains "$(test_get_rest)" "input.txt output.txt" "Rest arguments around options"
}

test_parse_args_empty() {
    bach::assert::section "Test no arguments"
    bach::parse_args
    bach::assert::contains "$(test_count_rest)" "0" "No rest arguments"
    local -n parsed_options_ref="${__BACH_PARSED_ARGS[options]}"
    bach::assert::contains "${#parsed_options_ref[@]}" "0" "No options"
}

test_parse_args_reset_between_calls() {
    bach::assert::section "Test reset between calls"
    bach::parse_args --first -a one
    bach::parse_args --second two
    bach::assert::empty "$(test_get_option first)" "Previous option is cleared"
    bach::assert::empty "$(test_get_option a)" "Previous flag is cleared"
    bach::assert::contains "$(test_get_option second)" "true" "New option is set"
    bach::assert::contains "$(test_get_rest)" "two" "Previous rest arguments are cleared"
}

test_parsed_args_var_name() {
    bach::assert::section "Test parsed arguments variable name"
    bach::parse_args::config::set_parsed_args_global_var_name "MY_ARGS"
    bach::assert::contains "$?" "0" "Setting a variable name succeeds"

    bach::parse_args --custom file
    local -n my_options_ref="${MY_ARGS[options]}"
    local -n my_rest_ref="${MY_ARGS[rest]}"
    bach::assert::contains "${my_options_ref[custom]}" "true" "Options are stored in the custom variable"
    bach::assert::contains "${my_rest_ref[*]}" "file" "Rest arguments are stored in the custom variable"

    local output
    output=$(bach::parse_args::config::set_parsed_args_global_var_name "" 2>&1)
    bach::assert::contains "$?" "1" "An empty variable name is refused"

    bach::parse_args::config::set_parsed_args_global_var_name "__BACH_PARSED_ARGS"
}

main() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    source "${SCRIPT_DIR}/assert.sh"
    # The parse_args library relies on the `bach` function to load the libraries it depends on
    source "${SCRIPT_DIR}/../bach.sh"
    __BACH_CONFIG["libs_local_path_default"]="${SCRIPT_DIR}"
    source "${SCRIPT_DIR}/parse_args.sh"

    printf '%b\n' "${YELLOW}Running bach::parse_args tests...${RESET}"

    test_re_sourcing_prevention
    test_parse_args_simple_flags
    test_parse_args_options_with_values
    test_parse_args_short_flags
    test_parse_args_rest_arguments
    test_parse_args_mixed
    test_parse_args_empty
    test_parse_args_reset_between_calls
    test_parsed_args_var_name

    bach::assert::print_test_summary
    exit $?
}

main "$@"
