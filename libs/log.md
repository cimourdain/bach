# log.sh - Logging Library

A sophisticated logging library providing level-based filtering, colored output, and timestamp formatting for bash scripts.

## Overview

The log library provides a flexible logging system with multiple log levels, environment-based filtering, and beautifully formatted colored output. Perfect for debugging scripts, monitoring long-running processes, and creating professional CLI tools.

## Features

- ✅ Multiple log levels (verbose, trace, debug, info, warning, error, fatal)
- ✅ Environment-based log level filtering (`LOG_LEVEL`)
- ✅ Colored output with level-specific colors
- ✅ Automatic timestamp formatting
- ✅ Level-based priority system
- ✅ Output to stderr by default

## Installation

```bash
# Source the logging library
source log.sh
```

## API Reference

### bach::log

Log a message with the specified level.

**Signature:**
```bash
bach::log [options] "<message>"
```

**Options:**
- `-v, --verbose` - Verbose level log (lowest priority)
- `-t, --trace` - Trace level log
- `-d, --debug` - Debug level log
- `-i, --info` - Info level log (default)
- `-w, --warning` - Warning level log
- `-e, --error` - Error level log
- `-f, --fatal` - Fatal level log (highest priority)

**Parameters:**
- `message` - The message to log

**Environment Variables:**
- `LOG_LEVEL` - Minimum log level to display (verbose|trace|debug|info|warning|error|fatal)

**Output:** Writes to stderr in format: `[YYYY-MM-DD HH:MM:SS] LEVEL message`

## Basic Examples

### Simple Logging

```bash
#!/bin/bash
source log.sh

# Log at different levels
bach::log "Application started"                    # Default: info level
bach::log --info "Processing user request"
bach::log --warning "Cache is full"
bach::log --error "Failed to connect to database"
bach::log --fatal "Critical system failure"
```

**Output:**
```
[2026-02-23 14:30:15] INFO    Application started
[2026-02-23 14:30:15] INFO    Processing user request
[2026-02-23 14:30:15] WARNING Cache is full
[2026-02-23 14:30:15] ERROR   Failed to connect to database
[2026-02-23 14:30:15] FATAL   Critical system failure
```

### Debug and Trace Logging

```bash
#!/bin/bash
source log.sh

function process_file() {
    local filename="$1"

    bach::log --debug "Entering process_file with: $filename"
    bach::log --trace "Opening file descriptor"

    if [[ -f "$filename" ]]; then
        bach::log --info "Processing file: $filename"
        local line_count=$(wc -l < "$filename")
        bach::log --debug "File has $line_count lines"
    else
        bach::log --error "File not found: $filename"
        return 1
    fi

    bach::log --trace "Exiting process_file"
}

process_file "data.txt"
```

### Using Short Flags

```bash
#!/bin/bash
source log.sh

# Short flag versions
bach::log -v "Verbose message"      # Verbose
bach::log -t "Trace message"        # Trace
bach::log -d "Debug message"        # Debug
bach::log -i "Info message"         # Info
bach::log -w "Warning message"      # Warning
bach::log -e "Error message"        # Error
bach::log -f "Fatal message"        # Fatal
```

## Advanced Examples

### Log Level Filtering

```bash
#!/bin/bash
source log.sh

# Set minimum log level to warning (suppress info, debug, trace, verbose)
export LOG_LEVEL="warning"

bach::log --verbose "This won't be shown"
bach::log --trace "This won't be shown"
bach::log --debug "This won't be shown"
bach::log --info "This won't be shown"
bach::log --warning "This WILL be shown"
bach::log --error "This WILL be shown"
bach::log --fatal "This WILL be shown"
```

**Output:**
```
[2026-02-23 14:30:15] WARNING This WILL be shown
[2026-02-23 14:30:15] ERROR   This WILL be shown
[2026-02-23 14:30:15] FATAL   This WILL be shown
```

### Application with Multiple Log Levels

```bash
#!/bin/bash
source log.sh

# Set log level from command line argument
LOG_LEVEL="${1:-info}"
export LOG_LEVEL

function initialize() {
    bach::log --verbose "Loading configuration files"
    bach::log --debug "Config directory: /etc/myapp"
    bach::log --info "Application initialized"
}

function connect_database() {
    bach::log --trace "Attempting database connection"
    bach::log --debug "Connection string: localhost:5432"

    if ! ping -c 1 localhost &>/dev/null; then
        bach::log --error "Database server unreachable"
        return 1
    fi

    bach::log --info "Connected to database"
    return 0
}

function process_data() {
    bach::log --verbose "Starting data processing pipeline"

    local start_time=$(date +%s)
    bach::log --debug "Start time: $start_time"

    # Process data...
    sleep 2

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    bach::log --info "Data processing completed in ${duration}s"
}

# Main execution
initialize
if connect_database; then
    process_data
else
    bach::log --fatal "Cannot proceed without database connection"
    exit 1
fi
```

**Usage:**
```bash
# Run with info level (default)
./app.sh

# Run with debug level
./app.sh debug

# Run with warning level (only warnings and above)
./app.sh warning
```

### Error Handling with Logging

```bash
#!/bin/bash
source log.sh

function safe_operation() {
    local operation="$1"

    bach::log --debug "Attempting operation: $operation"

    if eval "$operation" 2>&1; then
        bach::log --info "Operation succeeded: $operation"
        return 0
    else
        local exit_code=$?
        bach::log --error "Operation failed with code $exit_code: $operation"
        return $exit_code
    fi
}

# Examples
safe_operation "mkdir -p /tmp/test_dir"
safe_operation "touch /tmp/test_dir/file.txt"
safe_operation "cat /nonexistent/file.txt"  # This will fail and log error
```

### Long-Running Process with Progress Logging

```bash
#!/bin/bash
source log.sh

export LOG_LEVEL="info"

function process_items() {
    local -a items=("item1" "item2" "item3" "item4" "item5")
    local total=${#items[@]}

    bach::log --info "Starting batch processing of $total items"

    for i in "${!items[@]}"; do
        local item="${items[$i]}"
        local progress=$((i + 1))

        bach::log --debug "Processing item $progress/$total: $item"

        # Simulate processing
        sleep 1

        if [[ $((RANDOM % 10)) -gt 8 ]]; then
            bach::log --warning "Item $item took longer than expected"
        fi

        bach::log --verbose "Completed item $progress/$total"
    done

    bach::log --info "Batch processing completed: $total items processed"
}

process_items
```

### Structured Logging for Scripts

```bash
#!/bin/bash
source log.sh

# Function to log script sections
function log_section() {
    local section="$1"
    bach::log --info "========== $section =========="
}

function log_step() {
    local step="$1"
    bach::log --debug "→ $step"
}

# Main script
log_section "Pre-flight Checks"
log_step "Checking disk space"
bach::log --verbose "Available space: $(df -h / | awk 'NR==2 {print $4}')"

log_step "Checking dependencies"
for cmd in curl jq git; do
    if command -v "$cmd" &>/dev/null; then
        bach::log --debug "Found: $cmd"
    else
        bach::log --error "Missing dependency: $cmd"
    fi
done

log_section "Main Processing"
log_step "Downloading data"
bach::log --info "Fetching from remote server"

log_step "Validating data"
bach::log --debug "Running validation checks"

log_section "Cleanup"
log_step "Removing temporary files"
bach::log --verbose "Cleanup completed"

bach::log --info "Script execution completed successfully"
```

### Integration with Error Trapping

```bash
#!/bin/bash
source log.sh

# Set up error trapping
set -euo pipefail

trap 'bach::log --fatal "Script failed at line $LINENO: $BASH_COMMAND"; exit 1' ERR
trap 'bach::log --warning "Script interrupted by user"; exit 130' INT

function cleanup() {
    bach::log --info "Performing cleanup"
    # Cleanup code here
}

trap cleanup EXIT

# Main script
bach::log --info "Starting critical operation"
bach::log --debug "Working directory: $PWD"

# Your code here
false  # This will trigger ERR trap
```

### Dynamic Log Level Control

```bash
#!/bin/bash
source log.sh

function set_log_level() {
    local level="$1"
    export LOG_LEVEL="$level"
    bach::log --info "Log level changed to: $level"
}

# Start with info level
export LOG_LEVEL="info"

bach::log --debug "This won't show initially"
bach::log --info "Application started"

# Switch to debug for troubleshooting
set_log_level "debug"
bach::log --debug "Now debug messages are visible"
bach::log --trace "But trace is still hidden"

# Switch to trace for detailed debugging
set_log_level "trace"
bach::log --trace "Trace messages now visible"

# Back to info for normal operation
set_log_level "info"
bach::log --debug "Debug hidden again"
```

## Log Level Priority

The library uses a numeric priority system for filtering:

| Level   | Priority | Use Case                          |
|---------|----------|-----------------------------------|
| verbose | 0        | Extremely detailed output         |
| trace   | 1        | Function entry/exit tracking      |
| debug   | 2        | Debugging information             |
| info    | 3        | General informational messages    |
| warning | 4        | Warning messages                  |
| error   | 5        | Error messages                    |
| fatal   | 6        | Critical errors (application exit)|

When `LOG_LEVEL` is set, only messages at that level or higher priority are displayed.

## Color Coding

- **Verbose** - Gray (dim)
- **Trace** - Cyan
- **Debug** - Blue
- **Info** - Green
- **Warning** - Yellow
- **Error** - Red
- **Fatal** - Bold Red

Colors are automatically applied using `tput` for terminal compatibility.

## Best Practices

1. **Use appropriate levels**: Don't log everything as `--error`
2. **Set LOG_LEVEL in production**: Use `warning` or `error` to reduce noise
3. **Use debug/trace for development**: Enable verbose logging during development
4. **Log to stderr**: The library outputs to stderr, leaving stdout for data
5. **Include context**: Add relevant variables and state information to log messages
6. **Structure your logs**: Use consistent formatting for easier parsing

## Environment Variables

### LOG_LEVEL

Controls the minimum log level to display. Messages below this level are filtered out.

```bash
# Set globally
export LOG_LEVEL="debug"

# Set for single command
LOG_LEVEL=trace ./my-script.sh

# Unset to show all messages
unset LOG_LEVEL
```

Valid values (case-insensitive):
- `verbose`
- `trace`
- `debug`
- `info`
- `warning`
- `error`
- `fatal`

## See Also

- [assert.md](assert.md) - Test assertion library
- [parse_args.md](parse_args.md) - Command-line argument parsing
- [docstring_helper.md](docstring_helper.md) - Documentation generation
