#!/bin/bash

if [ -z "${__BACH_CONFIG}" ]; then
    # echo "BACH Setup: declare __BACH_CONFIG." >&2
    declare -gA __BACH_CONFIG=(
        [log_level]="verbose" # Default log level for program execution, can be overridden by setting the BACH_LOG_LEVEL environment variable or by passing a log level as the first argument when invoking a bach function
        [log_msg_prefix]="[BACH]"
        [libs_functions_prefix]="bach::" # Prefix for all functions defined in libraries, e.g. "bach::log"
        [libs_local_path_default]="./lib/bach/"
        [repo_remote_url]="git@github.com:cimourdain/bach.git"
        [libs_repo_path_default]="libs/"
        [libs_repo_base_url_default]="https://raw.githubusercontent.com/cimourdain/bach/refs/"
        [libs_repo_url_version_default]="heads/main/"
    )
    export __BACH_CONFIG
fi

if [ -z "${__BACH_LIBS_LOCAL_CUSTOM_PATH}" ]; then
    # echo "BACH Setup: declare __BACH_LIBS_LOCAL_CUSTOM_PATH." >&2
    declare -gA __BACH_LIBS_LOCAL_CUSTOM_PATH=(
        # [foo]="./custom/path/foo.sh"
    )
fi

if [ -z "${__BACH_LIBS_REPO_CUSTOM_PATH}" ]; then
    # echo "BACH Setup: declare __BACH_LIBS_REPO_CUSTOM_PATH." >&2
    declare -gA __BACH_LIBS_REPO_CUSTOM_PATH=(
        # [foo]="custom/repo/path/foo.sh"
    )
fi

bach::setup() {
    echo "BACH Framework - Setup: Initializing configuration." >&2
    echo "BACH Framework - Setup: TODO Init environment variables if not set" >&2
    # __BACH_CONFIG
    # __BACH_LIBS_LOCAL_CUSTOM_PATH
    # __BACH_LIBS_REPO_CUSTOM_PATH
}

bach::__private::log() {
    # Log level priorities (lower number = lower priority)
    local -A log_levels_indexes=(
        [verbose]=0
        [trace]=1
        [debug]=2
        [info]=3
        [warning]=4
        [error]=5
        [fatal]=6
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

    log_levels_keys=("${!log_levels_indexes[@]}")
    local default_prgm_log_level_key="verbose"
    local default_invocation_log_level_key="debug"

    # Get the program execution log level from the configuration and determine its index
    local prgm_log_level_key="${__BACH_CONFIG[log_level]:-$default_prgm_log_level_key}"
    local prgm_log_level_index="${log_levels_indexes[$prgm_log_level_key]}"

    # Init the current log level with the default invocation log level
    local current_log_level_name
    current_log_level_name="$default_invocation_log_level_key"


    # Inspect the first argument to see if it is a log level (with or without "--" prefix)
    # In case of a match, set the current log level to the one specified in the argument and shift it from the arguments list
    local first_argument
    first_argument="${1}"
    local first_argument_without_dash_prefix
    first_argument_without_dash_prefix="${first_argument#--}"
    if [[ " ${log_levels_keys[*]} " =~ [[:space:]]${first_argument_without_dash_prefix}[[:space:]] ]]; then
        current_log_level_name="$first_argument_without_dash_prefix"
        shift
    fi
    local current_log_level_index
    current_log_level_index="${log_levels_indexes[$current_log_level_name]}"

    local log_message
    log_message="${1}"

    if [[ "$current_log_level_index" -lt "$prgm_log_level_index" ]]; then
        return 1
    fi

    local color_format="${log_colors[$current_log_level_name]}"
    printf "${color_format}%s[%s]%s${color_reset}\n" "${__BACH_CONFIG[log_msg_prefix]}" "${current_log_level_name^^}" "$log_message" >&2
    return 0
}

# Returns:
#   0 = URL is valid and returns content (HTTP 2xx after redirects)
#   1 = missing URL argument
#   2 = URL format is invalid (basic check)
#   3 = request failed (DNS/TLS/network/HTTP 4xx/5xx)
bach::__private::is_valid_file_url() {
  local url="$1"

  if [[ -z "$url" ]]; then
    bach::__private::log --error "URL argument is missing"
    return 1
  fi

  # Basic URL shape check (optional but useful)
  if [[ ! "$url" =~ ^https?:// ]]; then
    bach::__private::log --error "URL format is invalid: $url"
    return 2
  fi

  # Quick validity check: follow redirects, fail on HTTP errors, no output file
  if curl -fLsS -o /dev/null "$url"; then
    bach::__private::log --verbose "URL is valid: $url"
    return 0
  else
    bach::__private::log --error "Failed to fetch URL: $url"
    return 3
  fi
}

bach::__private::download_lib() {
    local libfile_url="$1"
    local target_filepath="${2}"

    if bach::__private::is_valid_file_url "$libfile_url"; then
        bach::__private::log --debug "Downloading library from $libfile_url to $target_filepath"
        mkdir -p "$(dirname "$target_filepath")"
        curl -L "$libfile_url" -o "$target_filepath"
    else
        bach::__private::log --error "Failed to fetch library from $libfile_url to $target_filepath"
        return 1
    fi
    return 0
}

bach::__private::get_lib_path_in_current_repo() {
    local lib_name="$1"
    local lib_path_in_repo

    if [[ -n "${__BACH_LIBS_REPO_CUSTOM_PATH[$lib_name]}" ]]; then
        bach::__private::log --verbose "When building download URL: Using custom repository path for library ${lib_name}: ${__BACH_LIBS_REPO_CUSTOM_PATH[$lib_name]}"
        lib_path_in_repo="${__BACH_LIBS_REPO_CUSTOM_PATH[$lib_name]}"
    else
       bach::__private::log --verbose "When building download URL: Using default repository path for library ${lib_name}: ${__BACH_CONFIG[libs_repo_path_default]}"
       local bach_libs_repo_path_default="${__BACH_CONFIG[libs_repo_path_default]}"
       lib_path_in_repo="${bach_libs_repo_path_default}${lib_name}.sh"
    fi
    echo "$lib_path_in_repo"
}


bach::__private::build_lib_download_url() {
    local bach_libs_base_url_default="${__BACH_CONFIG[libs_repo_base_url_default]}"
    local bach_libs_url_version_default="${__BACH_CONFIG[libs_repo_url_version_default]}"

    local lib_name="$1"
    local lib_version="${2:-$bach_libs_url_version_default}"


    local lib_path_in_repo
    lib_path_in_repo="$(bach::__private::get_lib_path_in_current_repo "$lib_name")"

    local lib_download_url="${bach_libs_base_url_default}${lib_version}${lib_path_in_repo}"
    bach::__private::log --verbose "Lib download URL: $lib_download_url"
    echo "$lib_download_url"
}


bach::remove_trailing_slashes() {
    local path="$1"
    printf '%s' "$path" | sed 's:/*$::'
}

bach::__private::source_lib() {
    local bach_lib_name="$1"

    # Identify the local path to the library file based on the library name and the configuration, then source it if it exists, otherwise attempt to download it from the repository and source it.
    # echo "Source lib ${bach_lib_name}: identify the local path where to expect the library." >&2
    local bach_local_lib_dir_path
    local bach_libs_local_path_default
    if [[ -n "${__BACH_LIBS_LOCAL_CUSTOM_PATH[$bach_lib_name]}" ]]; then
        # If a custom local path for the library is defined in the configuration, use it
        # echo "Source lib ${bach_lib_name}: Use custom local path defined in configuration: ${__BACH_LIBS_LOCAL_CUSTOM_PATH[$bach_lib_name]}." >&2
        bach_local_lib_dir_path="${__BACH_LIBS_LOCAL_CUSTOM_PATH[$bach_lib_name]}"
    else
        # Use the default local path based on the current script directory and the configuration
        bach_libs_local_path_default="${__BACH_CONFIG[libs_local_path_default]}"
        bach_libs_local_path_default="$(bach::remove_trailing_slashes "$bach_libs_local_path_default")"  # Remove trailing slashes
        # echo "Source lib ${bach_lib_name}: build expected path with default relative path ${bach_libs_local_path_default}." >&2
        bach_local_lib_dir_path="${bach_libs_local_path_default}/${bach_lib_name}.sh"
    fi

    # echo "Source lib ${bach_lib_name}: expected in ${bach_local_lib_dir_path}." >&2
    if test -f "${bach_local_lib_dir_path}"; then
        # echo "Source lib ${bach_lib_name}: Source library ${bach_lib_name} from local path ${bach_local_lib_dir_path}" >&2
        source "${bach_local_lib_dir_path}"
    else
        # echo "Source lib ${bach_lib_name}: Library ${bach_lib_name} not found in local path ${bach_local_lib_dir_path}, attempt to download it from the repository and source it." >&2

        local current_repo_remote_url="$(git remote get-url origin)"
        if [[ "$current_repo_remote_url" == "${__BACH_CONFIG[repo_remote_url]}" ]]; then
            #echo "Source lib ${bach_lib_name}: Copy from local repository to ${bach_local_lib_dir_path}." >&2
            mkdir -p "$(dirname "${bach_local_lib_dir_path}")"
            local repo_base_path="$(git rev-parse --show-toplevel)"
            local lib_path_in_repo
            lib_path_in_repo="$(bach::__private::get_lib_path_in_current_repo "$bach_lib_name")"
            local lib_full_path_in_repo="${repo_base_path}/${lib_path_in_repo}"

            # Create or update the symlink for the local library path
            if [[ ! -e "${bach_local_lib_dir_path}" && ! -L "${bach_local_lib_dir_path}" ]]; then
                # echo "Source lib ${bach_lib_name}: Create a symlink from ${lib_full_path_in_repo} to ${bach_local_lib_dir_path}." >&2
                ln -s "${lib_full_path_in_repo}" "${bach_local_lib_dir_path}"
            elif [[ "$(readlink -f -- "${bach_local_lib_dir_path}")" != "${lib_full_path_in_repo}" ]]; then
                # echo "Source lib ${bach_lib_name}: Replace stale ${bach_local_lib_dir_path} with a symlink to ${lib_full_path_in_repo}." >&2
                rm -f "${bach_local_lib_dir_path}"
                ln -s "${lib_full_path_in_repo}" "${bach_local_lib_dir_path}"
            fi
            # echo "Source lib ${bach_lib_name}: Using local library path ${bach_local_lib_dir_path}." >&2
            source "${bach_local_lib_dir_path}"
        else
            lib_download_url="$(bach::__private::build_lib_download_url "${bach_lib_name}")"
            # echo "Source lib ${bach_lib_name}: Download from url ${lib_download_url}" >&2

            if bach::__private::download_lib "${lib_download_url}" "${bach_local_lib_dir_path}"; then
                # echo "Source lib ${bach_lib_name}: Source library ${bach_lib_name} downloaded from ${lib_download_url} to ${bach_local_lib_dir_path}" >&2
                source "${bach_local_lib_dir_path}"
            else
                echo "ERROR: Source lib ${bach_lib_name}: Failed to download library ${bach_lib_name} from ${lib_download_url} to ${bach_local_lib_dir_path}" >&2
                exit 1
            fi
        fi
    fi
}



bach() {
    local current_script_path
    current_script_path="$(readlink -f -- "${BASH_SOURCE[0]}")"
    # echo "enter main bach function from $current_script_path upon call by ${BASH_SOURCE[1]}" >&2

    local current_script_dir
    current_script_dir="$(dirname -- "${current_script_path}")"
    current_script_dir="$(bach::remove_trailing_slashes "$current_script_dir")"  # Remove trailing slashes

    local bach_lib_prefix
    bach_lib_prefix="${__BACH_CONFIG[libs_functions_prefix]}"

    local requested_funcname="$1"
    # Add the prefix to the requested function name to get the full function name to call
    local bach_func_name="${bach_lib_prefix}${requested_funcname}"

    shift
    if [ ! "$(type -t "${bach_func_name}")" = "function" ]; then
        # echo "Source fn ${bach_func_name}: identify its library" >&2
        # Extract the library name from the requested function name, assuming the format is "bach::<lib-name>::<function-name>"
        split_funcname="${requested_funcname//::/$'\n'}"
        readarray -t funcname_array <<< "$split_funcname"
        local bach_lib_name
        bach_lib_name="${funcname_array[0]}"

        bach::__private::source_lib "${bach_lib_name}"

        if ! test "$(type -t "${bach_func_name}")" = "function"; then
            echo "ERROR: Source fn ${bach_func_name}: Function ${bach_func_name} still not declared after sourcing library ${bach_lib_name}" >&2
            exit 1
        fi
        # echo "Source fn ${bach_func_name}: Successfully loaded function ${bach_func_name} from library ${bach_lib_name}" >&2
    # else
    #     echo "Source fn ${bach_func_name}: Function is already declared: ${bach_func_name} nothing to do." >&2
    fi

    # echo "Source fn ${bach_func_name}: Executing function ${bach_func_name} with arguments: $*" >&2
    "${bach_func_name}" "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bach "$@"
fi