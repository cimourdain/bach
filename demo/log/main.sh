#!/bin/bash

# Source the main bash library to ensure all core functions are available
source "$(dirname "${BASH_SOURCE[0]}")/../../bach.sh"
__BACH_CONFIG["libs_local_path_default"]="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/lib/bach"
__BACH_CONFIG["log__default_execution_log_level_key"]="verbose"
__BACH_CONFIG["log__default_log_level_name"]="debug"

main() {
    echo "1. Running log demo" >&2

    echo "1.1 Basic log message expected to have default log level to debug" >&2
    bach log "Basic log message with default log level (debug)"

    echo "1.2 log messages with log level argument" >&2
    echo "1.2.1 log messages with log level argument --long option" >&2
    bach log --verbose "Verbose log message"
    bach log --trace "Trace log message"
    bach log --debug "Debug log message"
    bach log --info "Info log message"
    bach log --warning "Warning log message"
    bach log --error "Error log message"
    bach log --fatal "Fatal log message"

    echo "1.2.2 log messages with log level argument --short option" >&2
    bach log -v "Verbose log message"
    bach log -t "Trace log message"
    bach log -d "Debug log message"
    bach log -i "Info log message"
    bach log -w "Warning log message"
    bach log -e "Error log message"
    bach log -f "Fatal log message"

    echo "1.3 log messages with multiple arguments (first is a printf format)" >&2
    bach log --info "printfFormat:%s-%s-%s" "arg1" "arg2" "arg3"
    bach log --warning "printfFormat:%s-%s-%s" "arg1 arg1.1" "arg2" "arg3"

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi