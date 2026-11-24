#!/bin/bash

################################################################################
# Logging
################################################################################
# Description:
#   Level based logging with colored output and timestamps, written on stderr.
#   The execution log level is set with the LOG_LEVEL environment variable.
#
# Usage:
#   source /path/to/log.sh
#   bach log --info "Hello"
#
# Dependencies:
#   - bash 4.0+
#   - tput
#   - term_utils library (colors)
#
# Author: BACHCLI Project
# Version: 1.0.0
################################################################################

# Prevent re-sourcing if function already declared
if declare -F bach::log &>/dev/null; then
    return 0
fi

################################################################################
# Check if an argument is a log level option (private)
# Matches the short (-d) and long (--debug) forms of each log level.
# Arguments:
#   $1 - Name reference to the lowercased argument
#   $2 - Name reference receiving the matching log level key
# Globals:
#   __BACH_LOG_LEVELS - Known log levels
# Returns:
#   1 if the argument is a log level option, 0 otherwise
################################################################################
bach::log::__private::parse_args_check_log_level() {
    local -n arg_lowercase_ref="$1"
    local -n log_level_value_target_ref="$2"

    for log_level_key in ${!__BACH_LOG_LEVELS[@]};do
        key_lowercase="${log_level_key,,}"  # Convert to lowercase
        short_opt="-${key_lowercase:0:1}"
        long_opt="--${key_lowercase}"
        if [[ "${arg_lowercase_ref}" == "$short_opt" || "${arg_lowercase_ref}" == "$long_opt" ]]; then
            log_level_value_target_ref="$log_level_key"
            return 1
        fi
    done
    return 0
}

################################################################################
# Check if an argument is a --<key>=<value> option (private)
# Arguments:
#   $1 - Name reference to the argument
#   $2 - option_key: Expected option key
#   $3 - Name reference receiving the option value
# Returns:
#   1 if the argument matches the key, 0 otherwise
################################################################################
bach::log::__private::parse_args_check_valued_option() {
    local -n arg_lowercase_subref="$1"
    local option_key_str="$2"
    local -n option_value_ref="$3"

    if [[ "$arg_lowercase_subref" =~ ^--([^=]+)=(.*)$ ]]; then
        local key="${BASH_REMATCH[1]}"
        local value="${BASH_REMATCH[2]}"
        if [[ "$key" == "$option_key_str" ]]; then
            option_value_ref="$value"
            return 1
        fi
    fi

    return 0
}

################################################################################
# Check if an argument is the --delimiter=<value> option (private)
# Arguments:
#   $1 - Name reference to the argument
#   $2 - Name reference receiving the delimiter
# Returns:
#   1 if the argument is the delimiter option, 0 otherwise
################################################################################
bach::log::__private::parse_args_check_array_delimiter() {
    local -n arg_lowercase_ref="$1"
    local -n option_value_delimiter_target_ref="$2"

    bach::log::__private::parse_args_check_valued_option arg_lowercase_ref "delimiter" option_value_delimiter_target_ref
    return $?
}

################################################################################
# Check if an argument is the --array-ref=<name> option (private)
# Arguments:
#   $1 - Name reference to the argument
#   $2 - Name reference receiving the array name
# Returns:
#   1 if the argument is the array-ref option, 0 otherwise
################################################################################
bach::log::__private::parse_args_check_array_ref() {
    local -n arg_lowercase_ref="$1"
    local -n option_value_array_target_ref="$2"

    bach::log::__private::parse_args_check_valued_option arg_lowercase_ref "array-ref" option_value_array_target_ref
    return $?
}


################################################################################
# Extract the log options from the log arguments (private)
# Options are parsed until the first non option argument, handled options are removed from the arguments array.
# Arguments:
#   $1 - Name reference to the arguments array (updated)
#   $2 - Name reference receiving the log level key
#   $3 - Name reference receiving the array name
#   $4 - Name reference receiving the delimiter
# Returns:
#   0 always
################################################################################
bach::log::__private::parse_args() {
    local -n args="$1"
    local -n log_level_value_ref="$2"
    local -n array_value_ref="$3"
    local -n delimiter_value_ref="$4"


    local -a args_handled_options_indexes=()
    local arg
    local arg_idx
    for ((arg_idx=0; arg_idx<${#args[@]}; arg_idx++)); do
        arg="${args[arg_idx]}"  # Convert to lowercase
        if [[ "$arg" == -* ]]; then
            arg_lowercase="${arg,,}"  # Convert to lowercase for case-insensitive comparison
            bach::log::__private::parse_args_check_log_level arg_lowercase log_level_value_ref
            if [[ $? -eq 1 ]]; then
                args_handled_options_indexes+=("$arg_idx")
                continue
            fi

            bach::log::__private::parse_args_check_array_ref arg array_value_ref
            if [[ $? -eq 1 ]]; then
                args_handled_options_indexes+=("$arg_idx")
                continue
            fi

            bach::log::__private::parse_args_check_array_delimiter arg delimiter_value_ref
            if [[ $? -eq 1 ]]; then
                args_handled_options_indexes+=("$arg_idx")
                continue
            fi

        else
            break  # Stop parsing options when the first non-option argument is encountered
        fi
    done

    # echo "DEBUG:After argument parsing, remove ${#args_handled_options_indexes[@]} arguments." >&2
    local -a updated_args=()
    for arg_idx in "${!args[@]}"; do
        if [[ ! " ${args_handled_options_indexes[*]} " =~ [[:space:]]${arg_idx}[[:space:]] ]]; then
            updated_args+=("${args[arg_idx]}")
        fi
    done
    args=("${updated_args[@]}")
    # echo "DEBUG:After argument parsing, ${#args[@]} arguments remain." >&2
}


################################################################################
# Declare the log levels, configuration and colors if not already done (private)
# Arguments:
#   None
# Globals:
#   __BACH_LOG_LEVELS - Declared
#   __BACH_LOG_CONFIG - Declared and completed with default values
#   __BACH_LOG_COLORS - Declared
#   __BACH_TERM_COLORS - Declared (from bach::term_utils::declare_colors)
# Returns:
#   0 always
################################################################################
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

    local log_config_key
    for log_config_key in "${!default_log_config[@]}"; do
        current_config_value="${__BACH_LOG_CONFIG["$log_config_key"]}"
        if [[ -z "${current_config_value}" ]]; then
            # echo"bach::log::__private::setup set default for missing config key '$log_config_key'." >&2
            global_config_value="${__BACH_CONFIG["log__$log_config_key"]}"
            if [[ -n "${global_config_value}" ]]; then
                # echo"bach::log::__private::setup use global config value for '$log_config_key': ${global_config_value}." >&2
                __BACH_LOG_CONFIG[$log_config_key]="$global_config_value"
            else
                # echo"bach::log::__private::setup use default value for '$log_config_key': ${default_log_config[$log_config_key]}." >&2
                __BACH_LOG_CONFIG[$log_config_key]="${default_log_config[$log_config_key]}"
            fi
        # else
            # echo"bach::log::__private::setup __BACH_LOG_CONFIG['$log_config_key'] already set with '${current_config_value}', skipping." >&2
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

################################################################################
# Check if a log must be filtered according to the execution log level (private)
# The execution log level is read from the LOG_LEVEL environment variable
# (case-insensitive). When a level is invalid the log is not filtered.
# Arguments:
#   $1 - Name reference to the log level key of the current log
# Globals:
#   LOG_LEVEL - Execution log level
#   __BACH_LOG_CONFIG - Name of the environment variable and default level
#   __BACH_LOG_LEVELS - Known log levels and their priority
# Returns:
#   0 if the log must be printed
#   1 if the execution log level is invalid (log is printed)
#   2 if the current log level is invalid (log is printed)
#   3 if the current log level is lower than the execution log level (filtered)
################################################################################
bach::log::__private::should_filter_log() {
    local -n current_log_level_key_ref="$1"
    local log_level_env_var_name="${__BACH_LOG_CONFIG["execution_log_level_env_var"]}"
    # echo"DEBUG: Get execution log level from environment variable '$log_level_env_var_name'." >&2

    local execution_log_level_name="${!log_level_env_var_name,,}"
    if [[ -z "$execution_log_level_name" ]]; then
        # echo"DEBUG: No execution log level specified in environment variable '$log_level_env_var_name', using default '${__BACH_LOG_CONFIG["default_execution_log_level_key"]}'" >&2
        execution_log_level_name="${__BACH_LOG_CONFIG["default_execution_log_level_key"]}"
    fi

    local execution_log_level_index="${__BACH_LOG_LEVELS["$execution_log_level_name"]}"
    if [[ -z "${execution_log_level_index}" ]]; then
        # Invalid log level in environment variable, consider not filtering and print a warning
        # echo"ERROR: Failed to get level index from execution log level '${execution_log_level_name}': ${execution_log_level_index}" >&2

        # printf -v fmtStr '[%s]=%%q\\n' "${!__BACH_LOG_LEVELS[@]}";printf "$fmtStr" "${__BACH_LOG_LEVELS[@]}"
        return 1
    fi

    # echo "DEBUG: Get log level index from '${current_log_level_key_ref}'" >&2
    local current_log_level_index="${__BACH_LOG_LEVELS["$current_log_level_key_ref"]}"
    if [[ -z "${current_log_level_index}" ]]; then
        # Invalid current log level, consider not filtering and print a warning
        # echo"ERROR: Failed to get level index from current log level '${current_log_level_key_ref}'" >&2
        return 2
    fi

    if [[ $current_log_level_index -lt $execution_log_level_index ]]; then
        # echo "DEBUG: Current log level '${current_log_level_key_ref}' is lower than execution log level '${execution_log_level_name}', do not print log" >&2
        return 3
    fi

    # echo "DEBUG: Current log level '${current_log_level_key_ref}' is superior to execution log level '${execution_log_level_name}', log message will be printed" >&2

    return 0
}


################################################################################
# Build the colored prefix of a log message (private)
# Arguments:
#   $1 - Name reference to the log level key
#   $2 - Name reference receiving the message prefix
#   $3 - Name reference to the trace prefix (file:line function)
# Globals:
#   __BACH_LOG_COLORS - Level colors
# Returns:
#   0 always
################################################################################
bach::log::__private::setup_log_prefix() {
    local -n log_level_key_ref="$1"
    local -n log_message_prefix_ref="$2"
    local -n log_trace_prefix_ref="$3"

    local printf_format_color_start=${__BACH_LOG_COLORS[$log_level_key_ref]}
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local log_label_prefix="${log_level_key_ref^^}" # Uppercase log level as label
    log_message_prefix_ref="${printf_format_color_start}[$timestamp][$log_label_prefix][${log_trace_prefix_ref}]"
}

################################################################################
# Print a log message on stderr (private)
# With a single argument the message is printed as is, otherwise the first argument is used as printf format.
# Arguments:
#   $1 - Name reference to the message prefix
#   $@ - Message, or printf format followed by its values
# Globals:
#   __BACH_TERM_COLORS[reset] - Reset sequence
# Returns:
#   0 always
################################################################################
bach::log::__private::print_log_string() {
    local -n log_message_prefix_ref="$1"
    shift
    local log_remaining_arguments=("$@")

    local printf_format_color_reset="${__BACH_TERM_COLORS["reset"]}"

    if [[ ${#log_remaining_arguments[@]} -eq 1 ]]; then
        # echo "DEBUG:Only one log argument, printing as simple string." >&2
        printf "%s%s%s\n" \
            "${log_message_prefix_ref}" \
            "${log_remaining_arguments[0]}" \
            "${printf_format_color_reset}" >&2
    else
        # echo "DEBUG:${#log_remaining_arguments[@]} log arguments, printing as formatted string." >&2
        printf "%s${log_remaining_arguments[0]}%s\n" \
            "${log_message_prefix_ref}" \
            "${log_remaining_arguments[@]:1}" \
            "${printf_format_color_reset}" >&2
    fi

    return 0
}

################################################################################
# Log a message with level-based filtering and colored output
# The message is printed on stderr when its level is at least the execution log level (LOG_LEVEL).
# Options: -v/--verbose, -t/--trace, -d/--debug, -i/--info (default), -w/--warning, -e/--error, -f/--fatal,
# --array-ref=<name> to print an array, --delimiter=<char> to split the message into items.
# Arguments:
#   $@ - Options followed by the message
# Globals:
#   LOG_LEVEL - Execution log level (default: warning)
#   __BACH_LOG_CONFIG - Log configuration
# Outputs:
#   Log lines on stderr
# Returns:
#   0 on success (including filtered logs), 1 if no message is given or the arguments are invalid
################################################################################
bach::log() {
    bach::log::__private::setup

    local log_args=("$@")
    local current_log_level_key
    current_log_level_key="${__BACH_LOG_CONFIG["default_log_level_name"]}" # Default log level if not specified in arguments

    # Parse log level and message
    local array_ref
    local delimiter

    # echo "DEBUG:Log arguments count before parsing ${#log_args[@]}." >&2
    bach::log::__private::parse_args log_args current_log_level_key array_ref delimiter
    # echo "DEBUG:Log arguments count after parsing ${#log_args[@]}." >&2

    # Check if log should be filtered
    # Only a log below the execution log level (status 3) is filtered
    bach::log::__private::should_filter_log current_log_level_key
    [[ $? -eq 3 ]] && return 0

    local log_message_prefix
    local log_trace_prefix="${BASH_SOURCE[2]}:${BASH_LINENO[1]} ${FUNCNAME[2]}"
    bach::log::__private::setup_log_prefix current_log_level_key log_message_prefix log_trace_prefix

    local remaining_args_count=${#log_args[@]}
    if [[ -n "$array_ref" ]]; then
        # echo "DEBUG:Attempt to print array from ref '${array_ref}'." >&2
        local array_item_prefix="$(IFS=" "; echo "${log_args[*]}")"
        if [[ -z "$array_item_prefix" ]]; then
            array_item_prefix="$array_ref"
        fi

        local -n log_array_source="$array_ref"
        if [[ ${#log_array_source[@]} -eq 0 ]]; then
            bach::log::__private::print_log_string log_message_prefix "[${array_item_prefix}]IS EMPTY"
            return 0
        fi

        for log_array_key in "${!log_array_source[@]}"; do
            bach::log::__private::print_log_string log_message_prefix "[${array_item_prefix}][$log_array_key]: ${log_array_source["${log_array_key}"]}"
        done
        return 0
    fi

    if [[ $remaining_args_count -eq 0 ]]; then
        echo "ERROR: No argument provided, cannot process log." >&2
        return 1
    fi

    if [ -n "${delimiter}" ]; then
        # echo "DEBUG:A delimiter is set, attempting to split log arguments to array." >&2
        if [[ $remaining_args_count -gt 2 ]]; then
            echo "ERROR: Too many arguments provided for log message with delimiter, expected at most 2 (title and message), got ${remaining_args_count}." >&2
            return 1
        fi

        array_item_prefix="[Delimited log]"
        if [[ $remaining_args_count -eq 2 ]]; then
            array_item_prefix="${log_args[0]}"
        fi

        IFS="${delimiter}" read -a message_as_array <<< "${log_args[-1]}"
        if [[ ${#message_as_array[@]} -eq 0 ]]; then
            bach::log::__private::print_log_string log_message_prefix "[${array_item_prefix}]IS EMPTY"
            return 0
        fi

        for log_array_key in "${!message_as_array[@]}"; do
            bach::log::__private::print_log_string log_message_prefix "[$array_item_prefix][$log_array_key]: ${message_as_array[log_array_key]}"
        done
        return 0
    fi

    # echo "DEBUG:No array or delimiter, printing ${remaining_args_count} log arguments as is." >&2
    bach::log::__private::print_log_string log_message_prefix "${log_args[@]}"
}

# Export the functions
export -f bach::log


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bach::log "$@"
fi
