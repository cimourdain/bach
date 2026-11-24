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

# docopt example from http://docopt.org
FROM_SPEC_SAMPLE='Naval Fate.

Usage:
  naval_fate ship new <name>...
  naval_fate ship <name> move <x> <y> [--speed=<kn>]
  naval_fate ship shoot <x> <y>
  naval_fate mine (set|remove) <x> <y> [--moored|--drifting]
  naval_fate -h | --help
  naval_fate --version

Options:
  -h --help     Show this screen.
  --version     Show version.
  --speed=<kn>  Speed in knots [default: 10].
  --moored      Moored (anchored) mine.
  --drifting    Drifting mine.
'

# Get one key of the result of a parsed specification
test_get_key() {
    local -n parsed_options_ref="${__BACH_PARSED_ARGS[options]}"
    echo "${parsed_options_ref[$1]}"
}

# Run from_spec on the sample specification, hiding the error logs
test_from_spec_sample() {
    bach::parse_args::from_spec "$FROM_SPEC_SAMPLE" "$@" 2>/dev/null
}

test_from_spec_commands_and_arguments() {
    bach::assert::section "Test from_spec: commands, arguments and repetition"
    test_from_spec_sample ship new Guardian Voyager
    bach::assert::contains "$?" "0" "Valid arguments are accepted"
    bach::assert::contains "$(test_get_key ship)" "true" "Matched command"
    bach::assert::contains "$(test_get_key new)" "true" "Matched sub command"
    bach::assert::contains "$(test_get_key move)" "false" "Command of another usage pattern"
    bach::assert::contains "$(test_get_key "<name>")" "Guardian Voyager" "Repeated argument"
    bach::assert::contains "$(test_get_key "<name>,#")" "2" "Repeated argument count"
    bach::assert::contains "$(test_get_key "<name>,1")" "Voyager" "Repeated argument item"

    test_from_spec_sample ship Guardian move 10 50 --speed=20
    bach::assert::contains "$?" "0" "Another usage pattern is matched"
    bach::assert::contains "$(test_get_key "<name>")" "Guardian" "Argument"
    bach::assert::contains "$(test_get_key "<x>")" "10" "First argument"
    bach::assert::contains "$(test_get_key "<y>")" "50" "Second argument"
    bach::assert::contains "$(test_get_key speed)" "20" "Option with argument"
    bach::assert::contains "$(test_get_key new)" "false" "Command not matched"
}

test_from_spec_options() {
    bach::assert::section "Test from_spec: options"
    test_from_spec_sample ship Guardian move 1 2
    bach::assert::contains "$(test_get_key speed)" "10" "Default value of an option"
    test_from_spec_sample mine set 1 2 --moored
    bach::assert::contains "$?" "0" "Group with mutually exclusive options"
    bach::assert::contains "$(test_get_key moored)" "true" "Flag provided"
    bach::assert::contains "$(test_get_key drifting)" "false" "Flag not provided"
    bach::assert::contains "$(test_get_key set)" "true" "Command of (set|remove)"
}

test_from_spec_failures() {
    bach::assert::section "Test from_spec: arguments not matching the usage"
    test_from_spec_sample
    bach::assert::contains "$?" "1" "Fails without arguments"
    test_from_spec_sample ship
    bach::assert::contains "$?" "1" "Fails when arguments are missing"
    test_from_spec_sample mine set 1 2 --moored --drifting
    bach::assert::contains "$?" "1" "Fails with mutually exclusive options"
    test_from_spec_sample mine explode 1 2
    bach::assert::contains "$?" "1" "Fails with an unknown command"
    test_from_spec_sample ship shoot 1 2 --unknown
    bach::assert::contains "$?" "1" "Fails with an unknown option"
    test_from_spec_sample ship shoot 1 2 3
    bach::assert::contains "$?" "1" "Fails with too many arguments"
    bach::assert::contains "$(test_get_key ship)" "" "Parsed arguments are empty after a failure"
}

test_from_spec_shortcut_and_stacked_flags() {
    bach::assert::section "Test from_spec: [options], stacked flags, repeatable"
    local doc='Usage: prog [options] [-x] [--] FILE...

Options:
  -a, --all   List everything.
  -b          Short only.
  -c          Short only too.
  --out=<f>   Output [default: x.txt]
  -x          Extra.'
    bach::parse_args::from_spec "$doc" -abc one.txt two.txt 2>/dev/null
    bach::assert::contains "$?" "0" "Valid arguments are accepted"
    bach::assert::contains "$(test_get_key all)" "true" "Stacked flag, long name"
    bach::assert::contains "$(test_get_key b)" "true" "Stacked flag without long syntax"
    bach::assert::contains "$(test_get_key c)" "true" "Stacked flag without long syntax (2)"
    bach::assert::contains "$(test_get_key x)" "false" "Flag not provided"
    bach::assert::contains "$(test_get_key out)" "x.txt" "[options] shortcut: default value"
    bach::assert::contains "$(test_get_key FILE)" "one.txt two.txt" "UPPER-CASE argument"
    bach::parse_args::from_spec "$doc" --out=o.txt file 2>/dev/null
    bach::assert::contains "$(test_get_key out)" "o.txt" "[options] shortcut: value"
}

test_from_spec_file() {
    bach::assert::section "Test from_spec: specification from a file"
    local spec_file
    spec_file="$(mktemp)"
    printf 'usage: prog [-q] <name>\n' > "$spec_file"
    bach::parse_args::from_spec "$spec_file" -q bob
    bach::assert::contains "$?" "0" "Specification file is read"
    bach::assert::contains "$(test_get_key q)" "true" "Flag from file"
    bach::assert::contains "$(test_get_key "<name>")" "bob" "Argument from file"
    bach::assert::contains "$(test_get_rest)" "bob" "Rest holds the positionals"
    rm -f "$spec_file"
}

test_from_spec_invalid_spec() {
    bach::assert::section "Test from_spec: invalid specifications"
    bach::parse_args::from_spec "No usage here" a 2>/dev/null
    bach::assert::contains "$?" "1" "A specification needs a Usage section"
    bach::parse_args::from_spec "Usage: prog [a" a 2>/dev/null
    bach::assert::contains "$?" "1" "Unbalanced bracket"
    bach::parse_args::from_spec "Usage: prog (a" a 2>/dev/null
    bach::assert::contains "$?" "1" "Unbalanced parenthesis"
    bach::parse_args::from_spec "Usage: prog a)" a 2>/dev/null
    bach::assert::contains "$?" "1" "Unexpected closing parenthesis"
    bach::parse_args::from_spec "$(printf 'Usage: prog [options]\n\nOptions:\n  -o FILE  Output\n')" 2>/dev/null
    bach::assert::contains "$?" "1" "An option with an argument needs a long syntax"
}

test_debug_parsed() {
    bach::assert::section "Test debug_parsed"
    bach::parse_args --verbose --output=json file.txt
    local output
    output="$(bach::parse_args::debug_parsed)"
    bach::assert::contains "$output" '"output": "json"' "Default format is json"
    bach::assert::contains "$output" '"rest[0]": "file.txt"' "Json contains the rest arguments"
    output="$(bach::parse_args::debug_parsed --format=markdown)"
    bach::assert::contains "$output" "| verbose | true |" "Markdown table"
    output="$(bach::parse_args::debug_parsed --format=ascii)"
    bach::assert::contains "$output" "| output  | json     |" "Ascii table"
    output="$(bach::parse_args::debug_parsed --format=yaml 2>/dev/null)"
    bach::assert::contains "$?" "1" "Unknown format is refused"
    bach::assert::empty "$output" "Unknown format prints nothing"

    local converter_backup
    converter_backup="$(declare -f bach::bash_utils::assoc_array::to_json)"
    unset -f bach::bash_utils::assoc_array::to_json
    local -A saved_config=([libs_local_path_default]="${__BACH_CONFIG[libs_local_path_default]}")
    __BACH_CONFIG[libs_local_path_default]="/nonexistent"
    output="$(bach::parse_args::debug_parsed 2>/dev/null)"
    bach::assert::contains "$?" "1" "Missing converter function: failure"
    bach::assert::empty "$output" "Missing converter function: empty string"
    __BACH_CONFIG[libs_local_path_default]="${saved_config[libs_local_path_default]}"
    eval "$converter_backup"
}

test_parse_args_double_dash() {
    bach::assert::section "Test -- separator"
    bach::parse_args -a first -- --not-an-option -b "x y"
    bach::assert::contains "$(test_get_option a)" "true" "Option before --"
    bach::assert::empty "$(test_get_option not-an-option)" "Option after -- is not parsed"
    bach::assert::empty "$(test_get_option b)" "Short flag after -- is not parsed"
    bach::assert::contains "$(test_count_rest)" "4" "Arguments after -- are in the rest"
    bach::assert::contains "$(test_get_rest)" "first --not-an-option -b x y" "Rest keeps the order, -- is removed"
    bach::parse_args --
    bach::assert::contains "$(test_count_rest)" "0" "Lonely -- gives an empty rest"
    bach::parse_args -- -- a
    bach::assert::contains "$(test_get_rest)" "-- a" "A second -- is kept in the rest"
}

test_from_spec_double_dash() {
    bach::assert::section "Test from_spec: -- separator"
    local doc='Usage: prog [-x] [--] <file>...'
    bach::parse_args::from_spec "$doc" -x -- -weird.txt b 2>/dev/null
    bach::assert::contains "$?" "0" "Arguments after -- are positionals"
    bach::assert::contains "$(test_get_key "<file>")" "-weird.txt b" "File names starting with -"
    bach::assert::contains "$(test_get_key --)" "true" "[--] is matched"
    bach::parse_args::from_spec "$doc" a 2>/dev/null
    bach::assert::contains "$(test_get_key --)" "false" "[--] not matched without --"
    bach::parse_args::from_spec 'Usage: prog [-x]' -x -- extra_1 extra_2 2>/dev/null
    bach::assert::contains "$?" "0" "Arguments after -- are not matched without [--] in the usage"
    bach::assert::contains "$(test_get_rest)" "extra_1 extra_2" "They are stored in the rest"
    bach::assert::contains "$(test_get_key x)" "true" "Options before -- are matched"
}

test_from_spec_help_and_version() {
    bach::assert::section "Test from_spec: help and version"
    local doc=$'Usage: prog [-x] <name>\n\nOptions:\n  -x  Extra.\n\nVersion: 1.2.3 '
    local output status
    output="$(bach::parse_args::from_spec "$doc" --help 2>&1)"; status=$?
    bach::assert::contains "$status" "0" "--help exits with 0"
    bach::assert::contains "$output" "Usage: prog [-x] <name>" "--help prints the specification"
    output="$(bach::parse_args::from_spec "$doc" -x -h a 2>&1)"; status=$?
    bach::assert::contains "$output" "Options:" "-h prints the specification even with other arguments"
    output="$(bach::parse_args::from_spec "$doc" --version 2>&1)"; status=$?
    bach::assert::contains "$status" "0" "--version exits with 0"
    bach::assert::contains "$output" "1.2.3" "--version prints the version"
    output="$(bach::parse_args::from_spec "$doc" -v 2>&1)"
    bach::assert::contains "$output" "1.2.3" "-v prints the version"
    output="$(bach::parse_args::from_spec 'Usage: prog <name>' --version 2>&1)"; status=$?
    bach::assert::contains "$status" "1" "--version without version in the specification exits with 1"
    bach::assert::contains "$output" "does not state a version" "An error is logged"
}

test_from_spec_choices() {
    bach::assert::section "Test from_spec: allowed values"
    local doc=$'Usage: prog [--color=<c>] <size> <name>\n\nOptions:\n  --color=<c>  Color [choices: red, green] [default: red]\n\nArguments:\n  <size>  Size [choices: S, M, L]\n  NAME    Not in the usage'
    bach::parse_args::from_spec "$doc" --color=green M bob 2>/dev/null
    bach::assert::contains "$?" "0" "Allowed values are accepted"
    bach::assert::contains "$(test_get_key color)" "green" "Allowed option value"
    bach::assert::contains "$(test_get_key "<size>")" "M" "Allowed argument value"
    bach::parse_args::from_spec "$doc" --color=blue M bob 2>/dev/null
    bach::assert::contains "$?" "1" "Option value not allowed"
    bach::parse_args::from_spec "$doc" XL bob 2>/dev/null
    bach::assert::contains "$?" "1" "Argument value not allowed"
    local output
    output="$(bach::parse_args::from_spec "$doc" XL bob 2>&1)"
    bach::assert::contains "$output" "Value 'XL' is not allowed for <size> (allowed: S, M, L)" "The error states the allowed values"
}

test_from_spec_keys() {
    bach::assert::section "Test from_spec: keys of the result"
    local doc=$'Usage: prog [-q] [-z] cmd\n\nOptions:\n  -q, --quiet  Quiet.'
    bach::parse_args::from_spec "$doc" -q -z cmd 2>/dev/null
    bach::assert::contains "$(test_get_key quiet)" "true" "Short syntax stored under the long name, without dashes"
    bach::assert::empty "$(test_get_key q)" "No key for the short syntax of a known option"
    bach::assert::contains "$(test_get_key z)" "true" "Unknown short syntax: short name without dash"
    bach::assert::contains "$(test_get_key cmd)" "true" "Command"
    bach::parse_args::from_spec $'Usage: prog [--name] name' name 2>/dev/null
    bach::assert::contains "$?" "1" "Names giving the same key are refused"
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
    test_debug_parsed
    test_from_spec_commands_and_arguments
    test_from_spec_options
    test_from_spec_failures
    test_from_spec_shortcut_and_stacked_flags
    test_from_spec_file
    test_from_spec_invalid_spec
    test_parse_args_double_dash
    test_from_spec_double_dash
    test_from_spec_help_and_version
    test_from_spec_choices
    test_from_spec_keys

    bach::assert::print_test_summary
    exit $?
}

main "$@"
