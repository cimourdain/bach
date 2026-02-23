#!/bin/bash

################################################################################
# BACHCLI Demo Script
################################################################################
# Description:
#   Comprehensive demonstration script showcasing all features of the BACHCLI
#   command processor system, including help/version, command routing, nested
#   commands, option parsing, and error handling.
#
# Usage:
#   ./demo.sh
#
# Examples:
#   # Run complete feature demonstration
#   ./demo.sh
#
# Dependencies:
#   - bash 4.0+
#   - cmd/main.sh and all subcommand scripts
#
# Author: BACHCLI Project
# Version: 1.0.0
################################################################################

# Prevent re-sourcing if already loaded
if declare -F bachcli::demo::main &>/dev/null; then
    return 0
fi

################################################################################
# Run a demo section
# Executes a demo section with formatted header and command execution
# Arguments:
#   $1 - section_number: The section number
#   $2 - section_title: The section title
# Globals:
#   None
# Returns:
#   0 on success
################################################################################
bachcli::demo::__private::run_section() {
    local section_number="${1:-}"
    local section_title="${2:-}"

    local section_number_dots_count=$(grep -o '\.' <<< "${section_number}" | wc -l)
    if [[ "${section_number_dots_count}" -eq 0 ]]; then
        local color_start="$(tput setaf 2)"  # Green
        local color_end="$(tput sgr0)"
        printf '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n' >&2
        printf '%b%s. %s%b\n' "${color_start}" "${section_number}" "${section_title^^}" "${color_end}" >&2
        printf '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n' >&2
    elif [[ "${section_number_dots_count}" -eq 1 ]]; then
        local color_start="$(tput setaf 4)"  # Blue
        local color_end="$(tput sgr0)"
        printf '\n%b%s. %s%b\n' "${color_start}" "${section_number}" "${section_title^^}" "${color_end}" >&2
        printf '%s\n' "$(printf '%*s' ${#section_title} '' | tr ' ' '=')" >&2
    else
        printf '\n%s. %s\n' "${section_number}" "${section_title}" >&2
        printf '%s\n' "$(printf '%*s' ${#section_title} '' | tr ' ' '-')" >&2
    fi
}

################################################################################
# Print a general message
# Displays informational messages in section demonstrations
# Arguments:
#   $1 - message: The message to display
# Returns:
#   0 on success
################################################################################
bachcli::demo::__private::print_message() {
    local message="$1"
    printf '%s\n' "${message}" >&2
}

################################################################################
# Print an example label
# Displays example labels with consistent formatting in magenta color
# Arguments:
#   $1 - example_label: The example label (e.g., "Example 1", "Error 1")
#   $2 - description: Optional description of the example
# Returns:
#   0 on success
################################################################################
bachcli::demo::__private::print_example() {
    local example_label="$1"
    local description="${2:-}"
    local magenta_start="$(tput setaf 5)"  # Magenta
    local color_end="$(tput sgr0)"

    if [[ -n "$description" ]]; then
        printf '%b%s - %s%b\n' "${magenta_start}" "${example_label}" "${description}" "${color_end}" >&2
    else
        printf '%b%s%b\n' "${magenta_start}" "${example_label}" "${color_end}" >&2
    fi
}

################################################################################
# Run a demo command
# Displays and executes a command with formatted output
# Arguments:
#   $1 - command_desc: Description of the command to run
#   $@ - command: The actual command to execute
# Globals:
#   None
# Returns:
#   Command exit status
################################################################################
bachcli::demo::__private::run_command() {
    local command_desc="${1:-}"
    shift

    printf '$ %s\n' "${command_desc}" >&2
    "$@"
    printf '\n' >&2
}

################################################################################
# Section 1.1: No arguments - executes cmd/main.sh directly
# Routing: No path arguments provided, main.sh handles execution
################################################################################
bachcli::demo::__private::section_1_1_no_arguments() {
    bachcli::demo::__private::run_section "1.1" "NO ARGUMENTS - Direct main.sh execution"
    bachcli::demo::__private::print_message "Routing: No path arguments → cmd/main.sh handles execution"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh" \
        bash -c 'cd cmd && ./main.sh'
}

################################################################################
# Section 1.2: Filename as unique argument
# Routing: Resolves cmd1 → finds cmd/cmd1.sh → executes it
################################################################################
bachcli::demo::__private::section_1_2_filename_argument() {
    bachcli::demo::__private::run_section "1.2" "FILENAME AS ARGUMENT"
    bachcli::demo::__private::print_message "Routing: cmd1 → cmd/cmd1.sh found → execute cmd/cmd1.sh"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh cmd1" \
        bash -c 'cd cmd && ./main.sh cmd1'
}

################################################################################
# Section 1.3: Folder with main.sh as unique argument
# Routing: Resolves sone → finds cmd/sone/ directory → has main.sh → executes cmd/sone/main.sh
################################################################################
bachcli::demo::__private::section_1_3_folder_with_main() {
    bachcli::demo::__private::run_section "1.3" "FOLDER WITH main.sh AS ARGUMENT"
    bachcli::demo::__private::print_message "Routing: sone → cmd/sone/ directory → has main.sh → execute cmd/sone/main.sh"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh sone" \
        bash -c 'cd cmd && ./main.sh sone'
}

################################################################################
# Section 1.4: Folder without main.sh as unique argument
# Routing: Resolves stwo → finds cmd/stwo/ directory → no main.sh → error
################################################################################
bachcli::demo::__private::section_1_4_folder_without_main() {
    bachcli::demo::__private::run_section "1.4" "FOLDER WITHOUT main.sh AS ARGUMENT"
    bachcli::demo::__private::print_message "Routing: stwo → cmd/stwo/ directory → no main.sh → error"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh stwo" \
        bash -c 'cd cmd && ./main.sh stwo 2>&1'
}

################################################################################
# Section 1.5: File in subfolder
# Routing: Multiple path arguments traverse directories to find target file
################################################################################
bachcli::demo::__private::section_1_5_file_in_subfolder() {
    bachcli::demo::__private::run_section "1.5" "FILE IN SUBFOLDER"
    bachcli::demo::__private::print_example "Example 1" "Routing: sone bar → cmd/sone/ directory → cmd/sone/bar.sh found → execute it"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh sone bar" \
        bash -c 'cd cmd && ./main.sh sone bar'

    printf '\n' >&2
    bachcli::demo::__private::print_example "Example 2" "Routing: stwo foo → cmd/stwo/ directory → cmd/stwo/foo.sh found → execute it"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh stwo foo" \
        bash -c 'cd cmd && ./main.sh stwo foo'
}

################################################################################
# Section 1.6: Deep nested path
# Routing: Traverses multiple directory levels to reach target
################################################################################
bachcli::demo::__private::section_1_6_deep_nested() {
    bachcli::demo::__private::run_section "1.6" "DEEP NESTED PATH"
    bachcli::demo::__private::print_message "Routing: stwo ssx yaya → cmd/stwo/ → cmd/stwo/ssx/ → cmd/stwo/ssx/yaya.sh → execute it"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh stwo ssx yaya" \
        bash -c 'cd cmd && ./main.sh stwo ssx yaya'
}

################################################################################
# Section 1.7: Resolution errors
# Routing: Arguments that cannot be resolved show appropriate errors
################################################################################
bachcli::demo::__private::section_1_7_resolution_errors() {
    bachcli::demo::__private::run_section "1.7" "RESOLUTION ERRORS"
    bachcli::demo::__private::print_example "Error 1" "No file with argument name"
    bachcli::demo::__private::print_message "Routing: sone buzz → cmd/sone/ directory → no buzz.sh file → error"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh sone buzz" \
        bash -c 'cd cmd && ./main.sh sone buzz 2>&1'
}

################################################################################
# Section 1.8: Exclusion pattern behaviour
# Routing: Files matching exclusion patterns cannot be executed
################################################################################
bachcli::demo::__private::section_1_8_exclusion_patterns() {
    bachcli::demo::__private::run_section "1.8" "EXCLUSION PATTERN BEHAVIOUR"
    bachcli::demo::__private::print_message "Excluded files (const.sh, statics.sh) cannot be executed:"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh sone const (excluded: const.sh)" \
        bash -c 'cd cmd && ./main.sh sone const 2>&1'
    bachcli::demo::__private::run_command "cmd/main.sh sone statics (excluded: statics.sh)" \
        bash -c 'cd cmd && ./main.sh sone statics 2>&1'
}

################################################################################
# Section 2.1: Flag examples with short and long notations
# Demonstrates flag options and their default values
################################################################################
bachcli::demo::__private::section_2_1_flag_examples() {
    bachcli::demo::__private::run_section "2.1" "FLAG OPTIONS - Short and Long notation"
    bachcli::demo::__private::print_example "Example 1" "No flags provided (showing default values)"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh cmd1" \
        bash -c 'cd cmd && ./main.sh cmd1'

    printf '\n' >&2
    bachcli::demo::__private::print_example "Example 2" "Short flag notation (-a -f combined as -af)"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh cmd1 -af" \
        bash -c 'cd cmd && ./main.sh cmd1 -af'

    printf '\n' >&2
    bachcli::demo::__private::print_example "Example 3" "Long flag notation"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh cmd1 --all --force --verbose" \
        bash -c 'cd cmd && ./main.sh cmd1 --all --force --verbose'

    printf '\n' >&2
    bachcli::demo::__private::print_example "Example 4" "Valued option with default"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh cmd1 (check --output-format default)" \
        bash -c 'cd cmd && ./main.sh cmd1 | grep "Output format"'

    printf '\n' >&2
    bachcli::demo::__private::print_example "Example 5" "Valued option with custom value"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh cmd1 --output-format=json" \
        bash -c 'cd cmd && ./main.sh cmd1 --output-format=json | grep "Output format"'
}

################################################################################
# Section 2.2: Multi-level option parsing
# Demonstrates that each script in the routing path parses its own options
################################################################################
bachcli::demo::__private::section_2_2_multilevel_parsing() {
    bachcli::demo::__private::run_section "2.2" "MULTI-LEVEL OPTION PARSING"
    bachcli::demo::__private::print_message "Each script level (main.sh, sone/main.sh, foo.sh) parses its own options:"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh sone foo -ab --my-value=\"test123\" target1" \
        bash -c 'cd cmd && ./main.sh sone foo -ab --my-value="test123" target1'
}

################################################################################
# Section 2.3: Options error handling
# Demonstrates error handling for invalid options
################################################################################
bachcli::demo::__private::section_2_3_option_errors() {
    bachcli::demo::__private::run_section "2.3" "OPTION ERROR HANDLING"
    bachcli::demo::__private::print_message "Invalid option handling example:"
    printf '\n' >&2
    bachcli::demo::__private::run_command "cmd/main.sh cmd1 --invalid-option" \
        bash -c 'cd cmd && ./main.sh cmd1 --invalid-option 2>&1 | head -20'
}

################################################################################
# Section 3: Direct script execution
# Demonstrates executing scripts directly without routing
################################################################################
bachcli::demo::__private::section_3_direct_execution() {
    bachcli::demo::__private::run_section "3" "DIRECT SCRIPT EXECUTION"
    bachcli::demo::__private::print_message "Scripts can be executed directly, bypassing the router:"
    printf '\n' >&2
    bachcli::demo::__private::run_command "./cmd/sone/foo.sh --help | head -15" \
        bash -c './cmd/sone/foo.sh --help | head -15'

    printf '\n' >&2
    bachcli::demo::__private::print_message "Direct execution with options:"
    printf '\n' >&2
    bachcli::demo::__private::run_command "./cmd/sone/bar.sh -qd --config=custom.conf" \
        bash -c './cmd/sone/bar.sh -qd --config=custom.conf'
}

################################################################################
# Main function
# Executes all demonstration sections sequentially or specific sections if args provided
# Arguments:
#   $@ - Section flags (e.g., --section-1-1, --section-2-1)
# Globals:
#   None
# Returns:
#   0 on success
################################################################################
bachcli::demo::main() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    cd "${script_dir}" || return 1

    # Define section mapping (section name -> function name)
    declare -A section_map=(
        ["--section-1-1"]="bachcli::demo::__private::section_1_1_no_arguments"
        ["--section-1-2"]="bachcli::demo::__private::section_1_2_filename_argument"
        ["--section-1-3"]="bachcli::demo::__private::section_1_3_folder_with_main"
        ["--section-1-4"]="bachcli::demo::__private::section_1_4_folder_without_main"
        ["--section-1-5"]="bachcli::demo::__private::section_1_5_file_in_subfolder"
        ["--section-1-6"]="bachcli::demo::__private::section_1_6_deep_nested"
        ["--section-1-7"]="bachcli::demo::__private::section_1_7_resolution_errors"
        ["--section-1-8"]="bachcli::demo::__private::section_1_8_exclusion_patterns"
        ["--section-2-1"]="bachcli::demo::__private::section_2_1_flag_examples"
        ["--section-2-2"]="bachcli::demo::__private::section_2_2_multilevel_parsing"
        ["--section-2-3"]="bachcli::demo::__private::section_2_3_option_errors"
        ["--section-3"]="bachcli::demo::__private::section_3_direct_execution"
    )

    # Determine which sections to run
    local -a sections_to_run=()
    if [[ $# -eq 0 ]]; then
        # No arguments - run all sections
        sections_to_run=(
            "--section-1-1" "--section-1-2" "--section-1-3" "--section-1-4"
            "--section-1-5" "--section-1-6" "--section-1-7" "--section-1-8"
            "--section-2-1" "--section-2-2" "--section-2-3" "--section-3"
        )
    else
        # Run only specified sections
        for arg in "$@"; do
            if [[ -n "${section_map[$arg]:-}" ]]; then
                sections_to_run+=("$arg")
            else
                echo "Unknown section: $arg" >&2
                echo "Available sections: ${!section_map[*]}" >&2
                return 1
            fi
        done
    fi

    printf '==========================================\n' >&2
    printf 'BACHCLI Command Processor - Feature Demo\n' >&2
    printf '==========================================\n' >&2

    # Track major sections for header printing
    local last_major_section=""

    for section_flag in "${sections_to_run[@]}"; do
        # Determine major section (1, 2, or 3)
        local major_section=""
        if [[ "$section_flag" =~ --section-1- ]]; then
            major_section="1"
        elif [[ "$section_flag" =~ --section-2- ]]; then
            major_section="2"
        elif [[ "$section_flag" == "--section-3" ]]; then
            major_section="3"
        fi

        # Print major section header if changed
        if [[ "$major_section" != "$last_major_section" && -n "$major_section" ]]; then
            case "$major_section" in
                "1")
                    bachcli::demo::__private::run_section "1" "SUBCOMMAND EXECUTION & ROUTING"
                    ;;
                "2")
                    bachcli::demo::__private::run_section "2" "OPTIONS DEFINITION & PARSING"
                    ;;
                "3")
                    # Section 3 prints its own header
                    ;;
            esac
            last_major_section="$major_section"
        fi

        # Execute the section function
        "${section_map[$section_flag]}"
    done

    printf '\n==========================================\n' >&2
    printf 'Demo Complete!\n' >&2
    printf '==========================================\n' >&2

    return 0
}

# Direct execution guard clause
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bachcli::demo::main "$@"
fi
