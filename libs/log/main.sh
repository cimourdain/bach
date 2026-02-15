#!/bin/bash
#
# Logging utility function to print log messages.
#
# Features:
#   - Supports multiple log levels (VERBOSE, DEBUG, INFO, WARNING, ERROR, FATAL).
#   - Log levels defined by command line arguments (e.g., --verbose, -v, --debug, -d, etc.)
#   - Global log level control via LOG_LEVEL environment variable.
#   - Format:
#       - Prefixes log messages with a timestamp and the log level name.
#       - Colors log messages based on their log level for better visibility.
#   - Prevent multiple definitions by checking if the log function is already defined before defining it.
#
# Usage:
#   #!/bin/bash
#   source <this_script.sh>
#   log --info "This is an info message"
#   # see usage.sh of this folder for more examples
#
# Custom log levels list:
#   - Update the `LOG_LEVELS_ALLOWED_SERIALIZED` variable to set a different list of allowed log levels (e.g., "TRACE VERBOSE DEBUG INFO WARNING ERROR FATAL").
#   - WARNING: Update the following variables accordingly if you change the log levels list:
#       - `default_log_level` variable of the log function to set a different default log level
#       - `default_global_log_level` variable of the log function to set a different default global log level
#       - `log_levels_colors_associative_array` variable of the log function to set different colors for each log level
#
# Custom default log level:
#   Update the `default_log_level` variable of the log function to set a different default log level (e.g., DEBUG, WARNING, etc.).
#   This will be used when no log level is specified in the arguments.
#
# Custom default global log level:
#   Update the `default_global_log_level` variable of the log function to set a different default global log level (e.g., DEBUG, WARNING, etc.).
#   This will be used when the log level environment variable is not set.
#
# Custom log level environment variable name:
#   Update the `global_log_level_env_var_name` variable of the log function to change the name of the environment variable used for controlling the global log level (e.g., GLOBAL_LOG_LEVEL, MY_LOG_LEVEL, etc.).
#
# Custom log levels colors:
#   Update the `log_levels_colors_associative_array` variable of the log function to set different colors for each log level.
#   WARNING: Make sure to use valid color names as value (values existing as keys in the `printf_format_colors_associative_array` variable).
#
# Custom function name:
#   To change the function name from `log` to something else (e.g., `my_log`):
#    1. Change the function declaration from `function log() { ... }` to `function my_log() { ... }`.
#    2. Update the check for existing function definition from `if [[ ! $(type -t log) == function ]]; then` to `if [[ ! $(type -t my_log) == function ]]; then`.
#
# Roadmap/ideas for improvement:
#  - Naming:
#   - Env vars should be named with a prefix to avoid conflicts with the user environment (e.g., __LOG_LEVELS_ALLOWED_SERIALIZED, __PRINTF_FORMAT_COLORS_SERIALIZED, __LOG_LEVEL_COLOR_SERIALIZED, etc.)
#   - Function name should be prefixed to avoid conflicts with user functions (e.g., utils::log)
#  - Custom formatting ?
#  - Report to file
#  - Stacktrace
#  - pretty printing of complex data structures (arrays, associative arrays, etc.)

if [[ ! $(type -t log) == function ]];then
    # TODO: What to do if env vars are already defined but with different values ?
    #  - Force refresh to ensure values are the ones defined in the lib?
    #  - Do not refresh but print a warning?
    if [[ -z "${LOG_LEVELS_ALLOWED_SERIALIZED}" ]]; then
        # echo "Serializing log levels allowed array to LOG_LEVELS_ALLOWED_SERIALIZED for export" >&2
        # WARNING: The order of log levels in LOG_LEVELS_ALLOWED_SERIALIZED defines their severity level (from least severe to most severe).
        LOG_LEVELS_ALLOWED_SERIALIZED="VERBOSE DEBUG INFO SUCCESS WARNING ERROR FATAL"
        export LOG_LEVELS_ALLOWED_SERIALIZED
    fi

    # echo "Declare log function as it is not defined" >&2
    if [[ -z "${PRINTF_FORMAT_COLORS_SERIALIZED}" ]]; then
        # echo "Serializing printf format colors associative array to PRINTF_FORMAT_COLORS_SERIALIZED for export" >&2
        declare -A printf_format_colors_associative_array=(
            [black]="$(tput setaf 0)"
            [red]="$(tput setaf 1)"
            [green]="$(tput setaf 2)"
            [yellow]="$(tput setaf 3)"
            [blue]="$(tput setaf 4)"
            [magenta]="$(tput setaf 5)"
            [cyan]="$(tput setaf 6)"
            [white]="$(tput setaf 7)"
            [lime_yellow]="$(tput setaf 190)"
            [powder_blue]="$(tput setaf 153)"
            # [reset]=$(tput sgr0)
        )
        PRINTF_FORMAT_COLORS_SERIALIZED=$(for key in "${!printf_format_colors_associative_array[@]}"; do echo "$key=${printf_format_colors_associative_array[$key]}"; done)
        export PRINTF_FORMAT_COLORS_SERIALIZED
    fi

    if [[ -z "${LOG_LEVEL_COLOR_SERIALIZED}" ]]; then
        # echo "Serializing log levels colors associative array to LOG_LEVEL_COLOR_SERIALIZED for export" >&2
        # WARNING: Keys of the log_levels_colors_associative_array must match the log levels defined in LOG_LEVELS_ALLOWED_SERIALIZED
        # WARNING: Values of the log_levels_colors_associative_array must match the colors defined in PRINTF_FORMAT_COLORS_SERIALIZED
        declare -A log_levels_colors_associative_array=(
            ["VERBOSE"]="cyan"
            ["DEBUG"]="powder_blue"
            # ["INFO"]="blue"
            ["SUCCESS"]="green"
            ["WARNING"]="lime_yellow"
            ["ERROR"]="red"
            ["FATAL"]="magenta"
        )
        LOG_LEVEL_COLOR_SERIALIZED=$(for key in "${!log_levels_colors_associative_array[@]}"; do echo "$key=${log_levels_colors_associative_array[$key]}"; done)
        export LOG_LEVEL_COLOR_SERIALIZED
    fi

    # Print a log message with optional log level
    #
    # Usage: log [--<LC_LONG> | -<LC_SHORT>] <message>
    #  - LC_LONG: Log level long option is a value from the LOG_LEVELS_ALLOWED_SERIALIZED variable in lowercase
    #  - LC_SHORT: Log level short option is the first letter of a value from the LOG_LEVELS_ALLOWED_SERIALIZED variable in lowercase
    #
    # Examples:
    #   log --verbose "This is a verbose message"
    #   log -v "This is another verbose message"
    #   log --debug "This is a debug message"
    #   log -d "This is another debug message"
    #   log --info "This is an info message"
    #   log -i "This is another info message"
    #   log --warning "This is a warning message"
    #   log -w "This is another warning message"
    #   log --error "This is an error message"
    #   log -e "This is another error message"
    #
    function log() (
        local allowed_log_levels
        IFS=" " read -a allowed_log_levels <<< "${LOG_LEVELS_ALLOWED_SERIALIZED}"

        local default_log_level
        default_log_level="INFO"  # MUST match one of the values of LOG_LEVELS_ALLOWED_SERIALIZED, if empty, the default log level will be the least severe log level (the first one in LOG_LEVELS_ALLOWED_SERIALIZED)

        local default_global_log_level
        default_global_log_level=""  # MUST match one of the values of LOG_LEVELS_ALLOWED_SERIALIZED, if empty all log messages will be printed regardless of their log level

        local global_log_level_env_var_name="LOG_LEVEL"

        local default_log_level_color
        default_log_level_color="$(tput setaf 2)"  # Log color default to green if current log level is not defined in the log_levels_colors_associative_array

        # Construct allowed log levels string to be used as function arg
        local allowed_log_levels_str_comma_separated
        allowed_log_levels_str_comma_separated="$(IFS=','; echo "${allowed_log_levels[*]}")"

        ###################################################
        # 1. Read log level from arguments
        ###################################################
        __private::get_log_level_from_args() {
            local allowed_log_levels_str_comma_separated="${1}"
            local default_log_level="${2}"
            local required_log_level_str="${3}"

            IFS="," read -a allowed_log_levels <<< "${allowed_log_levels_str_comma_separated}"
            for log_level_key in "${allowed_log_levels[@]}"
            do
                log_level_key_short_option="-${log_level_key:0:1}"
                log_level_key_long_option="--${log_level_key}"
                if [[ "${required_log_level_str}" == "${log_level_key_short_option,,}" || "${required_log_level_str}" == "${log_level_key_long_option,,}" ]]; then
                    # echo "Debug: '${required_log_level_str}' MATCH '${log_level_key_short_option,,}' or '${log_level_key_long_option,,}': return ${log_level_key^^}" >&2
                    echo "${log_level_key^^}"
                    return 0
                # else
                #     echo "Debug: '${required_log_level_str}' DOES NOT MATCH '${log_level_key_short_option,,}' or '${log_level_key_long_option,,}'" >&2
                fi
            done
            # echo "Debug: No log level specified in arguments, defaulting to ${default_log_level}" >&2
            echo "${default_log_level}"
            return 0
        }
        local log_level
        log_level="$(__private::get_log_level_from_args "${allowed_log_levels_str_comma_separated}" "${default_log_level}" "${1:-""}")"

        ###################################################
        # 2. Read log message from arguments
        ###################################################
        local log_message
        log_message="${@: -1}"

        ###################################################
        # 3. Compare log level with global log level to decide whether to print the message or not
        ###################################################
        local global_log_level
        declare -n global_log_level_env_var_ref="${global_log_level_env_var_name}"
        global_log_level="${global_log_level_env_var_ref:-$default_global_log_level}"

        __private::current_log_level_is_above_global_log_level() {
            local allowed_log_levels_str_comma_separated="${1}"
            IFS="," read -a allowed_log_levels <<< "${allowed_log_levels_str_comma_separated}"
            local current_log_level_name="${2}"
            local global_log_level_name="${3}"
            if [ -z "${global_log_level_name}" ]; then
                # echo "Debug: Global log level is not set, abort comparison and allow log to be printed" >&2
                return 0
            fi

            local current_log_level_index=-1
            local global_log_level_index=-1
            for i in "${!allowed_log_levels[@]}"; do  # "${!array[@]}" returns all indices
                if [[ "${allowed_log_levels[$i]}" == "${current_log_level_name^^}" ]]; then
                    current_log_level_index=$i
                fi
                if [[ "${allowed_log_levels[$i]}" == "${global_log_level_name^^}" ]]; then
                    global_log_level_index=$i
                fi
            done
            if [[ $current_log_level_index -lt $global_log_level_index ]]; then
                return 1  # Skip logging if the current log level is less severe than the global log level
            fi
            return 0
        }
        __private::current_log_level_is_above_global_log_level "${allowed_log_levels_str_comma_separated}" "${log_level}" "${global_log_level}"
        if [[ $? -ne 0 ]]; then
            return 0  # Skip logging if the current log level is less severe than the global
        fi

        ###################################################
        # 4. Format log message with colors and prefixes
        ###################################################
        # Initial log level with default value
        local printf_format_prefix=()
        local printf_format_suffix=()
        local printf_format_data_prefix=()
        local printf_data_prefix=()
        local printf_format_data_suffix=()
        local printf_data_suffix=()

        # deserialize LOG_LEVEL_COLOR_SERIALIZED into an associative array
        declare -A log_level_color_assoc_array=()
        while IFS="=" read -r key value; do
            log_level_color_assoc_array[$key]="$value"  # Populate with serialized data
        done <<< "$LOG_LEVEL_COLOR_SERIALIZED"   # Read from exported variable

        # deserialize PRINTF_FORMAT_COLORS_SERIALIZED into an associative array
        declare -A printf_format_colors_associative_array=()
        while IFS="=" read -r key value; do
            printf_format_colors_associative_array[$key]="$value"  # Populate with serialized data
        done <<< "$PRINTF_FORMAT_COLORS_SERIALIZED"   # Read from exported variable

        # Format Color
        printf_format_log_level_color_name="${log_level_color_assoc_array[${log_level}]}"
        if [[ -z "${printf_format_log_level_color_name}" ]] || [[ ! " ${!printf_format_colors_associative_array[@]} " =~ [[:space:]]${printf_format_log_level_color_name}[[:space:]] ]]; then
            # echo "Warning: No log level format color found for '${log_level}' in log_level_color_assoc_array [${!log_level_color_assoc_array[@]}] (color name ['${printf_format_log_level_color_name}'] is either empty or was not found in  '${!printf_format_colors_associative_array[@]}'). Defaulting to no color." >&2
            printf_format_prefix+=("${default_log_level_color}")  # Default to reset color if log level color is not defined
        else
            # echo "Debug: Log level '${log_level}' has color name '${printf_format_log_level_color_name}' defined in log_level_color_assoc_array, applying color to log message." >&2
            printf_format_prefix+=("${printf_format_colors_associative_array[${printf_format_log_level_color_name}]}")
        fi
        printf_format_suffix+=("$(tput sgr0)") # Reset color after the log message
        # echo "log_level_color_assoc_array" >&2
        # printf -v fmtStr '[%s]=%%q\\n' "${!log_level_color_assoc_array[@]}";printf "$fmtStr" "${log_level_color_assoc_array[@]}" >&2
        # echo "Log level: ${log_level}, color name: ${printf_format_log_level_color_name}" >&2

        # Add timestamp
        printf_format_data_prefix+=("[%s]")
        printf_data_prefix+=("$(date +%Y-%m-%dT%H:%M:%S%z)")

        # Add Log Level name as a prefix to the log message
        printf_format_data_prefix+=("[%s]")
        printf_data_prefix+=("${log_level}")

        # Print log message with printf and the constructed format string and data array
        printf_format_string="${printf_format_prefix[*]}${printf_format_data_prefix[*]}%s${printf_format_data_suffix[*]}${printf_format_suffix[*]}\n"
        printf_data_array=("${printf_data_prefix[@]}" "${log_message}" "${printf_data_suffix[@]}")
        printf "${printf_format_string}" "${printf_data_array[@]}" >&2
    )

    export -f log
else
    log -d "Log utility already defined, skipping definition"
fi

