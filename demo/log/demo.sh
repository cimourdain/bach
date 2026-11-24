#!/bin/bash

################################################################################
# Log Library Demo
# Demonstrates the logging capabilities of the bach log library
################################################################################

# Source bach.sh to get the bach command which dynamically loads libraries
# For sourcing libraries in your local context, see the README at ../../README.md
source ../../bach.sh

# Configure local library path for this demo
__BACH_CONFIG["libs_local_path_default"]="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.libs/bach"


main() {
    printf '\n%s\n\n' "========================================"
    printf '%s\n' "BACH Log Library Demonstration"
    printf '%s\n\n' "========================================"

    # Section 1: Basic Logging at Different Levels
    printf '%s\n' "1. Basic Logging at Different Levels"
    printf '%s\n' "======================================="
    printf '%s\n\n' "All messages with default logging (info level and above):"

    bach log --verbose "This is a verbose message (lowest priority)"
    bach log --trace "This is a trace message"
    bach log --debug "This is a debug message"
    bach log --info "This is an info message (default level)"
    bach log --warning "This is a warning message"
    bach log --error "This is an error message"
    bach log --fatal "This is a fatal message (highest priority)"

    # Section 2: Using Shorthand Options
    printf '\n%s\n' "2. Using Shorthand Options"
    printf '%s\n' "============================"
    printf '%s\n\n' "Same log levels using shorthand flags:"

    bach log -v "Verbose with -v shorthand"
    bach log -t "Trace with -t shorthand"
    bach log -d "Debug with -d shorthand"
    bach log -i "Info with -i shorthand"
    bach log -w "Warning with -w shorthand"
    bach log -e "Error with -e shorthand"
    bach log -f "Fatal with -f shorthand"

    # Section 3: Default Info Level
    printf '\n%s\n' "3. Default Info Level (No Level Specified)"
    printf '%s\n' "==========================================="
    printf '%s\n\n' "Messages without explicit level default to info:"

    bach log "Default message without level flag"
    bach log "Another default message"

    # Section 4: Logging with Environment Variables
    printf '\n%s\n' "4. Filtering by LOG_LEVEL Environment Variable"
    printf '%s\n' "================================================"
    printf '%s\n' "Running with LOG_LEVEL=warning (only warning, error, fatal shown):\n"

    export LOG_LEVEL="warning"
    bach log --verbose "Verbose - will NOT show"
    bach log --trace "Trace - will NOT show"
    bach log --debug "Debug - will NOT show"
    bach log --info "Info - will NOT show"
    bach log --warning "Warning - WILL show"
    bach log --error "Error - WILL show"
    bach log --fatal "Fatal - WILL show"

    # Reset to default level
    unset LOG_LEVEL

    # Section 5: Practical Use Case - Processing Loop
    printf '\n%s\n' "5. Practical Use Case - Simulated File Processing"
    printf '%s\n' "==================================================="
    printf '%s\n\n' "Logging during a simulated file processing operation:"

    local files=("file1.txt" "file2.conf" "file3.log")

    for file in "${files[@]}"; do
        bach log --debug "Processing file: $file"

        if [[ "$file" == *".conf" ]]; then
            bach log --info "Configuration file detected: $file"
        fi

        if [[ "$file" == *".log" ]]; then
            bach log --warning "Log file detected, ensure appropriate permissions: $file"
        fi

        bach log --trace "Completed processing: $file"
    done

    # Section 6: Error Handling Scenario
    printf '\n%s\n' "6. Error Handling Scenario"
    printf '%s\n' "==========================="
    printf '%s\n\n' "Simulating error handling with appropriate log levels:"

    simulate_operation() {
        local operation="$1"
        local should_fail="$2"

        bach log --debug "Starting operation: $operation"

        if [[ "$should_fail" == "yes" ]]; then
            bach log --error "Operation failed: $operation"
            return 1
        else
            bach log --info "Operation succeeded: $operation"
            return 0
        fi
    }

    simulate_operation "database_backup" "no"
    simulate_operation "cache_clear" "yes"
    simulate_operation "config_reload" "no"

    # Summary
    printf '\n%s\n' "========================================"
    printf '%s\n' "Demo Complete!"
    printf '%s\n\n' "========================================"
}

# Direct execution guard
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
