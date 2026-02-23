#!/bin/bash

# Prevent re-sourcing if function already declared
if declare -F bach::log &>/dev/null; then
    return 0
fi

# Parse log level from command line options (private)
# Arguments:
#   $@: Command line arguments
# Returns:
#   echoes: "<level> <message>"
bach::__private::parse_log_level() {
    local default_level="info"
    local current_level="$default_level"
    local message=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose) current_level="verbose"; shift ;;
            -t|--trace) current_level="trace"; shift ;;
            -d|--debug) current_level="debug"; shift ;;
            -i|--info) current_level="info"; shift ;;
            -w|--warning) current_level="warning"; shift ;;
            -e|--error) current_level="error"; shift ;;
            -f|--fatal) current_level="fatal"; shift ;;
            *)
                message="$1"
                shift
                break
                ;;
        esac
    done

    echo "${current_level} ${message}"
}

# Check if log should be filtered based on level (private)
# Arguments:
#   $1: Current log level
#   $2: Name reference to log_levels array
# Returns:
#   0 if should NOT filter (print), 1 if should filter (suppress)
bach::__private::should_filter_log() {
    local current_level="$1"
    local -n ll="$2"
    local log_level_env_var="LOG_LEVEL"

    local min_level_name="${!log_level_env_var}"
    [[ -z "$min_level_name" ]] && return 0

    # Convert to lowercase
    min_level_name="${min_level_name,,}"

    # Check if minimum level is valid
    if [[ -n "${ll[$min_level_name]}" ]]; then
        local min_level_value="${ll[$min_level_name]}"
        local current_level_value="${ll[$current_level]}"

        # If current level is lower than minimum, filter it
        [[ $current_level_value -lt $min_level_value ]] && return 1
    fi

    return 0
}

# Format and print log message (private)
# Arguments:
#   $1: Log level
#   $2: Message
#   $3: Name reference to log_colors array
#   $4: Name reference to log_labels array
#   $5: Color reset code
bach::__private::format_and_print_log() {
    local level="$1"
    local message="$2"
    local -n lc="$3"
    local -n lbl="$4"
    local color_reset="$5"

    local color="${lc[$level]}"
    local label="${lbl[$level]}"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    printf "%s[%s]%s %s%-7s%s %s\n" \
        "${color}" \
        "${timestamp}" \
        "${color_reset}" \
        "${color}" \
        "${label}" \
        "${color_reset}" \
        "${message}" >&2
}

# Log function with level-based filtering and colored output
# Usage: bach::log [options] "<message>"
# Options:
#   -v, --verbose   Verbose level log
#   -t, --trace     Trace level log
#   -d, --debug     Debug level log
#   -i, --info      Info level log (default)
#   -w, --warning   Warning level log
#   -e, --error     Error level log
#   -f, --fatal     Fatal level log
bach::log() {
    # Log level priorities (lower number = lower priority)
    local -A log_levels=(
        [verbose]=0 [trace]=1 [debug]=2 [info]=3
        [warning]=4 [error]=5 [fatal]=6
    )

    # Color definitions
    local -A log_colors=(
        [verbose]="$(tput setaf 8)"
        [trace]="$(tput setaf 6)"
        [debug]="$(tput setaf 4)"
        [info]="$(tput setaf 2)"
        [warning]="$(tput setaf 3)"
        [error]="$(tput setaf 1)"
        [fatal]="$(tput setaf 1)$(tput bold)"
    )

    local color_reset="$(tput sgr0)"

    # Log level labels
    local -A log_labels=(
        [verbose]="VERBOSE" [trace]="TRACE" [debug]="DEBUG"
        [info]="INFO" [warning]="WARNING" [error]="ERROR" [fatal]="FATAL"
    )

    # Parse log level and message
    local parsed=$(bach::__private::parse_log_level "$@")
    local current_level="${parsed%% *}"
    local message="${parsed#* }"

    # Check if log should be filtered
    bach::__private::should_filter_log "$current_level" log_levels || return 0

    # Format and print
    bach::__private::format_and_print_log "$current_level" "$message" \
        log_colors log_labels "$color_reset"
}

# Export the functions
export -f bach::__private::parse_log_level
export -f bach::__private::should_filter_log
export -f bach::__private::format_and_print_log
export -f bach::log
