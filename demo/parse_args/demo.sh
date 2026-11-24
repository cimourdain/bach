#!/bin/bash

################################################################################
# Parse Args Library Demo
# Demonstrates command-line argument parsing capabilities
################################################################################

# Source bach.sh to get the bach command which dynamically loads libraries
# For sourcing libraries in your local context, see the README at ../../README.md
source ../../bach.sh

# Configure local library path for this demo
__BACH_CONFIG["libs_local_path_default"]="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.libs/bach"

main() {
    printf '\n%s\n\n' "========================================"
    printf '%s\n' "BACH Parse Args Library Demonstration"
    printf '%s\n\n' "========================================"

    # Section 1: Basic Parsing with Named Arguments
    printf '%s\n' "1. Basic Argument Parsing"
    printf '%s\n' "========================="
    printf '%s\n\n' "Parsing command-line arguments with the parse_args function:"

    local -A parsed_args
    bach parse_args::config::set_parsed_args_global_var_name "parsed_args"

    printf "Parsing: --name John --age 30 --active\n"
    printf "Expected args: name, age, active\n\n"

    # Define argument spec
    local -a arg_spec=(
        "name:string"
        "age:int"
        "active:bool"
    )

    # Parse example arguments
    test_args=(--name "John" --age "30" --active)
    bach::parse_args parsed_args arg_spec "${test_args[@]}"

    if [[ ${#parsed_args[@]} -gt 0 ]]; then
        printf "Parsed arguments:\n"
        for key in "${!parsed_args[@]}"; do
            printf "  %s = %s\n" "$key" "${parsed_args[$key]}"
        done
    fi

    # Section 2: Parsing with Positional and Named Arguments
    printf '\n%s\n' "2. Positional and Named Arguments"
    printf '%s\n' "=================================="
    printf '%s\n\n' "Combining positional arguments with named options:"

    parsed_args=()
    bach parse_args::config::set_parsed_args_global_var_name "parsed_args"

    printf "Parsing: file.txt --output result.txt --verbose\n\n"

    test_args=("file.txt" --output "result.txt" --verbose)
    bach::parse_args parsed_args arg_spec "${test_args[@]}"

    printf "Parsed arguments:\n"
    for key in "${!parsed_args[@]}"; do
        printf "  %s = %s\n" "$key" "${parsed_args[$key]}"
    done

    # Section 3: Short and Long Options
    printf '\n%s\n' "3. Short and Long Options"
    printf '%s\n' "========================="
    printf '%s\n\n' "Using both short (-f) and long (--file) option forms:"

    printf "Example: Command accepts -f or --file for filename\n"
    printf "Example: Command accepts -o or --output for output file\n"
    printf "Example: Command accepts -v or --verbose for verbosity\n\n"

    printf "These options would be processed similarly in your script\n"
    printf "based on the argument specification provided to bach::parse_args\n"

    # Section 4: Default Values
    printf '\n%s\n' "4. Using Default Values"
    printf '%s\n' "======================="
    printf '%s\n\n' "Argument specifications can include default values:"

    printf "Argument spec: 'output:string=default.txt'\n"
    printf "  If --output is not provided, defaults to 'default.txt'\n\n"

    printf "Argument spec: 'threads:int=4'\n"
    printf "  If --threads is not provided, defaults to 4\n"

    # Section 5: Type Validation
    printf '\n%s\n' "5. Type Validation"
    printf '%s\n' "=================="
    printf '%s\n\n' "Parse args supports type validation:"

    printf "Supported types:\n"
    printf "  string    - Text values (default)\n"
    printf "  int       - Integer numbers\n"
    printf "  bool      - Boolean flags (true/false)\n"
    printf "  float     - Floating point numbers\n\n"

    printf "Example specifications:\n"
    printf "  'name:string'        - String argument\n"
    printf "  'count:int'          - Integer argument\n"
    printf "  'enable:bool'        - Boolean flag\n"
    printf "  'threshold:float'    - Float argument\n"

    # Section 6: Practical Use Case - Script with Multiple Options
    printf '\n%s\n' "6. Practical Use Case - Script with Options"
    printf '%s\n' "========================================="
    printf '%s\n\n' "Real-world example: backup script with multiple options:"

    printf "Usage: backup.sh [--source DIR] [--dest DIR] [--compress] [--verbose]\n\n"

    printf "Common patterns:\n"
    printf "  backup.sh --source /home/user --dest /backup --compress\n"
    printf "  backup.sh /home/user /backup                           # positional\n"
    printf "  backup.sh -s /home/user -d /backup -c -v              # short form\n\n"

    printf "With parse_args, your script can handle all these variants\n"
    printf "and normalize them to a consistent argument structure.\n"

    # Section 7: Error Handling
    printf '\n%s\n' "7. Error Handling"
    printf '%s\n' "=================="
    printf '%s\n\n' "Parse args provides error handling:"

    printf "Common parsing errors:\n"
    printf "  - Missing required argument\n"
    printf "  - Invalid type for argument (e.g., 'abc' for int)\n"
    printf "  - Unknown argument name\n\n"

    printf "Return values:\n"
    printf "  0 - Parsing successful\n"
    printf "  1 - Parsing failed (check stderr for details)\n"

    # Summary
    printf '\n%s\n' "========================================"
    printf '%s\n' "Demo Complete!"
    printf '%s\n\n' "========================================"

    printf "For interactive testing, try:\n"
    printf "  your_script --name Alice --age 25 --active\n"
    printf "  your_script --help      # Show help (if implemented)\n"
    printf "  your_script --version   # Show version (if implemented)\n"
}

# Direct execution guard
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
