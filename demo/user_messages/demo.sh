#!/bin/bash

################################################################################
# User Messages Library Demo
# Demonstrates user-friendly message formatting
################################################################################

# Source bach.sh to get the bach command which dynamically loads libraries
# For sourcing libraries in your local context, see the README at ../../README.md
source ../../bach.sh

# Configure local library path for this demo
__BACH_CONFIG["libs_local_path_default"]="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.libs/bach"

main() {
    printf '\n%s\n\n' "========================================"
    printf '%s\n' "BACH User Messages Library Demonstration"
    printf '%s\n\n' "========================================"

    # Section 1: Basic User Messages
    printf '%s\n' "1. Basic User Messages"
    printf '%s\n' "======================"
    printf '%s\n\n' "bach user_msg provides different message types:"

    bach user_msg "This is an info message (default type)"
    printf "\n"

    # Section 2: Different Message Types
    printf '%s\n' "2. Different Message Types"
    printf '%s\n' "=========================="
    printf '%s\n\n' "Displaying various message categories:\n"

    printf "Info message:\n"
    bach user_msg "Configuration loaded successfully"
    printf "\n"

    printf "Warning message:\n"
    bach user_msg "Cache is close to capacity" "warning"
    printf "\n"

    printf "Error message:\n"
    bach user_msg "Failed to connect to database" "error"
    printf "\n"

    printf "Success message:\n"
    bach user_msg "Operation completed without errors" "success"
    printf "\n"

    printf "Debug message:\n"
    bach user_msg "Variable x = 42" "debug"
    printf "\n"

    # Section 3: Message with Details
    printf '%s\n' "3. Messages with Additional Details"
    printf '%s\n' "===================================="
    printf '%s\n\n' "Messages can include supplementary information:\n"

    printf "Error with details:\n"
    bach user_msg "Failed to save file" "error"
    printf "  └─ Reason: Permission denied\n"
    printf "  └─ Path: /etc/restricted/config.txt\n\n"

    printf "Warning with context:\n"
    bach user_msg "Deprecated function used" "warning"
    printf "  └─ Function: old_process_data\n"
    printf "  └─ Alternative: new_process_data\n"
    printf "  └─ Timeline: Will be removed in v2.0\n\n"

    # Section 4: Practical Use Case - Script Execution
    printf '%s\n' "4. Practical Use Case - Script Execution"
    printf '%s\n' "======================================="
    printf '%s\n\n' "Using messages during application workflow:\n"

    bach user_msg "Starting backup process" "info"
    sleep 0.5

    bach user_msg "Connecting to remote server..." "info"
    sleep 0.5

    bach user_msg "SSH key verification required" "warning"
    sleep 0.5

    bach user_msg "Connected successfully" "success"
    sleep 0.5

    bach user_msg "Transferring files (256 MB remaining)" "info"
    sleep 0.5

    bach user_msg "Backup completed" "success"
    printf "\n"

    # Section 5: Error Handling Messages
    printf '%s\n' "5. Error Handling Messages"
    printf '%s\n' "=========================="
    printf '%s\n\n' "Displaying errors during operations:\n"

    simulate_operation() {
        local operation="$1"
        local should_fail="$2"

        bach user_msg "Executing: $operation" "info"

        if [[ "$should_fail" == "yes" ]]; then
            sleep 0.3
            bach user_msg "Failed: $operation - Invalid input format" "error"
            return 1
        else
            sleep 0.3
            bach user_msg "Completed: $operation" "success"
            return 0
        fi
    }

    simulate_operation "validate_config" "no"
    printf "\n"
    simulate_operation "load_plugins" "yes"
    printf "\n"
    simulate_operation "initialize_database" "no"
    printf "\n"

    # Section 6: Configuration Validation Messages
    printf '%s\n' "6. Configuration Validation Messages"
    printf '%s\n' "===================================="
    printf '%s\n\n' "Reporting configuration status:\n"

    check_config_item() {
        local item="$1"
        local status="$2"
        local details="${3:-}"

        case "$status" in
            ok)
                bach user_msg "$item is configured correctly" "success"
                ;;
            missing)
                bach user_msg "$item is missing" "error"
                ;;
            warning)
                bach user_msg "$item has non-optimal settings" "warning"
                ;;
        esac

        if [[ -n "$details" ]]; then
            printf "  └─ %s\n" "$details"
        fi
    }

    printf "Checking configuration:\n\n"
    check_config_item "Database connection" "ok" "Connected to localhost:5432"
    check_config_item "API credentials" "missing" "REQUIRED: Set API_KEY environment variable"
    check_config_item "Cache settings" "warning" "Cache timeout: 5 minutes (recommended: 10 minutes)"
    check_config_item "SSL certificate" "ok" "Valid until 2025-12-31"
    printf "\n"

    # Section 7: Installation/Setup Messages
    printf '%s\n' "7. Installation/Setup Messages"
    printf '%s\n' "=============================="
    printf '%s\n\n' "Guiding users through setup process:\n"

    bach user_msg "Starting installation" "info"
    printf "\n"

    bash::user_msg "Checking prerequisites..." "debug" 2>/dev/null || printf "  Checking prerequisites...\n"
    bach user_msg "Python 3.8 found" "success"
    bach user_msg "Node.js found" "success"
    bach user_msg "Docker NOT found" "warning"
    printf "\n"

    bach user_msg "Installation configuration" "info"
    printf "  ✓ Install location: /opt/myapp\n"
    printf "  ✓ Configuration: ~/.myapp.conf\n"
    printf "  ✓ Logs: /var/log/myapp\n"
    printf "\n"

    bach user_msg "Installation complete" "success"
    printf "  └─ Run 'myapp --help' to get started\n"
    printf "  └─ Documentation: https://example.com/docs\n\n"

    # Section 8: Batch Operations Messages
    printf '%s\n' "8. Batch Operations Messages"
    printf '%s\n' "============================="
    printf '%s\n\n' "Reporting progress on multiple items:\n"

    local -a files=("config.yaml" "database.sql" "assets.zip")
    local processed=0

    for file in "${files[@]}"; do
        bach user_msg "Processing: $file" "info"
        sleep 0.2
        ((processed++))
    done

    bach user_msg "Processed $processed/${#files[@]} files" "success"
    printf "\n"

    # Summary
    printf '%s\n' "========================================"
    printf '%s\n' "Demo Complete!"
    printf '%s\n\n' "========================================"

    printf "%s%s" "$BOLD" "$GREEN"
    printf "Message types available:\n"
    printf "%s%s" "$RESET" "$DIM"
    printf "  • info (default)  - Informational messages\n"
    printf "  • warning         - Cautions and alerts\n"
    printf "  • error           - Problems that need attention\n"
    printf "  • success         - Confirmation of completion\n"
    printf "  • debug           - Development/debugging info\n"
    printf "%s\n" "$RESET"
}

# Direct execution guard
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
