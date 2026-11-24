#!/bin/bash

################################################################################
# Bash Utilities
################################################################################
# Description:
#   String and array helpers: substring position lookup, string sanitizing,
#   unique hashes, in-place array sorting and associative array formatting
#   (json, markdown, ascii table).
#
# Usage:
#   source /path/to/bash_utils.sh
#   bach bash_utils::string::only_alpha "a1b2"
#
# Dependencies:
#   - bash 4.0+
#   - sha256sum, awk, sort
#   - bach function (bach.sh) for logging and library loading
#
# Author: BACHCLI Project
# Version: 1.0.0
################################################################################


# Prevent re-sourcing if functions already declared
if declare -F bach::bash_utils::string::first_index_of_substring &>/dev/null && \
   declare -F bach::bash_utils::string::index_of_any_substring &>/dev/null && \
   declare -F bach::bash_utils::string::unique_hash &>/dev/null && \
   declare -F bach::bash_utils::string::only_alpha &>/dev/null && \
   declare -F bach::bash_utils::string::only_alphanumeric &>/dev/null && \
   declare -F bach::bash_utils::string::trim_leading_whitespaces &>/dev/null && \
   declare -F bach::bash_utils::array::sort &>/dev/null && \
   declare -F bach::bash_utils::assoc_array::to_json &>/dev/null && \
   declare -F bach::bash_utils::assoc_array::to_markdown &>/dev/null && \
   declare -F bach::bash_utils::assoc_array::to_ascii &>/dev/null; then
    return 0
fi

################################################################################
# Get the index of the first occurrence of a substring
# Index is 0-based, -1 is printed when the substring is not found.
# Arguments:
#   $1 - main_string: String to search in
#   $2 - substring: Substring to find
# Outputs:
#   The index of the first occurrence, or -1
# Returns:
#   0 if the substring is found, 1 otherwise
################################################################################
bach::bash_utils::string::first_index_of_substring() {
    local main_string
    main_string="$1"
    local substring
    substring="$2"

    if [[ "$main_string" == *"$substring"* ]]; then
        bach log --verbose "In string: '${main_string}', get index position of substring: '${substring}'"
        local main_string_prefix
        main_string_prefix=${main_string%%${substring}*}

        local char_position_idx
        char_position_idx=${#main_string_prefix}
        echo "$char_position_idx"
        return 0
    fi

    echo "-1"
    return 1
}
export -f bach::bash_utils::string::first_index_of_substring

################################################################################
# Get the index following the n-th match of any of several substrings
# Matches of all substrings are sorted by position, the occurrence index selects one of them.
# Arguments:
#   $1 - main_string: String to search in
#   $2 - substrings_array_name: Name of the array holding the substrings
#   $3 - occurrence_idx: Rank of the match to use (default: 0)
# Outputs:
#   The index of the end of the selected match, or -1
# Returns:
#   0 if the match exists, 1 otherwise
################################################################################
bach::bash_utils::string::index_of_any_substring() {
    # TODO: Handle negative value for substring_occurrence_idx, to count occurrences from the end of the string
    local main_string
    main_string="$1"
    local substrings_array_name="$2"
    local -n substrings_array_ref="$substrings_array_name"
    local substring_occurrence_idx
    substring_occurrence_idx=${3:-0}

    local -A indexes_by_substring
    indexes_by_substring=()

    local offset
    local rest
    local substring
    local indexes_by_substring_key
    local -a all_substrings_indexes
    all_substrings_indexes=()
    local -a substrings_indexes
    local found_substring_in_rest
    local found_substring_idx_in_rest
    local found_substring_idx
    for substring in "${substrings_array_ref[@]}"; do
        offset=0
        rest="$main_string"
        substrings_indexes=()
        while [[ "$rest" == *"$substring"* ]]; do
            found_substring_in_rest=${rest%%${substring}*}
            found_substring_idx_in_rest=${#found_substring_in_rest}
            found_substring_idx=$((offset + found_substring_idx_in_rest))
            substrings_indexes+=("$found_substring_idx")
            all_substrings_indexes+=("$found_substring_idx")

            offset=$((found_substring_idx + ${#substring}))
            rest="${main_string:offset}"
        done

        indexes_by_substring_key=$(bach bash_utils::string::only_alpha "${substring}")
        if [[ "${#indexes_by_substring_key}" -eq 0 || "${#indexes_by_substring_key}" -ne "${#substring}" ]]; then
            local substring_unique_hash
            substring_unique_hash=$(bach bash_utils::string::unique_hash "$substring")
            indexes_by_substring_key="${substring_unique_hash}__${#substring}"
        fi
        indexes_by_substring["$indexes_by_substring_key"]="${substrings_indexes[*]}"
    done

    bach log --verbose --array-ref=indexes_by_substring "Sub of '${main_string}'"

    if [[ ${#all_substrings_indexes[@]} -gt ${substring_occurrence_idx} ]]; then
        bach::bash_utils::array::sort all_substrings_indexes
        bach log --verbose --array-ref=all_substrings_indexes "Substring indexes"
        local required_substring_index_value
        required_substring_index_value="${all_substrings_indexes[${substring_occurrence_idx}]}"
        local substring_key
        for substring_key in ${!indexes_by_substring[@]}
        do
            if [[ " ${indexes_by_substring[${substring_key}]} " == *" ${required_substring_index_value} "* ]]; then
                bach log --verbose "In string: '${main_string}', found substring key: '${substring_key}' at required occurrence index: ${substring_occurrence_idx}, which corresponds to index: ${required_substring_index_value}"
                local substring_length
                if [[ "$substring_key" == *"__"* ]]; then
                    substring_length=${substring_key##*__}
                else
                    substring_length=${#substring_key}
                fi

                local substring_index_response
                substring_index_response=$((required_substring_index_value + substring_length))
                bach log --verbose "In string: '${main_string}', found substring: '${substring_key}', which ends at index: ${substring_index_response}"
                echo "$substring_index_response"
                return 0
            fi
        done
    fi

    bach log --debug "In string: '${main_string}', failed to get substring occurrence at index: ${substring_occurrence_idx}."
    echo "-1"
    return 1
}
export -f bach::bash_utils::string::index_of_any_substring

################################################################################
# Compute the sha256 hash of a string
# Arguments:
#   $1 - main_string: String to hash
# Outputs:
#   The hexadecimal sha256 digest
# Returns:
#   0 always
################################################################################
bach::bash_utils::string::unique_hash() {
    local main_string
    main_string="$1"

    local hash
    hash=$(printf '%s' "$main_string" | sha256sum | awk '{print $1}')
    echo "$hash"
    return 0
}
export -f bach::bash_utils::string::unique_hash

################################################################################
# Remove every character that is not a letter (A-Z, a-z)
# Arguments:
#   $1 - main_string: String to filter
# Outputs:
#   The filtered string
# Returns:
#   0 always
################################################################################
bach::bash_utils::string::only_alpha() {
    local main_string
    main_string="$1"

    local alpha_only
    # alpha_only="${main_string//[^[:alpha:]]/}"
    alpha_only="${main_string//[^A-Za-z]/}"
    echo "$alpha_only"
    return 0
}
export -f bach::bash_utils::string::only_alpha

################################################################################
# Remove every character that is not a letter or a digit (A-Z, a-z, 0-9)
# Arguments:
#   $1 - main_string: String to filter
# Outputs:
#   The filtered string
# Returns:
#   0 always
################################################################################
bach::bash_utils::string::only_alphanumeric() {
    local main_string
    main_string="$1"

    local alphanumeric_only
    # alphanumeric_only="${main_string//[^[:alnum:]]/}"
    alphanumeric_only="${main_string//[^A-Za-z0-9]/}"
    echo "$alphanumeric_only"
    return 0
}
export -f bach::bash_utils::string::only_alphanumeric

################################################################################
# Remove the whitespaces at the beginning of a string
# Trailing whitespaces are kept.
# Arguments:
#   $1 - main_string: String to trim
# Outputs:
#   The trimmed string
# Returns:
#   0 always
################################################################################
bach::bash_utils::string::trim_leading_whitespaces() {
    local main_string
    main_string="$1"

    local trimmed_string
    trimmed_string="${main_string#"${main_string%%[![:space:]]*}"}"
    echo "$trimmed_string"
    return 0
}
export -f bach::bash_utils::string::trim_leading_whitespaces


################################################################################
# Sort an array numerically, in place
# Arguments:
#   $1 - array_name: Name of the array to sort
# Globals:
#   <array_name> - The array is modified in place
# Returns:
#   0 on success
################################################################################
bach::bash_utils::array::sort() {
    local -n array_to_sort
    array_to_sort="$1"

    mapfile -t array_to_sort < <(printf '%s\n' "${array_to_sort[@]}" | sort -n)
}
export -f bach::bash_utils::array::sort


################################################################################
# Get the keys of an associative array sorted alphabetically (private)
# Arguments:
#   $1 - assoc_name: Name of the associative array
#   $2 - keys_name: Name of the indexed array receiving the sorted keys
################################################################################
bach::bash_utils::__private::assoc_array::sorted_keys() {
    local -n assoc_source_ref="$1"
    local -n sorted_keys_ref="$2"
    sorted_keys_ref=()
    (( ${#assoc_source_ref[@]} == 0 )) || mapfile -d '' -t sorted_keys_ref < <(printf '%s\0' "${!assoc_source_ref[@]}" | LC_ALL=C sort -z)
}

################################################################################
# Escape a string to be a json string content (private)
# Arguments:
#   $1 - value: String to escape
#   $2 - result_name: Name of the variable receiving the escaped string
################################################################################
bach::bash_utils::__private::json_escape() {
    local -n json_escaped_ref="$2"
    local escaped="$1"
    escaped="${escaped//\\/\\\\}"
    escaped="${escaped//\"/\\\"}"
    escaped="${escaped//$'\n'/\\n}"
    escaped="${escaped//$'\r'/\\r}"
    json_escaped_ref="${escaped//$'\t'/\\t}"
}

################################################################################
# Convert an associative array to a pretty formatted json object
# Keys are sorted alphabetically, values are json strings.
# Arguments:
#   $1 - assoc_name: Name of the associative array
# Outputs:
#   The json string on stdout
# Returns:
#   0 on success
################################################################################
bach::bash_utils::assoc_array::to_json() {
    local -n assoc_ref="$1"
    local -a keys
    bach::bash_utils::__private::assoc_array::sorted_keys "$1" keys
    if (( ${#keys[@]} == 0 )); then
        printf '{}\n'
        return 0
    fi

    local idx key escaped_key escaped_value separator=","
    printf '{\n'
    for idx in "${!keys[@]}"; do
        key="${keys[idx]}"
        bach::bash_utils::__private::json_escape "$key" escaped_key
        bach::bash_utils::__private::json_escape "${assoc_ref["$key"]}" escaped_value
        (( idx < ${#keys[@]} - 1 )) || separator=""
        printf '  "%s": "%s"%s\n' "$escaped_key" "$escaped_value" "$separator"
    done
    printf '}\n'
}
export -f bach::bash_utils::assoc_array::to_json

################################################################################
# Convert an associative array to a markdown table (columns Key and Value)
# Keys are sorted alphabetically, "|" is escaped and new lines become <br>.
# Arguments:
#   $1 - assoc_name: Name of the associative array
# Outputs:
#   The markdown table on stdout
# Returns:
#   0 on success
################################################################################
bach::bash_utils::assoc_array::to_markdown() {
    local -n assoc_ref="$1"
    local -a keys
    bach::bash_utils::__private::assoc_array::sorted_keys "$1" keys

    local key escaped_key escaped_value
    printf '| Key | Value |\n| --- | --- |\n'
    for key in "${keys[@]}"; do
        escaped_key="${key//|/\\|}"
        escaped_key="${escaped_key//$'\n'/<br>}"
        escaped_value="${assoc_ref["$key"]//|/\\|}"
        escaped_value="${escaped_value//$'\n'/<br>}"
        printf '| %s | %s |\n' "$escaped_key" "$escaped_value"
    done
}
export -f bach::bash_utils::assoc_array::to_markdown

################################################################################
# Convert an associative array to an ascii table (columns Key and Value)
# Keys are sorted alphabetically, new lines are displayed as \n.
# Arguments:
#   $1 - assoc_name: Name of the associative array
# Outputs:
#   The ascii table on stdout
# Returns:
#   0 on success
################################################################################
bach::bash_utils::assoc_array::to_ascii() {
    local -n assoc_ref="$1"
    local -a keys cells_key=("Key") cells_value=("Value")
    local key cell
    local -i key_width=3 value_width=5 idx
    bach::bash_utils::__private::assoc_array::sorted_keys "$1" keys
    for key in "${keys[@]}"; do
        cell="${key//$'\n'/\\n}"; cells_key+=("$cell"); (( ${#cell} <= key_width )) || key_width=${#cell}
        cell="${assoc_ref["$key"]//$'\n'/\\n}"; cells_value+=("$cell"); (( ${#cell} <= value_width )) || value_width=${#cell}
    done

    local border key_dashes value_dashes
    printf -v key_dashes '%*s' "$((key_width + 2))" ""
    printf -v value_dashes '%*s' "$((value_width + 2))" ""
    border="+${key_dashes// /-}+${value_dashes// /-}+"
    for idx in "${!cells_key[@]}"; do
        (( idx > 1 )) || printf '%s\n' "$border"
        printf '| %-*s | %-*s |\n' "$key_width" "${cells_key[idx]}" "$value_width" "${cells_value[idx]}"
    done
    printf '%s\n' "$border"
}
export -f bach::bash_utils::assoc_array::to_ascii
