#!/bin/bash

################################################################################
# Arguments Parsing
################################################################################
# Description:
#   Parse command line arguments, with or without specification, into global
#   variables.
#
# Usage:
#   source /path/to/parse_args.sh
#   bach parse_args "$@"
#
# Dependencies:
#   - bash 4.0+
#   - bach function (bach.sh) for logging
#
# Author: BACHCLI Project
# Version: 1.0.0
################################################################################


# Prevent re-sourcing if functions already declared
if declare -F bach::parse_args &>/dev/null && \
   declare -F bach::parse_args::config::set_parsed_args_global_var_name &>/dev/null && \
   declare -F bach::parse_args::from_spec &>/dev/null; then
    return 0
fi

################################################################################
# Set the name of the global variable receiving the parsed arguments
# Arguments:
#   $1 - var_name: Name of the global associative array
# Globals:
#   __BACH_PARSE_ARGS_CONFIG[parsed_args_var_name] - Updated
# Returns:
#   0 on success, 1 if the name is empty
################################################################################
bach::parse_args::config::set_parsed_args_global_var_name() {
    local parsed_args_var_name
    parsed_args_var_name="${1:-""}"

    if [[ -z "${parsed_args_var_name}" ]]; then
        bach log --error "Parsed args global variable name cannot be empty"
        return 1
    fi

    bach log --debug "Parsed args global variable name set to ${parsed_args_var_name}"
    __BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]="$parsed_args_var_name"

    parsed_args_var_name="${__BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]}"
    # local -n parsed_args_var_name_ref="${parsed_args_var_name}"

    if [[ -z "${!parsed_args_var_name}" ]]; then
        bach log --verbose "Initializing ${parsed_args_var_name} to empty associative array"
        declare -gA "${parsed_args_var_name}"
    fi
    return 0
}
export -f bach::parse_args::config::set_parsed_args_global_var_name

if [[ -z "${__BACH_PARSE_ARGS_CONFIG}" ]]; then
    declare -gA __BACH_PARSE_ARGS_CONFIG=()
    bach::parse_args::config::set_parsed_args_global_var_name "__BACH_PARSED_ARGS"
    bach log --verbose --array-ref="${__BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]}"
fi


################################################################################
# Parse one command line element (private)
# Handles --key=value options, flags and positional arguments, and stores them in the parsed arguments variable.
# Arguments:
#   $1 - element: Element to parse
#   $2 - next_element: Following element (default: "")
# Globals:
#   __BACH_PARSE_ARGS_CONFIG[parsed_args_var_name] - Name of the parsed arguments variable (updated)
# Returns:
#   0 on success
################################################################################
bach::parse_args::__private::parse_element() {
    local element="$1"
    local next_element="${2:-""}"

    local -n parsed_args_var_ref="${__BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]}"
    local -n parsed_options_associative_array_ref="${parsed_args_var_ref["options"]}"
    local -n parsed_rest_associative_array_ref="${parsed_args_var_ref["rest"]}"

    bach log --verbose "Parse element: %s" "$element"
    if [[ "$element" =~ ^--([^=]+)=(.*)$ ]]; then
        local option_key="${BASH_REMATCH[1]}"
        local option_value="${BASH_REMATCH[2]}"
        bach log --verbose "Parsed long option: --${option_key} with value: ${option_value}"
        parsed_options_associative_array_ref["$option_key"]="$option_value"
    elif [[ "$element" =~ ^--(.+)$ ]]; then
        local flag_long_key="${BASH_REMATCH[1]}"
        bach log --verbose "Parsed long flag: --${flag_long_key}"
        parsed_options_associative_array_ref["$flag_long_key"]=true
    elif [[ "$element" =~ ^-([[:alnum:]]{1,})$ ]]; then
        local flags_short_keys="${BASH_REMATCH[1]}"
        bach log --verbose "Split short flags keys from: %s" "${element}"
        local flag_short_key
        for ((i=0; i<${#flags_short_keys}; i++)); do
            flag_short_key="${flags_short_keys:i:1}"
            bach log --verbose "[${i}]Parsed short flag: -${flag_short_key}"
            parsed_options_associative_array_ref["$flag_short_key"]=true
        done
    else
        bach log --verbose "Rest argument: ${element}"
        parsed_rest_associative_array_ref+=("$element")
    fi
    bach log --verbose "End of parsing of: %s" "$element"
    return 0
}

################################################################################
# Declare a converter function of the bash_utils library, loading the library if needed (private)
# Arguments:
#   $1 - function_name: Name of the converter function
# Returns:
#   0 if the function is declared, 1 otherwise
################################################################################
bach::parse_args::__private::load_converter() {
    declare -F "$1" &>/dev/null && return 0
    declare -F bach::__private::source_lib &>/dev/null || return 1
    # Try in a subshell first: the loader exits the shell when the library cannot be found
    (bach::__private::source_lib bash_utils) &>/dev/null || return 1
    bach::__private::source_lib bash_utils &>/dev/null
    declare -F "$1" &>/dev/null
}

################################################################################
# Get the content of the parsed arguments variables as a string
# The options are listed under their name and the rest arguments under rest[0], rest[1]...
# The conversion is done by the bash_utils library (bach::bash_utils::assoc_array::to_<format>).
# Arguments:
#   --format=<format> - json (default), markdown or ascii
# Globals:
#   __BACH_PARSE_ARGS_CONFIG[parsed_args_var_name] - Name of the parsed arguments variable
# Outputs:
#   The formatted string on stdout (nothing when the conversion function is not declared)
# Returns:
#   0 on success, 1 on invalid format or when the conversion function is not declared
################################################################################
bach::parse_args::debug_parsed() {
    local format="json" argument
    for argument in "$@"; do
        case "$argument" in
            --format=*) format="${argument#--format=}" ;;
            *) bach log --error "Unknown argument '%s' (expected --format=<json|markdown|ascii>)" "$argument"; return 1 ;;
        esac
    done
    if [[ ! "$format" =~ ^(json|markdown|ascii)$ ]]; then
        bach log --error "Unknown format '%s' (expected json, markdown or ascii)" "$format"
        return 1
    fi

    local converter="bach::bash_utils::assoc_array::to_${format}"
    if ! bach::parse_args::__private::load_converter "$converter"; then
        bach log --warning "Cannot format the parsed arguments as %s: function %s is not declared" "$format" "$converter"
        return 1
    fi

    local -n parsed_args_ref="${__BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]}"
    local -n parsed_options_ref="${parsed_args_ref["options"]}"
    local -n parsed_rest_ref="${parsed_args_ref["rest"]}"
    local -A parsed_view=()
    local key
    for key in "${!parsed_options_ref[@]}"; do parsed_view["$key"]="${parsed_options_ref["$key"]}"; done
    for key in "${!parsed_rest_ref[@]}"; do parsed_view["rest[${key}]"]="${parsed_rest_ref[key]}"; done
    "$converter" parsed_view
}
export -f bach::parse_args::debug_parsed

################################################################################
# Reset the parsed arguments variables (private)
# The parsed arguments variable gets the keys options and rest (names of the
# options and rest variables) and separator_index (position in the rest of the
# arguments following a -- separator, empty when there is no separator).
# Arguments:
#   None
# Globals:
#   __BACH_PARSE_ARGS_CONFIG[parsed_args_var_name] - Name of the parsed arguments variable (reset)
# Returns:
#   0 always
################################################################################
bach::parse_args::__private::reset_parsed_args_global_var() {
    bach log --verbose "Reset parsed args global variable"

    local parsed_args_global_associative_array_var_name="${__BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]}"
    local parsed_options_global_associative_array_var_name="${parsed_args_global_associative_array_var_name}_options"
    local parsed_rest_global_associative_array_var_name="${parsed_args_global_associative_array_var_name}_rest"

    # Unset before declaring: declaring an existing array would keep the values of the previous parsing
    unset "${parsed_options_global_associative_array_var_name}" "${parsed_rest_global_associative_array_var_name}"
    declare -gA "${parsed_options_global_associative_array_var_name}"
    declare -ga "${parsed_rest_global_associative_array_var_name}"

    local -n parsed_args_global_associative_array="${__BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]}"
    parsed_args_global_associative_array=(
        ["options"]="${parsed_options_global_associative_array_var_name}"
        ["rest"]="${parsed_rest_global_associative_array_var_name}"
        ["separator_index"]=""
    )
}

################################################################################
# Parse command line arguments without specification
# Options, flags and positional arguments are stored in the parsed arguments variable.
# A -- argument stops the parsing: the following arguments are added to the rest as they are.
# Arguments:
#   $@ - Command line arguments to parse
# Globals:
#   __BACH_PARSE_ARGS_CONFIG[parsed_args_var_name] - Name of the parsed arguments variable (updated)
# Returns:
#   0 always
################################################################################
bach::parse_args() {

    bach log --verbose "Parse arguments without specification."

    bach::parse_args::__private::reset_parsed_args_global_var

    local -n parsed_args_ref="${__BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]}"
    local -n parsed_rest_ref="${parsed_args_ref["rest"]}"
    local -a elements=("$@")
    local element_idx
    for ((element_idx=0; element_idx<${#elements[@]}; element_idx++)); do
        # echo "DEBUG:Inspect argument with index ${element_idx}/${#elements[@]}: ${elements[element_idx]}" >&2
        if [[ -n "${parsed_args_ref["separator_index"]}" ]]; then
            parsed_rest_ref+=("${elements[element_idx]}")
        elif [[ "${elements[element_idx]}" == "--" ]]; then
            parsed_args_ref["separator_index"]="${#parsed_rest_ref[@]}"
        else
            bach::parse_args::__private::parse_element "${elements[element_idx]}" "${elements[element_idx+1]:-""}"
        fi
    done

    return 0
}
export -f bach::parse_args

################################################################################
# docopt specification (http://docopt.org)
#
# The specification is a help message: a "Usage:" section listing usage patterns
# and optionally "Options:" sections describing the options. It is parsed into a
# tree of nodes stored in __BACH_PARSE_ARGS_DOCOPT:
#   n<id>.type      required | optional | either | oneormore | shortcut | command | argument | option
#   n<id>.name      name of a leaf (command word, <argument>, --long or -s)
#   n<id>.children  space separated ids of the children
#   opt:<name>.{short,long,argcount,default}  description of an option
#   lopt:<long>, sopt:<c>  option name from its long/short syntax
#   multi:<name>    set when the leaf can be repeated
# The arguments to match are kept in __BACH_PARSE_ARGS_LEFT (items "A<US>value" for
# positionals, "O<US>key<US>value" for options) and the matched leaves in
# __BACH_PARSE_ARGS_COLLECTED (items "<name><US>value").
################################################################################
__BACH_PARSE_ARGS_US=$'\x1f'

################################################################################
# Create a node of the specification tree (private)
# Arguments:
#   $1 - type, $2 - name (default: ""), $3 - children ids (default: "")
# Outputs:
#   __BACH_PARSE_ARGS_RET - id of the new node
################################################################################
bach::parse_args::__private::docopt_new_node() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local id="${doc_ref[count]:-0}"
    doc_ref[count]=$((id + 1))
    doc_ref["n${id}.type"]="$1"
    doc_ref["n${id}.name"]="${2:-""}"
    doc_ref["n${id}.children"]="${3:-""}"
    [[ "$1" != "shortcut" ]] || doc_ref[shortcuts]+=" ${id}"
    __BACH_PARSE_ARGS_RET="$id"
}

################################################################################
# Extract the usage section of a docopt text (private)
# The section starts after "usage:" (case insensitive) and ends at a blank line.
# Arguments:
#   $1 - doc: docopt text
# Outputs:
#   __BACH_PARSE_ARGS_RET - the usage section on one line
# Returns:
#   0 on success, 1 if there is no usage section
################################################################################
bach::parse_args::__private::docopt_extract_usage() {
    local line lower prefix section="" found=false
    while IFS= read -r line || [[ -n "$line" ]]; do
        lower="${line,,}"
        if [[ "$found" == "false" && "$lower" == *usage:* ]]; then
            found=true
            prefix="${lower%%usage:*}"
            section="${line:$((${#prefix} + 6))}"
        elif [[ "$found" == "true" ]]; then
            [[ "$line" =~ [^[:space:]] ]] || break
            section+=" ${line}"
        fi
    done <<< "$1"
    [[ "$found" == "true" ]] || { bach log --error "The specification has no 'Usage:' section"; return 1; }
    __BACH_PARSE_ARGS_RET="$section"
}

################################################################################
# Turn a usage section into one expression: every usage pattern is a group,
# the groups being alternatives: "prog a prog b" => "( a ) | ( b )" (private)
# Arguments:
#   $1 - section: usage section (program name first)
# Outputs:
#   __BACH_PARSE_ARGS_RET - the expression
################################################################################
bach::parse_args::__private::docopt_formal_usage() {
    local -a words
    read -ra words <<< "$1"
    local prog="${words[0]:-""}" formal="(" word
    for word in "${words[@]:1}"; do
        if [[ "$word" == "$prog" ]]; then formal+=" ) | ("; else formal+=" ${word}"; fi
    done
    __BACH_PARSE_ARGS_RET="${formal} )"
}

################################################################################
# Split an expression into tokens: words, brackets, parens, pipes and ellipsis
# (a <word with spaces> stays one token) (private)
# Arguments:
#   $1 - expression
# Outputs:
#   __BACH_PARSE_ARGS_TOKENS - the tokens, __BACH_PARSE_ARGS_TOKPOS reset to 0
################################################################################
bach::parse_args::__private::docopt_tokenize() {
    local expression="${1//$'\n'/ }"
    expression="${expression//\[/ [ }"
    expression="${expression//\]/ ] }"
    expression="${expression//(/ ( }"
    expression="${expression//)/ ) }"
    expression="${expression//|/ | }"
    expression="${expression//.../ ... }"

    __BACH_PARSE_ARGS_TOKENS=()
    __BACH_PARSE_ARGS_TOKPOS=0
    local token_regex='^[[:space:]]*([^[:space:]]*<[^>]*>|[^[:space:]]+)(.*)$'
    while [[ "$expression" =~ [^[:space:]] ]]; do
        [[ "$expression" =~ $token_regex ]] || return 1
        __BACH_PARSE_ARGS_TOKENS+=("${BASH_REMATCH[1]}")
        expression="${BASH_REMATCH[2]}"
    done
}

################################################################################
# Register an option (private)
# Arguments:
#   $1 - short (-s or ""), $2 - long (--long or ""), $3 - argcount (0 or 1), $4 - default value
# Outputs:
#   __BACH_PARSE_ARGS_RET - name of the option: the long syntax or else the short one
# Returns:
#   0 on success, 1 if the option takes an argument without long syntax
################################################################################
bach::parse_args::__private::docopt_register_option() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local short="$1" long="$2" argcount="$3" default="$4"
    local name="${long:-"$short"}"
    if [[ "$argcount" == "1" && -z "$long" ]]; then
        bach log --error "Option %s takes an argument: it needs a long syntax (--name=VALUE)" "$name"
        return 1
    fi
    doc_ref["opt:${name}.short"]="$short"
    doc_ref["opt:${name}.long"]="$long"
    doc_ref["opt:${name}.argcount"]="$argcount"
    doc_ref["opt:${name}.default"]="$default"
    [[ -z "$long" ]] || doc_ref["lopt:${long#--}"]="$name"
    [[ -z "$short" ]] || doc_ref["sopt:${short#-}"]="$name"
    doc_ref[optnames]+=" ${name}"
    __BACH_PARSE_ARGS_RET="$name"
}

################################################################################
# Parse one option description: "-o FILE, --output=FILE  Text [default: x]" (private)
# Arguments:
#   $1 - description (starts with -)
# Returns:
#   0 on success, 1 on invalid option
################################################################################
bach::parse_args::__private::docopt_parse_option_description() {
    local desc="$1" options_part descr="" word short="" long="" argcount=0 default=""
    local -a words
    options_part="${desc%%  *}"
    [[ "$desc" != *"  "* ]] || descr="${desc#*  }"
    options_part="${options_part//,/ }"
    read -ra words <<< "${options_part//=/ }"
    for word in "${words[@]}"; do
        case "$word" in
            --*) long="$word" ;;
            -*) short="$word" ;;
            *) argcount=1 ;;
        esac
    done
    local default_regex='\[[Dd][Ee][Ff][Aa][Uu][Ll][Tt]: ([^]]*)\]'
    [[ "$argcount" == "0" || ! "$descr" =~ $default_regex ]] || default="${BASH_REMATCH[1]}"
    bach::parse_args::__private::docopt_register_option "$short" "$long" "$argcount" "$default" || return 1
    [[ "$argcount" == "0" ]] || bach::parse_args::__private::docopt_store_choices "$__BACH_PARSE_ARGS_RET" "$descr"
}

################################################################################
# Store the allowed values stated in a description: [choices: A, B, C] (private)
# Arguments:
#   $1 - name: Name of the option or argument, $2 - description text
################################################################################
bach::parse_args::__private::docopt_store_choices() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local choices_regex='\[[Cc][Hh][Oo][Ii][Cc][Ee][Ss]: ([^]]*)\]' choice choices=","
    local -a items
    [[ "$2" =~ $choices_regex ]] || return 0
    IFS=',' read -ra items <<< "${BASH_REMATCH[1]}"
    for choice in "${items[@]}"; do
        choice="${choice#"${choice%%[![:space:]]*}"}"
        choices+="${choice%"${choice##*[![:space:]]}"},"
    done
    doc_ref["choices:${1}"]="$choices"
}

################################################################################
# Parse one argument description: "<name>  Text [choices: A, B]" (private)
# Arguments:
#   $1 - description (starts with the argument name as written in the usage)
################################################################################
bach::parse_args::__private::docopt_parse_argument_description() {
    local desc="$1" name="${1%%  *}" descr=""
    [[ "$desc" != *"  "* ]] || descr="${desc#*  }"
    bach::parse_args::__private::docopt_store_choices "$name" "$descr"
}

################################################################################
# Parse the option and argument descriptions of a docopt text (private)
# Option descriptions: lines starting with - in the indented lines following a line
# containing "options:". Argument descriptions (extension of docopt, to state the
# allowed values): lines starting with <name> or NAME in the indented lines following
# a line containing "arguments:".
# Arguments:
#   $1 - doc: docopt text
# Returns:
#   0 on success, 1 on invalid description
################################################################################
bach::parse_args::__private::docopt_parse_descriptions() {
    local line lower trimmed section="" desc
    local argument_regex='^(<|[[:upper:]][[:upper:][:digit:]_-]*([[:space:]]|$))'
    local -a descriptions=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        lower="${line,,}"
        if [[ "$lower" == *options:* ]]; then section="O"; continue
        elif [[ "$lower" == *arguments:* ]]; then section="A"; continue
        elif [[ "$line" != [[:space:]]* ]]; then section=""
        fi
        [[ -n "$section" ]] || continue
        trimmed="${line#"${line%%[![:space:]]*}"}"
        if [[ "$section" == "O" && "$trimmed" == -* ]] || [[ "$section" == "A" && "$trimmed" =~ $argument_regex ]]; then
            descriptions+=("${section}${trimmed%"${trimmed##*[![:space:]]}"}")
        elif (( ${#descriptions[@]} > 0 )); then
            descriptions[-1]+=" ${trimmed}"
        fi
    done <<< "$1"
    for desc in "${descriptions[@]}"; do
        if [[ "$desc" == O* ]]; then
            bach::parse_args::__private::docopt_parse_option_description "${desc:1}" || return 1
        else
            bach::parse_args::__private::docopt_parse_argument_description "${desc:1}"
        fi
    done
    return 0
}

################################################################################
# Collect the ids of the leaves (commands, arguments, options) under a node (private)
# Arguments:
#   $1 - node id, $2 - name of the indexed array receiving the ids
################################################################################
bach::parse_args::__private::docopt_leaves() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local -n leaves_out_ref="$2"
    local child
    case "${doc_ref["n${1}.type"]}" in
        command|argument|option) leaves_out_ref+=("$1") ;;
        *) for child in ${doc_ref["n${1}.children"]}; do
               bach::parse_args::__private::docopt_leaves "$child" "$2"
           done ;;
    esac
}

################################################################################
# Mark all the leaves under a node as repeatable (private)
# Arguments:
#   $1 - node id
################################################################################
bach::parse_args::__private::docopt_mark_multiple() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local -a marked_leaves=()
    local leaf
    bach::parse_args::__private::docopt_leaves "$1" marked_leaves
    for leaf in "${marked_leaves[@]}"; do
        doc_ref["multi:${doc_ref["n${leaf}.name"]}"]=1
    done
}

################################################################################
# Parse a long option of a usage pattern: --name, --name=ARG, --name ARG (private)
# --name ARG is an option with argument only if the option is described.
# Arguments:
#   $1 - token
# Outputs:
#   __BACH_PARSE_ARGS_RET - id of the option node
# Returns:
#   0 on success, 1 on invalid usage of the option (error logged)
################################################################################
bach::parse_args::__private::docopt_parse_long() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local body="${1#--}" has_value=false name
    [[ "$body" != *=* ]] || { has_value=true; body="${body%%=*}"; }
    name="${doc_ref["lopt:${body}"]:-""}"
    if [[ -z "$name" ]]; then
        bach::parse_args::__private::docopt_register_option "" "--${body}" "$([[ "$has_value" == "true" ]] && echo 1 || echo 0)" "" || return 1
        name="$__BACH_PARSE_ARGS_RET"
    elif [[ "${doc_ref["opt:${name}.argcount"]}" == "0" && "$has_value" == "true" ]]; then
        bach log --error "Option --%s does not take an argument" "$body"
        return 1
    elif [[ "${doc_ref["opt:${name}.argcount"]}" == "1" && "$has_value" == "false" ]]; then
        (( ++__BACH_PARSE_ARGS_TOKPOS ))
    fi
    bach::parse_args::__private::docopt_new_node option "$name"
}

################################################################################
# Parse stacked short options of a usage pattern: -a, -abc (private)
# Arguments:
#   $1 - token
# Outputs:
#   __BACH_PARSE_ARGS_RET - id of the node (sequence of the options)
# Returns:
#   0 on success, 1 on invalid option (error logged)
################################################################################
bach::parse_args::__private::docopt_parse_shorts() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local body="${1#-}" pos char name
    local -a ids=()
    for ((pos=0; pos<${#body}; pos++)); do
        char="${body:pos:1}"
        name="${doc_ref["sopt:${char}"]:-""}"
        if [[ -z "$name" ]]; then
            bach::parse_args::__private::docopt_register_option "-${char}" "" 0 "" || return 1
            name="$__BACH_PARSE_ARGS_RET"
        elif [[ "${doc_ref["opt:${name}.argcount"]}" == "1" ]]; then
            [[ $((pos + 1)) -lt ${#body} ]] || (( ++__BACH_PARSE_ARGS_TOKPOS ))
        fi
        bach::parse_args::__private::docopt_new_node option "$name"
        ids+=("$__BACH_PARSE_ARGS_RET")
    done
    if (( ${#ids[@]} == 1 )); then __BACH_PARSE_ARGS_RET="${ids[0]}"; else bach::parse_args::__private::docopt_new_node required "" "${ids[*]}"; fi
}

################################################################################
# Parse an atom: (group), [optional group], [options], leaf (private)
# Arguments:
#   None (reads the current token)
# Outputs:
#   __BACH_PARSE_ARGS_RET - id of the node
# Returns:
#   0 on success, 1 on syntax error (error logged)
################################################################################
bach::parse_args::__private::docopt_parse_atom() {
    local -n toks=__BACH_PARSE_ARGS_TOKENS
    local token="${toks[__BACH_PARSE_ARGS_TOKPOS]}" closing="" type=""
    (( ++__BACH_PARSE_ARGS_TOKPOS ))
    case "$token" in
        "(") closing=")"; type=required ;;
        "[") closing="]"; type=optional ;;
        options) bach::parse_args::__private::docopt_new_node shortcut; return 0 ;;
        "--"|"-") bach::parse_args::__private::docopt_new_node command "$token"; return 0 ;;
        --*) bach::parse_args::__private::docopt_parse_long "$token"; return ;;
        -*) bach::parse_args::__private::docopt_parse_shorts "$token"; return ;;
        \<*\>) bach::parse_args::__private::docopt_new_node argument "$token"; return 0 ;;
        *) if [[ "$token" == "${token^^}" && "$token" =~ [[:alpha:]] ]]; then
               bach::parse_args::__private::docopt_new_node argument "$token"
           else
               bach::parse_args::__private::docopt_new_node command "$token"
           fi
           return 0 ;;
    esac
    bach::parse_args::__private::docopt_parse_expr || return 1
    if [[ "${toks[__BACH_PARSE_ARGS_TOKPOS]:-""}" != "$closing" ]]; then
        bach log --error "Usage: missing '%s' (unbalanced group)" "$closing"
        return 1
    fi
    (( ++__BACH_PARSE_ARGS_TOKPOS ))
    bach::parse_args::__private::docopt_new_node "$type" "" "$__BACH_PARSE_ARGS_RET"
}

################################################################################
# Parse a sequence of atoms, each possibly followed by "..." (private)
# Outputs:
#   __BACH_PARSE_ARGS_RET - id of the node
# Returns:
#   0 on success, 1 on syntax error
################################################################################
bach::parse_args::__private::docopt_parse_seq() {
    local -n toks=__BACH_PARSE_ARGS_TOKENS
    local token atom
    local -a ids=()
    while token="${toks[__BACH_PARSE_ARGS_TOKPOS]:-""}"; [[ -n "$token" && ! "$token" =~ ^(\]|\)|\|)$ ]]; do
        bach::parse_args::__private::docopt_parse_atom || return 1
        atom="$__BACH_PARSE_ARGS_RET"
        if [[ "${toks[__BACH_PARSE_ARGS_TOKPOS]:-""}" == "..." ]]; then
            (( ++__BACH_PARSE_ARGS_TOKPOS ))
            bach::parse_args::__private::docopt_new_node oneormore "" "$atom"
            bach::parse_args::__private::docopt_mark_multiple "$atom"
            atom="$__BACH_PARSE_ARGS_RET"
        fi
        ids+=("$atom")
    done
    if (( ${#ids[@]} == 1 )); then __BACH_PARSE_ARGS_RET="${ids[0]}"; else bach::parse_args::__private::docopt_new_node required "" "${ids[*]}"; fi
}

################################################################################
# Parse sequences separated by | (mutually exclusive alternatives) (private)
# Outputs:
#   __BACH_PARSE_ARGS_RET - id of the node
# Returns:
#   0 on success, 1 on syntax error
################################################################################
bach::parse_args::__private::docopt_parse_expr() {
    local -n toks=__BACH_PARSE_ARGS_TOKENS
    local -a alternatives=()
    bach::parse_args::__private::docopt_parse_seq || return 1
    alternatives+=("$__BACH_PARSE_ARGS_RET")
    while [[ "${toks[__BACH_PARSE_ARGS_TOKPOS]:-""}" == "|" ]]; do
        (( ++__BACH_PARSE_ARGS_TOKPOS ))
        bach::parse_args::__private::docopt_parse_seq || return 1
        alternatives+=("$__BACH_PARSE_ARGS_RET")
    done
    if (( ${#alternatives[@]} == 1 )); then __BACH_PARSE_ARGS_RET="${alternatives[0]}"; else bach::parse_args::__private::docopt_new_node either "" "${alternatives[*]}"; fi
}

################################################################################
# Count the occurrences of each leaf name in a node: the occurrences of a
# sequence add up, for alternatives the highest count is kept (private)
# Arguments:
#   $1 - node id, $2 - name of the associative array receiving the counts
################################################################################
bach::parse_args::__private::docopt_count_leaves() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local -n counts_ref="$2"
    local child name
    case "${doc_ref["n${1}.type"]}" in
        command|argument|option) (( ++counts_ref["${doc_ref["n${1}.name"]}"] )) ;;
        either)
            declare -A "merged_${1}=()" "alternative_${1}=()"
            local -n merged_ref="merged_${1}" alternative_ref="alternative_${1}"
            for child in ${doc_ref["n${1}.children"]}; do
                alternative_ref=()
                bach::parse_args::__private::docopt_count_leaves "$child" "alternative_${1}"
                for name in "${!alternative_ref[@]}"; do
                    (( alternative_ref["$name"] > ${merged_ref["$name"]:-0} )) && merged_ref["$name"]="${alternative_ref["$name"]}"
                done
            done
            for name in "${!merged_ref[@]}"; do (( counts_ref["$name"] += merged_ref["$name"] )); done ;;
        *) for child in ${doc_ref["n${1}.children"]}; do
               bach::parse_args::__private::docopt_count_leaves "$child" "$2"
           done ;;
    esac
}

################################################################################
# Finish the specification tree: [options] shortcuts and repeated leaves (private)
# [options] stands for the described options not used elsewhere in the usage.
# A leaf used several times in one usage pattern is repeatable.
# Arguments:
#   $1 - root node id
################################################################################
bach::parse_args::__private::docopt_finalize() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local -a all_leaves=()
    local -A used=() occurrences=()
    local id name pattern
    bach::parse_args::__private::docopt_leaves "$1" all_leaves
    for id in "${all_leaves[@]}"; do used["${doc_ref["n${id}.name"]}"]=1; done
    for id in ${doc_ref[shortcuts]:-""}; do
        doc_ref["n${id}.children"]=""
        for name in ${doc_ref[optnames]:-""}; do
            [[ -z "${used[$name]:-""}" ]] || continue
            bach::parse_args::__private::docopt_new_node option "$name"
            doc_ref["n${id}.children"]+=" ${__BACH_PARSE_ARGS_RET}"
        done
    done
    [[ "${doc_ref["n${1}.type"]}" == "either" ]] && pattern="${doc_ref["n${1}.children"]}" || pattern="$1"
    for id in $pattern; do
        occurrences=()
        bach::parse_args::__private::docopt_count_leaves "$id" occurrences
        for name in "${!occurrences[@]}"; do
            (( occurrences["$name"] > 1 )) && doc_ref["multi:${name}"]=1
        done
    done
    for id in "${all_leaves[@]}"; do
        [[ "${doc_ref["n${id}.name"]}" != "--" ]] || doc_ref[has_separator]=1
    done
    doc_ref[root]="$1"
}

################################################################################
# Parse a docopt text into the specification tree (private)
# Arguments:
#   $1 - doc: docopt text
# Returns:
#   0 on success, 1 on invalid specification (error logged)
################################################################################
bach::parse_args::__private::docopt_load() {
    declare -gA __BACH_PARSE_ARGS_DOCOPT=()
    declare -ga __BACH_PARSE_ARGS_TOKENS=()
    bach::parse_args::__private::docopt_extract_usage "$1" || return 1
    __BACH_PARSE_ARGS_DOCOPT[usage]="$__BACH_PARSE_ARGS_RET"
    bach::parse_args::__private::docopt_parse_descriptions "$1" || return 1
    bach::parse_args::__private::docopt_formal_usage "${__BACH_PARSE_ARGS_DOCOPT[usage]}"
    bach::parse_args::__private::docopt_tokenize "$__BACH_PARSE_ARGS_RET" || return 1
    bach::parse_args::__private::docopt_parse_expr || return 1
    if (( __BACH_PARSE_ARGS_TOKPOS < ${#__BACH_PARSE_ARGS_TOKENS[@]} )); then
        bach log --error "Usage: unexpected '%s' (unbalanced group)" "${__BACH_PARSE_ARGS_TOKENS[__BACH_PARSE_ARGS_TOKPOS]}"
        return 1
    fi
    bach::parse_args::__private::docopt_finalize "$__BACH_PARSE_ARGS_RET"
}

################################################################################
# Check a value against the allowed values of an option or argument (private)
# On refusal the error message is kept to be logged if the usage does not match.
# Arguments:
#   $1 - name: Name of the option or argument, $2 - value
# Returns:
#   0 if allowed (or no restriction), 1 otherwise
################################################################################
bach::parse_args::__private::docopt_value_allowed() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local choices="${doc_ref["choices:${1}"]:-""}" list
    [[ -z "$choices" || "$choices" == *",$2,"* ]] && return 0
    list="${choices:1:-1}"
    doc_ref[last_error]="Value '${2}' is not allowed for ${1} (allowed: ${list//,/, })"
    return 1
}

################################################################################
# Match a command, an argument or an option against the arguments left (private)
# On success the matched argument is removed from the left and collected.
# Arguments:
#   $1 - leaf node id
# Returns:
#   0 if matched, 1 otherwise (left and collected unchanged)
################################################################################
bach::parse_args::__private::docopt_match_leaf() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local -n left_ref=__BACH_PARSE_ARGS_LEFT
    local -n coll_ref=__BACH_PARSE_ARGS_COLLECTED
    local us="$__BACH_PARSE_ARGS_US"
    local type="${doc_ref["n${1}.type"]}" name="${doc_ref["n${1}.name"]}" idx item key value
    local argcount="${doc_ref["opt:${name}.argcount"]:-0}"
    local long_key="${doc_ref["opt:${name}.long"]#--}" short_key="${doc_ref["opt:${name}.short"]#-}"

    for idx in "${!left_ref[@]}"; do
        item="${left_ref[idx]}"
        if [[ "$type" != "option" && "$item" == "A${us}"* ]]; then
            value="${item#"A${us}"}"
            [[ "$type" == "argument" || "$value" == "$name" ]] || return 1
            [[ "$type" != "argument" ]] || bach::parse_args::__private::docopt_value_allowed "$name" "$value" || return 1
            [[ "$type" == "argument" ]] || value=true
        elif [[ "$type" == "option" && "$item" == "O${us}"* ]]; then
            key="${item#"O${us}"}"; key="${key%%"${us}"*}"
            value="${item#"O${us}${key}${us}"}"
            [[ "$key" == "$long_key" && -n "$long_key" || "$argcount" == "0" && "$key" == "$short_key" && -n "$short_key" ]] || continue
            [[ "$argcount" == "1" || "$value" == "true" ]] || continue
            bach::parse_args::__private::docopt_value_allowed "$name" "$value" || continue
        else
            continue
        fi
        unset "left_ref[$idx]"
        left_ref=("${left_ref[@]}")
        coll_ref+=("${name}${us}${value}")
        return 0
    done
    return 1
}

################################################################################
# Match a node against the arguments left (private)
# Same algorithm as the docopt reference: required = all in order, optional = try
# each, oneormore = repeat, either = the alternative leaving the fewest arguments.
# Arguments:
#   $1 - node id
# Returns:
#   0 if matched, 1 otherwise (left and collected unchanged)
################################################################################
bach::parse_args::__private::docopt_match() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local -n left_ref=__BACH_PARSE_ARGS_LEFT
    local -n coll_ref=__BACH_PARSE_ARGS_COLLECTED
    local type="${doc_ref["n${1}.type"]}" child
    local -a saved_left=("${left_ref[@]}") saved_coll=("${coll_ref[@]}")

    case "$type" in
        required)
            for child in ${doc_ref["n${1}.children"]}; do
                bach::parse_args::__private::docopt_match "$child" && continue
                left_ref=("${saved_left[@]}"); coll_ref=("${saved_coll[@]}")
                return 1
            done
            return 0 ;;
        optional|shortcut)
            for child in ${doc_ref["n${1}.children"]}; do bach::parse_args::__private::docopt_match "$child"; done
            return 0 ;;
        oneormore) bach::parse_args::__private::docopt_match_oneormore "${doc_ref["n${1}.children"]}" ;;
        either) bach::parse_args::__private::docopt_match_either "${doc_ref["n${1}.children"]}" ;;
        *) bach::parse_args::__private::docopt_match_leaf "$1" ;;
    esac
}

################################################################################
# Match a node one or more times (private)
# Arguments:
#   $1 - node id
# Returns:
#   0 if matched at least once, 1 otherwise
################################################################################
bach::parse_args::__private::docopt_match_oneormore() {
    local -n left_ref=__BACH_PARSE_ARGS_LEFT
    local times=0 before
    while before="${left_ref[*]}"; bach::parse_args::__private::docopt_match "$1"; do
        (( ++times ))
        [[ "${left_ref[*]}" != "$before" ]] || break
    done
    (( times > 0 ))
}

################################################################################
# Match the alternatives and keep the one leaving the fewest arguments (private)
# Arguments:
#   $1 - alternatives ids (space separated)
# Returns:
#   0 if one alternative matched, 1 otherwise
################################################################################
bach::parse_args::__private::docopt_match_either() {
    local -n left_ref=__BACH_PARSE_ARGS_LEFT
    local -n coll_ref=__BACH_PARSE_ARGS_COLLECTED
    local -a base_left=("${left_ref[@]}") base_coll=("${coll_ref[@]}") best_left=() best_coll=()
    local best=-1 alternative
    for alternative in $1; do
        left_ref=("${base_left[@]}"); coll_ref=("${base_coll[@]}")
        bach::parse_args::__private::docopt_match "$alternative" || continue
        if (( best < 0 || ${#left_ref[@]} < best )); then
            best="${#left_ref[@]}"; best_left=("${left_ref[@]}"); best_coll=("${coll_ref[@]}")
        fi
    done
    left_ref=("${base_left[@]}"); coll_ref=("${base_coll[@]}")
    (( best >= 0 )) || return 1
    left_ref=("${best_left[@]}"); coll_ref=("${best_coll[@]}")
}

################################################################################
# Store a leaf value in the result (private)
# Flags and commands: true/false (a number if repeatable). Arguments and options
# with argument: the value (space separated if repeatable, plus "<name>,#" the
# count and "<name>,<i>" the values), "" or the default when not provided.
# Arguments:
#   $1 - result_name, $2 - leaf name, $3 - number of matches, $4 - leaf id,
#   $5 - values (US separated), $6 - key in the result
################################################################################
bach::parse_args::__private::docopt_store_value() {
    local -n result_ref="$1"
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local name="$2" count="$3" multiple="${doc_ref["multi:${2}"]:-""}" key="$6" idx
    local -a values=()
    if [[ "${doc_ref["n${4}.type"]}" == "command" || "${doc_ref["n${4}.type"]}" == "option" && "${doc_ref["opt:${name}.argcount"]}" == "0" ]]; then
        [[ -n "$multiple" ]] && result_ref["$key"]="$count" || { (( count > 0 )) && result_ref["$key"]=true || result_ref["$key"]=false; }
        return 0
    fi
    IFS="$__BACH_PARSE_ARGS_US" read -ra values <<< "$5"
    (( ${#values[@]} > 0 )) || [[ -z "${doc_ref["opt:${name}.default"]:-""}" ]] || values=("${doc_ref["opt:${name}.default"]}")
    [[ -n "$multiple" ]] || (( ${#values[@]} < 2 )) || values=("${values[-1]}")
    result_ref["$key"]="${values[*]}"
    [[ -z "$multiple" ]] && return 0
    result_ref["${key},#"]="${#values[@]}"
    for idx in "${!values[@]}"; do result_ref["${key},${idx}"]="${values[idx]}"; done
}

################################################################################
# Build the result from the matched leaves; every leaf of the specification gets
# a value. The key is the name of the leaf without its leading dashes (private)
# Arguments:
#   $1 - result_name: Name of the result associative array
################################################################################
bach::parse_args::__private::docopt_fill_result() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local -n coll_ref=__BACH_PARSE_ARGS_COLLECTED
    local us="$__BACH_PARSE_ARGS_US"
    local -A values=() counts=() seen=() result_keys=()
    local -a leaves=()
    local entry name id key
    for entry in "${coll_ref[@]}"; do
        name="${entry%%"${us}"*}"
        values["$name"]+="${values["$name"]+${us}}${entry#*"${us}"}"
        (( ++counts["$name"] ))
    done
    bach::parse_args::__private::docopt_leaves "${doc_ref[root]}" leaves
    for id in "${leaves[@]}"; do
        name="${doc_ref["n${id}.name"]}"
        [[ -z "${seen[$name]:-""}" ]] || continue
        seen["$name"]=1
        key="${name#"${name%%[!-]*}"}"
        [[ -n "$key" ]] || key="$name"
        if [[ -n "${result_keys[$key]:-""}" ]]; then
            bach log --error "The names '%s' and '%s' give the same key '%s' in the result" "${result_keys[$key]}" "$name" "$key"
            return 1
        fi
        result_keys["$key"]="$name"
        bach::parse_args::__private::docopt_store_value "$1" "$name" "${counts[$name]:-0}" "$id" "${values[$name]:-""}" "$key"
    done
}

################################################################################
# Match the arguments against the specification and build the result (private)
# Arguments:
#   $1 - result_name: Name of the result associative array
# Returns:
#   0 on success, 1 if the arguments do not match the usage (error logged)
################################################################################
bach::parse_args::__private::docopt_run() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local -n left_ref=__BACH_PARSE_ARGS_LEFT
    doc_ref[last_error]=""
    if ! bach::parse_args::__private::docopt_match "${doc_ref[root]}" || (( ${#left_ref[@]} > 0 )); then
        [[ -z "${doc_ref[last_error]}" ]] || bach log --error "%s" "${doc_ref[last_error]}"
        bach log --error "The arguments do not match the usage: %s" "${doc_ref[usage]}"
        return 1
    fi
    bach::parse_args::__private::docopt_fill_result "$1"
}

################################################################################
# Get the version stated in a docopt specification: the text following
# "version:" (case insensitive) at the beginning of a line (private)
# Arguments:
#   $1 - doc: docopt text
# Outputs:
#   __BACH_PARSE_ARGS_RET - the version, empty if the specification has none
################################################################################
bach::parse_args::__private::get_spec_version() {
    local line version=""
    __BACH_PARSE_ARGS_RET=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "${line,,}" =~ ^([[:space:]]*version:[[:space:]]*) ]] || continue
        version="${line:${#BASH_REMATCH[1]}}"
        __BACH_PARSE_ARGS_RET="${version%"${version##*[![:space:]]}"}"
        return 0
    done <<< "$1"
}

################################################################################
# Handle the help (-h, --help) and version (-v, --version) requests (private)
# The specification (help) or its version is printed on stdout, then the execution
# is aborted. A version request on a specification without version is an error.
# Arguments:
#   $1 - doc: docopt text
#   $2 - options_name: Name of the associative array of the parsed options
# Returns:
#   Exits with 0 on help/version request, with 1 if the version is requested but not
#   stated; returns 0 when there is no request
################################################################################
bach::parse_args::__private::handle_help_and_version() {
    local -n requested_options_ref="$2"
    if [[ "${requested_options_ref[h]:-""}" == "true" || "${requested_options_ref[help]:-""}" == "true" ]]; then
        printf '%s\n' "$1"
        exit 0
    elif [[ "${requested_options_ref[v]:-""}" == "true" || "${requested_options_ref[version]:-""}" == "true" ]]; then
        bach::parse_args::__private::get_spec_version "$1"
        if [[ -z "$__BACH_PARSE_ARGS_RET" ]]; then
            bach log --error "The specification does not state a version (add a 'Version: <version>' line)"
            exit 1
        fi
        printf '%s\n' "$__BACH_PARSE_ARGS_RET"
        exit 0
    fi
    return 0
}

################################################################################
# Build the arguments to match: the parsed options and the positionals (private)
# The arguments following a -- are matched as positionals, after a "--" argument, only
# if the usage has a [--] element; otherwise they are not matched and stay in the rest.
# Arguments:
#   $1 - options_name: Parsed options, $2 - rest_name: Parsed rest arguments
#   $3 - separator_index: Position of the -- in the rest ("" if none)
# Outputs:
#   __BACH_PARSE_ARGS_LEFT and __BACH_PARSE_ARGS_COLLECTED (reset)
################################################################################
bach::parse_args::__private::docopt_build_left() {
    local -n doc_ref=__BACH_PARSE_ARGS_DOCOPT
    local -n build_options_ref="$1"
    local -n build_rest_ref="$2"
    local separator_index="$3" us="$__BACH_PARSE_ARGS_US" key value
    local -a positionals=("${build_rest_ref[@]}")
    if [[ -n "$separator_index" && -n "${doc_ref[has_separator]:-""}" ]]; then
        positionals=("${build_rest_ref[@]:0:separator_index}" "--" "${build_rest_ref[@]:separator_index}")
    elif [[ -n "$separator_index" ]]; then
        positionals=("${build_rest_ref[@]:0:separator_index}")
    fi
    declare -ga __BACH_PARSE_ARGS_LEFT=() __BACH_PARSE_ARGS_COLLECTED=()
    for key in "${!build_options_ref[@]}"; do __BACH_PARSE_ARGS_LEFT+=("O${us}${key}${us}${build_options_ref["$key"]}"); done
    for value in "${positionals[@]}"; do __BACH_PARSE_ARGS_LEFT+=("A${us}${value}"); done
}

################################################################################
# Parse command line arguments against a docopt specification (http://docopt.org)
#
# Wrapper over bach::parse_args (same parsing rules: --flag, -abc, --key=value,
# positionals) matching the parsed arguments against the usage patterns of the
# specification. The specification is a docopt help message (a string or the path
# of a file): a "Usage:" section listing the usage patterns, optionally followed
# by "Options:" sections describing the options:
#   Usage:
#     prog ship new <name>...
#     prog ship <name> move <x> <y> [--speed=<kn>]
#     prog [options] [--] <file>...
#   Options:
#     -v, --verbose   Be verbose.
#     --speed=<kn>    Speed in knots [default: 10].
#     --flag=<c>      Flag of the ship [choices: FR, UK, US]
#   Arguments:
#     <name>          Name of the ship [choices: Guardian, Voyager]
#
# [choices: A, B] states the allowed values of an option with an argument or of an
# argument (extension of docopt; the arguments are described in an "Arguments:" section).
#
# -h/--help print the specification and -v/--version print its version (the text
# following "Version:" at the beginning of a line), then the execution is aborted
# (exit 0; exit 1 if the specification has no version). They are always recognised.
# A -- argument ends the options: the following arguments are always stored in the
# rest; they are matched as positionals (after a -- matched by a [--] element) only if
# the usage has a [--] element, otherwise the usage does not apply to them.
#
# The program name is not part of the arguments to parse. As with bach::parse_args,
# an option with an argument is written --name=value (-o VALUE is not supported).
#
# The result is the options array of the parsed arguments variable. Keys are the
# docopt names: command, <argument>, ARGUMENT, long (or s when there is no long
# syntax), without leading dashes: an option described by "-q, --quiet" is stored
# as quiet even when the usage uses -q. Values: true/false for flags and commands (a count when
# repeatable), the value of the options and arguments ("" if not provided, the
# default value of an option if any). Repeatable values are space separated and
# also stored in "<key>,#" (count) and "<key>,0", "<key>,1"... The rest array
# holds the positional arguments as given.
# Arguments:
#   $1 - doc: docopt specification (string or file path)
#   $@ - Command line arguments to parse
# Globals:
#   __BACH_PARSE_ARGS_CONFIG[parsed_args_var_name] - Name of the parsed arguments variable (updated)
# Returns:
#   0 on success, 1 if the specification is invalid or the arguments do not match
#   the usage (error logged, parsed arguments left empty)
################################################################################
bach::parse_args::from_spec() {
    local doc_text="${1:-""}"
    shift
    [[ ! -f "$doc_text" ]] || doc_text="$(<"$doc_text")"

    bach::parse_args "$@"
    local -n parsed_args_ref="${__BACH_PARSE_ARGS_CONFIG["parsed_args_var_name"]}"
    local result_name="${parsed_args_ref["options"]}" rest_name="${parsed_args_ref["rest"]}"
    local -n parsed_options_ref="$result_name"
    local -n parsed_rest_ref="$rest_name"
    local separator_index="${parsed_args_ref["separator_index"]}"
    bach::parse_args::__private::handle_help_and_version "$doc_text" "$result_name"
    local -a given_rest=("${parsed_rest_ref[@]}")
    local -A raw_options=()
    local key
    for key in "${!parsed_options_ref[@]}"; do raw_options["$key"]="${parsed_options_ref["$key"]}"; done
    bach::parse_args::__private::reset_parsed_args_global_var

    if bach::parse_args::__private::docopt_load "$doc_text" \
        && bach::parse_args::__private::docopt_build_left raw_options given_rest "$separator_index" \
        && bach::parse_args::__private::docopt_run "$result_name"; then
        parsed_rest_ref=("${given_rest[@]}")
        return 0
    fi
    bach::parse_args::__private::reset_parsed_args_global_var
    return 1
}
export -f bach::parse_args::from_spec
