#!/bin/bash

unset LOG_LEVEL
source ./main.sh

printf "#### 1. Testing log utility with various log levels and message formats...\n" >&2

log --verbose "This is a verbose message"
log -v "This is another verbose message"
log --debug "This is a debug message"
log -d "This is another debug message"
log --info "This is an info message, it should be printed green (the default color as INFO is not defined in log_level_color_assoc_array)"
log -i "This is another info message, it should be printed in green (the default color as INFO is not defined in log_level_color_assoc_array)"
log --warning "This is a warning message"
log -w "This is another warning message"
log --error "This is an error message"
log -e "This is another error message"
log --fatal "This is a fatal error message"
log -f "This is another fatal error message"

printf "\n\n#### 2. Testing default log level behavior\n" >&2
log "This is a message without a log level, as the default_log_level is INFO, it should be printed as an INFO message"
log -x "I am a message with an unknown log level, as the default_log_level is INFO, it should be printed as an INFO message"

printf "\n\n#### 3. Test logging with global LOG_LEVEL=WARNING environment variable, only messages with a log level >= WARNING should be printed...\n" >&2
export LOG_LEVEL="WARNING"
log --verbose "I am a verbose message, I should NOT be printed because LOG_LEVEL is set to WARNING"
log -v "I am a verbose message, I should NOT be printed because LOG_LEVEL is set to WARNING"
log --debug "I am a debug message, I should NOT be printed because LOG_LEVEL is set to WARNING"
log -d "I am a debug message, I should NOT be printed because LOG_LEVEL is set to WARNING"
log --info "I am an info message, I should NOT be printed because LOG_LEVEL is set to WARNING"
log -i "I am an info message, I should NOT be printed because LOG_LEVEL is set to WARNING"
log  "I am a message without a log level, as i default to INFO, I should NOT be printed because LOG_LEVEL is set to WARNING"
log --warning "I am a warning message, I should be printed because LOG_LEVEL[WARNING]<=WARNING"
log -w "I am a warning message, I should be printed because LOG_LEVEL[WARNING]<=WARNING"
log --error "I am an error message, I should be printed because LOG_LEVEL[WARNING]<=ERROR"
log -e "I am an error message, I should be printed because LOG_LEVEL[WARNING]<=ERROR"
log --fatal "I am a fatal error message, I should be printed because LOG_LEVEL[WARNING]<=FATAL"
log -f "I am a fatal error message, I should be printed because LOG_LEVEL[WARNING]<=FATAL"
unset LOG_LEVEL

printf "\n\n#### 4. Testing multi sourcing of the log library, expected to output a debug message indicating the log utility is already defined...\n" >&2
source ./main.sh

