#!/bin/bash

# Prevent re-sourcing if function already declared
if declare -F bach::log &>/dev/null; then
    return 0
fi

bach::log::__private::setup() {
    if [[ -z "${__BACH_LOG_LEVELS}" ]]; then
        # echo"bach::log::__private::setup declare __BACH_LOG_LEVELS." >&2
        declare -gA __BACH_LOG_LEVELS=(
            [verbose]=0
            [trace]=1
            [debug]=2
            [info]=3
            [warning]=4
            [error]=5
            [fatal]=6
        )
        # printf -v fmtStr '[%s]=%%q\\n' "${!__BACH_LOG_LEVELS[@]}";printf "$fmtStr" "${__BACH_LOG_LEVELS[@]}"
    fi

    local -A default_log_config=(
        [execution_log_level_env_var]="LOG_LEVEL"
        [default_execution_log_level_key]="warning" # Default execution log level if environment variable is not set
        [default_log_level_name]="info" # Log level to use if no level is specified in the log function call
    )

    if [[ -z "${__BACH_LOG_CONFIG}" ]]; then
        # echo"bach::log::__private::setup declare __BACH_LOG_CONFIG." >&2
        declare -gA __BACH_LOG_CONFIG=()
    fi

    for key in "${!default_log_config[@]}"; do
        current_config_value="${__BACH_LOG_CONFIG["$key"]}"
        if [[ -z "${current_config_value}" ]]; then
            # echo"bach::log::__private::setup set default for missing config key '$key'." >&2
            global_config_value="${__BACH_CONFIG["log__$key"]}"
            if [[ -n "${global_config_value}" ]]; then
                # echo"bach::log::__private::setup use global config value for '$key': ${global_config_value}." >&2
                __BACH_LOG_CONFIG[$key]="$global_config_value"
            else
                # echo"bach::log::__private::setup use default value for '$key': ${default_log_config[$key]}." >&2
                __BACH_LOG_CONFIG[$key]="${default_log_config[$key]}"
            fi
        # else
            # echo"bach::log::__private::setup __BACH_LOG_CONFIG['$key'] already set with '${current_config_value}', skipping." >&2
        fi
    done
    # printf -v fmtStr '[%s]=%%q\\n' "${!__BACH_LOG_CONFIG[@]}";printf "$fmtStr" "${__BACH_LOG_CONFIG[@]}"


    if [[ -z "${__BACH_LOG_COLORS}" ]]; then
        # echo"bach::log::__private::setup declare __BACH_LOG_COLORS." >&2
        bach term_utils::declare_colors

        declare -gA __BACH_LOG_COLORS=(
            [verbose]="${__BACH_TERM_COLORS[white]}"
            [trace]="${__BACH_TERM_COLORS[cyan]}"
            [debug]="${__BACH_TERM_COLORS[blue]}"
            [info]="${__BACH_TERM_COLORS[green]}"
            [warning]="${__BACH_TERM_COLORS[yellow]}"
            [error]="${__BACH_TERM_COLORS[red]}"
            [fatal]="${__BACH_TERM_COLORS[bright_red]}${__BACH_TERM_COLORS[bold]}"
        )
    fi
    # printf -v fmtStr '[%s]=%%q\\n' "${!__BACH_LOG_COLORS[@]}";printf "$fmtStr" "${__BACH_LOG_COLORS[@]}"
}

# Parse log level from command line options (private)
# Arguments:
#   $@: Command line arguments
# Returns:
#   echoes: "<level> <message>"
bach::__private::parse_log_level() {
    local -n args="$1"
    local -n current_level="$2"
    current_level="${__BACH_LOG_CONFIG[default_log_level_name]}"

    local short_opt
    local long_opt
    local arg_lowercase
    local key_lowercase
    for ((i=0; i<${#args[@]}; i++)); do
        arg_lowercase="${args[i],,}"  # Convert to lowercase
        # echo"DEBUG: Parsing log level from argument '$arg_lowercase' to identify log level key." >&2
        if [[ "$arg_lowercase" == -* ]]; then
            for log_level_key in ${!__BACH_LOG_LEVELS[@]};do
                key_lowercase="${log_level_key,,}"  # Convert to lowercase
                short_opt="-${key_lowercase:0:1}"
                long_opt="--${key_lowercase}"
                # echo"DEBUG: Checking if argument '$arg_lowercase' matches log level options '$short_opt' or '$long_opt'." >&2
                if [[ "${arg_lowercase}" == "$short_opt" || "${arg_lowercase}" == "$long_opt" ]]; then
                    # echo"DEBUG: Argument '$arg_lowercase' matched log level options '$short_opt' or '$long_opt', set log level to '$log_level_key'." >&2
                    current_level="$log_level_key"

                    # Remove the log level option from arguments
                    local -a updated_args=()
                    for j in "${!args[@]}"; do
                        if [[ $j -ne $i ]]; then
                            updated_args+=("${args[j]}")
                        fi
                    done
                    args=("${updated_args[@]}")
                    break
                fi
            done
        fi
    done
}

# Check if log should be filtered based on level (private)
# Arguments:
#   $1: Failed to get the execution context log level
#   $2: Failed to get the current log level
#   $3: Current log level is lower than execution log level, do not print log
# Returns:
#   0 if should NOT filter (print), 1 if should filter (suppress)
bach::__private::should_filter_log() {
    local -n current_log_level_key_ref="$1"
    local log_level_env_var_name="${__BACH_LOG_CONFIG["execution_log_level_env_var"]}"
    # echo"DEBUG: Get execution log level from environment variable '$log_level_env_var_name'." >&2

    local execution_log_level_name="${!log_level_env_var_name}"
    if [[ -z "$execution_log_level_name" ]]; then
        # echo"DEBUG: No execution log level specified in environment variable '$log_level_env_var_name', using default '${__BACH_LOG_CONFIG["default_execution_log_level_key"]}'" >&2
        execution_log_level_name="${__BACH_LOG_CONFIG["default_execution_log_level_key"]}"
    fi

    local execution_log_level_index="${__BACH_LOG_LEVELS["$execution_log_level_name"]}"
    if [[ -z "${execution_log_level_index}" ]]; then
        # Invalid log level in environment variable, consider not filtering and print a warning
        # echo"ERROR: Failed to get level index from execution log level '${execution_log_level_name}': ${execution_log_level_index}" >&2

        printf -v fmtStr '[%s]=%%q\\n' "${!__BACH_LOG_LEVELS[@]}";printf "$fmtStr" "${__BACH_LOG_LEVELS[@]}"
        return 1
    fi

    local current_log_level_index="${__BACH_LOG_LEVELS["$current_log_level_key_ref"]}"
    if [[ -z "${current_log_level_index}" ]]; then
        # Invalid current log level, consider not filtering and print a warning
        # echo"ERROR: Failed to get level index from current log level '${current_log_level_key_ref}'" >&2
        return 2
    fi

    if [[ $current_log_level_index -lt $execution_log_level_index ]]; then
        # echo"DEBUG: Current log level '${current_log_level_key_ref}' is lower than execution log level '${execution_log_level_name}', do not print log" >&2
        return 3
    fi

    # echo"DEBUG: Current log level '${current_log_level_key_ref}' is superior to execution log level '${execution_log_level_name}', do not print log" >&2

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
    local -n args="$1"
    local -n log_level_key="$2"

    local printf_format_color_start=${__BACH_LOG_COLORS[$log_level_key]}
    local printf_format_color_reset="${__BACH_TERM_COLORS["reset"]}"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local log_label_prefix="${log_level_key^^}" # Uppercase log level as label

    # echo"DEBUG: ${#args[@]} args for log message: ${args[*]}" >&2

    if [[ ${#args[@]} -eq 1 ]]; then
        # echo"DEBUG: Print log with 1 argument" >&2
        printf "%s[%s][%s]%s%s\n" \
            "${printf_format_color_start}" \
            "${timestamp}" \
            "${log_label_prefix}" \
            "${args[0]}" \
            "${printf_format_color_reset}" >&2
        return 0
    else
        printf "%s[%s][%s]${args[0]}%s\n" \
            "${printf_format_color_start}" \
            "${timestamp}" \
            "${log_label_prefix}" \
            "${args[@]:1}" \
            "${printf_format_color_reset}" >&2
        return 0
    fi

    # echo"ERROR: No log message provided" >&2
    return 1
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
    bach::log::__private::setup

    local log_args=("$@")
    local current_log_level_key

    # Parse log level and message
    bach::__private::parse_log_level log_args current_log_level_key

    # Check if log should be filtered
    bach::__private::should_filter_log current_log_level_key || return 0

    # Format and print
    bach::__private::format_and_print_log log_args current_log_level_key
}

# Export the functions
export -f bach::log


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bach::log "$@"
fi