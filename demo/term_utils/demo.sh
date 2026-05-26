#!/bin/bash

################################################################################
# Term Utils Library Demo
# Demonstrates terminal color and formatting capabilities
################################################################################

# Source bach.sh to get the bach command which dynamically loads libraries
# For sourcing libraries in your local context, see the README at ../../README.md
source ../../bach.sh

# Configure local library path for this demo
__BACH_CONFIG["libs_local_path_default"]="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.libs/bach"

main() {
    printf '\n%s\n\n' "========================================"
    printf '%s\n' "BACH Term Utils Library Demonstration"
    printf '%s\n\n' "========================================"

    # Section 1: Declaring Colors
    printf '%s\n' "1. Declaring Colors"
    printf '%s\n' "==================="
    printf '%s\n\n' "bach term_utils::declare_colors sets up color variables:"

    printf "Calling: bach term_utils::declare_colors\n"
    printf "This creates variables like RED, GREEN, BLUE, YELLOW, etc.\n\n"

    # Declare colors
    bach term_utils::declare_colors

    # Now we can use the color variables
    printf "Now available colors:\n\n"

    printf "%s%-15s%s - Sample text in RED\n" "$RED" "RED" "$RESET"
    printf "%s%-15s%s - Sample text in GREEN\n" "$GREEN" "GREEN" "$RESET"
    printf "%s%-15s%s - Sample text in YELLOW\n" "$YELLOW" "YELLOW" "$RESET"
    printf "%s%-15s%s - Sample text in BLUE\n" "$BLUE" "BLUE" "$RESET"
    printf "%s%-15s%s - Sample text in MAGENTA\n" "$MAGENTA" "MAGENTA" "$RESET"
    printf "%s%-15s%s - Sample text in CYAN\n" "$CYAN" "CYAN" "$RESET"
    printf "%s%-15s%s - Sample text in WHITE\n" "$WHITE" "WHITE" "$RESET"
    printf "%s%-15s%s - Sample text in BLACK\n" "$BLACK" "BLACK" "$RESET"

    # Section 2: Text Styling
    printf '\n%s\n' "2. Text Styling Options"
    printf '%s\n' "======================="
    printf '%s\n\n' "Additional formatting variables available:"

    printf "%s%sBOLD TEXT%s\n" "$BOLD" "$GREEN" "$RESET"
    printf "%s%sUNDERLINED TEXT%s\n" "$UNDERLINE" "$BLUE" "$RESET"
    printf "%s%sDIM TEXT%s\n" "$DIM" "$CYAN" "$RESET"

    # Section 3: Background Colors
    printf '\n%s\n' "3. Background Colors"
    printf '%s\n' "==================="
    printf '%s\n\n' "Background color support:"

    printf "%s%sBG_RED - White text on red background%s\n" "$BG_RED" "$WHITE" "$RESET"
    printf "%s%sBG_GREEN - Text on green background%s\n" "$BG_GREEN" "$BLACK" "$RESET"
    printf "%s%sBG_BLUE - Yellow text on blue background%s\n" "$BG_BLUE" "$YELLOW" "$RESET"
    printf "%s%sBG_YELLOW - Text on yellow background%s\n" "$BG_YELLOW" "$BLACK" "$RESET"

    # Section 4: Practical Use Case - Status Messages
    printf '\n%s\n' "4. Practical Use Case - Status Messages"
    printf '%s\n' "======================================"
    printf '%s\n\n' "Creating colored status indicators:"

    printf "%s[✓]%s Operation succeeded\n" "$GREEN" "$RESET"
    printf "%s[!]%s Warning detected\n" "$YELLOW" "$RESET"
    printf "%s[✗]%s Operation failed\n" "$RED" "$RESET"
    printf "%s[ℹ]%s Information message\n" "$BLUE" "$RESET"
    printf "%s[→]%s Processing...\n" "$CYAN" "$RESET"

    # Section 5: Application Header Display
    printf '\n%s\n' "5. Application Header Display"
    printf '%s\n' "============================="
    printf '%s\n\n' "Using colors for visual application headers:"

    printf "%s" "$BG_BLUE"
    printf "%s%s" "$WHITE" "$BOLD"
    local header_text="Application Header"
    printf "%*s\n" $((${#header_text} + 4)) "  $header_text  "
    printf "%s" "$RESET"
    printf "\n"

    printf "%s%sVersion:%s 1.0.0\n" "$CYAN" "$BOLD" "$RESET"
    printf "%s%sAuthor:%s Bach Demo\n" "$CYAN" "$BOLD" "$RESET"
    printf "\n"

    # Section 6: Colored Lists
    printf '%s\n' "6. Colored Lists and Tables"
    printf '%s\n' "==========================="
    printf '%s\n\n' "Displaying structured data with colors:"

    printf "%s%-20s %-30s %-10s%s\n" "$BOLD$CYAN" "Feature" "Description" "Status" "$RESET"
    printf "%s%s%s\n" "$DIM" "$(printf '%*s' 60 | tr ' ' '-')" "$RESET"

    printf "%-20s %-30s %s[✓]%s\n" "Authentication" "User login system" "$GREEN" "$RESET"
    printf "%-20s %-30s %s[✓]%s\n" "Database" "Data persistence" "$GREEN" "$RESET"
    printf "%-20s %-30s %s[!]%s\n" "API Rate Limiting" "Request throttling" "$YELLOW" "$RESET"
    printf "%-20s %-30s %s[✗]%s\n" "Email Service" "Notification system" "$RED" "$RESET"

    # Section 7: Error Display
    printf '\n%s\n' "7. Error and Success Messages"
    printf '%s\n' "============================="
    printf '%s\n\n' "Formatting error and success messages:"

    printf "%s%s✗ ERROR%s: Failed to connect to database\n" "$BG_RED" "$WHITE$BOLD" "$RESET"
    printf "%s  Reason: Connection timeout\n" "$DIM"
    printf "%s  Action: Check database server status\n\n" "$DIM"

    printf "%s%s✓ SUCCESS%s: Configuration loaded successfully\n" "$BG_GREEN" "$BLACK$BOLD" "$RESET"
    printf "%s  Loaded 5 configuration files\n" "$DIM"
    printf "%s  Memory usage: 2.3 MB\n\n" "$DIM"

    # Section 8: Color Demo Function
    printf '%s\n' "8. Terminal Color Demo"
    printf '%s\n' "======================"
    printf '%s\n\n' "Running terminal color demo function:"

    printf "Executing: bach term_utils::colors_tput_demo\n\n"
    bach term_utils::colors_tput_demo

    # Summary
    printf '\n%s\n' "========================================"
    printf '%s\n' "Demo Complete!"
    printf '%s\n\n' "========================================"
}

# Direct execution guard
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
