#!/usr/bin/env bash

# User message library for displaying formatted messages with emojis and headers
# Outputs to stderr using printf
#
# Public API:
#   bach::user_msg -- Display formatted messages with optional emojis and headers
#
# All other functions prefixed with bach::__private:: are internal.

# Prevent re-sourcing if function already declared
if declare -F bach::user_msg &>/dev/null; then
    return 0
fi

# Internal: Get terminal width, fallback to 80
# Arguments:
#   None
# Returns:
#   Echoes the terminal width in columns
bach::__private::get_terminal_width() {
    local width
    width=$(tput cols 2>/dev/null) || width=80
    echo "$width"
}

# Internal: Format h1 header - boxed with # characters
# Arguments:
#   $1: Message to display (will be converted to uppercase)
# Returns:
#   Prints formatted header to stderr
bach::__private::format_h1() {
    local -r message="$1"
    local -r message_upper="${message^^}"
    local -r bold="$(tput bold)"
    local -r cyan="$(tput setaf 6)"
    local -r reset="$(tput sgr0)"
    local width

    width=$(bach::__private::get_terminal_width)

    printf "%s%s%s\n" "$cyan$bold" "$(printf '#%.0s' $(seq 1 $width))" "$reset" >&2
    printf "%s#%s\n" "$cyan" "$reset" >&2
    printf "%s%s%s%s%s\n" "$cyan$bold" "#  " "$message_upper" "$reset" >&2
    printf "%s#%s\n" "$cyan" "$reset" >&2
    printf "%s%s%s\n" "$cyan$bold" "$(printf '#%.0s' $(seq 1 $width))" "$reset" >&2
}

# Internal: Format h2 header - text with underline
# Arguments:
#   $1: Message to display
# Returns:
#   Prints formatted header to stderr
bach::__private::format_h2() {
    local -r message="$1"
    local -r bold="$(tput bold)"
    local -r magenta="$(tput setaf 5)"
    local -r reset="$(tput sgr0)"
    local length

    length=${#message}

    printf "%s%s%s\n" "$magenta$bold" "$message" "$reset" >&2
    printf "%s%s%s\n" "$magenta" "$(printf '#%.0s' $(seq 1 $((length + 2))))" "$reset" >&2
}

# Internal: Format h3 header - simple text with underline
# Arguments:
#   $1: Message to display
# Returns:
#   Prints formatted header to stderr
bach::__private::format_h3() {
    local -r message="$1"
    local -r bold="$(tput bold)"
    local -r yellow="$(tput setaf 3)"
    local -r reset="$(tput sgr0)"
    local length

    length=${#message}

    printf "%s%s%s\n" "$yellow$bold" "$message" "$reset" >&2
    printf "%s%s%s\n" "$yellow" "$(printf '#%.0s' $(seq 1 $length))" "$reset" >&2
}

# Internal: Format h4 header - dimmed text with underline
# Arguments:
#   $1: Message to display
# Returns:
#   Prints formatted header to stderr
bach::__private::format_h4() {
    local -r message="$1"
    local -r dim="$(tput dim)"
    local -r blue="$(tput setaf 4)"
    local -r reset="$(tput sgr0)"
    local length

    length=${#message}

    printf "%s%s%s\n" "$blue$dim" "$message" "$reset" >&2
    printf "%s%s%s\n" "$blue" "$(printf -- '-%.0s' $(seq 1 $length))" "$reset" >&2
}

# Internal: Format h5 header - minimal text
# Arguments:
#   $1: Message to display
# Returns:
#   Prints formatted header to stderr
bach::__private::format_h5() {
    local -r message="$1"
    local -r dim="$(tput dim)"
    local -r green="$(tput setaf 2)"
    local -r reset="$(tput sgr0)"

    printf "%s%s%s\n" "$green$dim" "$message" "$reset" >&2
}

# Public API: Display formatted messages with optional emojis and headers
# Usage: bach::user_msg [--emoji-name] [--h1|--h2|--h3|--h4|--h5] <message>
# Examples:
#   bach::user_msg "Hello world"
#   bach::user_msg --start --wait "Building project"
#   bach::user_msg --h1 "Main Title"
#   bach::user_msg --h2 "Subtitle"
# Arguments:
#   $@: Options (--emoji-names, --h[1-5]) and message text
bach::user_msg() {
    # Emoji codes mapping - local to function
    local -A emojis=(
        ["SUCCESS"]="2705"      # ✅
        ["FAIL"]="274C"         # ❌
        ["WARNING"]="26A0"      # ⚠️
        ["START"]="1F680"       # 🚀
        ["KILL"]="1F480"        # 💀
        ["UPDATE"]="267B"       # ♻️
        ["REPAIR"]="1F527"      # 🔧
        ["CLEAN"]="1F9F9"       # 🧹
        ["TEST"]="1F9EA"        # 🧪
        ["SECURE"]="1F512"      # 🔒
        ["UNSECURE"]="1F513"    # 🔓
        ["SEND"]="1F4E9"        # 📩
        ["CALL"]="260E"         # ☎️
        ["SAVE"]="1F4BE"        # 💾
        ["INSPECT"]="1F453"     # 👓
        ["EXTRA"]="1F381"       # 🎁
        ["WAIT"]="23F3"         # ⏳
        ["BUILD"]="1F477"       # 👷
    )

    local -a emoji_codes=()
    local header_level=""
    local message=""
    local emoji_name=""
    local emoji_name_upper=""

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --h[1-5])
                header_level="${1:3}"
                shift
                ;;
            --*)
                # Extract emoji name from option
                emoji_name="${1:2}"
                emoji_name_upper="${emoji_name^^}"
                if [[ -n "${emojis[$emoji_name_upper]}" ]]; then
                    emoji_codes+=("${emojis[$emoji_name_upper]}")
                fi
                shift
                ;;
            *)
                # Everything else is the message
                message="$@"
                break
                ;;
        esac
    done

    # Handle header types
    if [[ -n "$header_level" ]]; then
        case "$header_level" in
            1) bach::__private::format_h1 "$message" ;;
            2) bach::__private::format_h2 "$message" ;;
            3) bach::__private::format_h3 "$message" ;;
            4) bach::__private::format_h4 "$message" ;;
            5) bach::__private::format_h5 "$message" ;;
        esac
        return
    fi

    # Build emoji prefix
    local emoji_prefix=""
    for code in "${emoji_codes[@]}"; do
        emoji_prefix+="\U${code} "
    done

    # Print message with emoji prefix
    if [[ -n "$emoji_prefix" ]]; then
        printf "%b%s\n" "$emoji_prefix" "$message" >&2
    else
        printf "%s\n" "$message" >&2
    fi
}

# Export the public function
export -f bach::user_msg