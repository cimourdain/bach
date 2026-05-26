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

## Usage

### Basic Examples

#### Simple Logging

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
# Log at different levels
export LOG_LEVEL="info"                           # Display messages from info level
bach log "Application started"                    # Default: info level
bach log --info "Processing user request"
bach log --warning "Cache is full"
bach log --error "Failed to connect to database"
bach log --fatal "Critical system failure"
```

```bash [Standalone]
#!/bin/bash
source my-libs/log.sh
# Log at different levels
export LOG_LEVEL="info"                           # Display messages from info level
bach::log "Application started"                    # Default: info level
bach::log --info "Processing user request"
bach::log --warning "Cache is full"
bach::log --error "Failed to connect to database"
bach::log --fatal "Critical system failure"
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="c-green">[2026-01-01 12:00:00][INFO][/home/user/project/my_script.sh:6 main]Application started</span>
<span class="c-green">[2026-01-01 12:00:00][INFO][/home/user/project/my_script.sh:7 main]Processing user request</span>
<span class="c-yellow">[2026-01-01 12:00:00][WARNING][/home/user/project/my_script.sh:8 main]Cache is full</span>
<span class="c-red">[2026-01-01 12:00:00][ERROR][/home/user/project/my_script.sh:9 main]Failed to connect to database</span>
<span class="c-red"></span><span class="c-red bold">[2026-01-01 12:00:00][FATAL][/home/user/project/my_script.sh:10 main]Critical system failure</span></pre>

:::

#### Log Levels

Only messages whose level is at least the execution log level are displayed. The execution log level is defined by the [`LOG_LEVEL` environment variable](#log-level). Log levels can be given with long (`--debug`) or short (`-d`) options.

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
log_all_levels() {
    bach log --verbose "Verbose message"
    bach log -t "Trace message"
    bach log --debug "Debug message"
    bach log -i "Info message"
    bach log --warning "Warning message"
    bach log -e "Error message"
    bach log -f "Fatal message"
}

# Only messages from warning level are displayed
export LOG_LEVEL="warning"
echo "The following logs use the warning log level"
log_all_levels

# Messages from debug level are displayed
export LOG_LEVEL="debug"
echo "The following logs use the debug log level"
log_all_levels
```

```bash [Standalone]
#!/bin/bash
source my-libs/log.sh
log_all_levels() {
    bach::log --verbose "Verbose message"
    bach::log -t "Trace message"
    bach::log --debug "Debug message"
    bach::log -i "Info message"
    bach::log --warning "Warning message"
    bach::log -e "Error message"
    bach::log -f "Fatal message"
}

# Only messages from warning level are displayed
export LOG_LEVEL="warning"
echo "The following logs use the warning log level"
log_all_levels

# Messages from debug level are displayed
export LOG_LEVEL="debug"
echo "The following logs use the debug log level"
log_all_levels
```

:::

::: details Expected output

<pre class="ansi" v-pre>The following logs use the warning log level
<span class="c-yellow">[2026-01-01 12:00:00][WARNING][/home/user/project/my_script.sh:9 log_all_levels]Warning message</span>
<span class="c-red">[2026-01-01 12:00:00][ERROR][/home/user/project/my_script.sh:10 log_all_levels]Error message</span>
<span class="c-red"></span><span class="c-red bold">[2026-01-01 12:00:00][FATAL][/home/user/project/my_script.sh:11 log_all_levels]Fatal message</span>
The following logs use the debug log level
<span class="c-blue">[2026-01-01 12:00:00][DEBUG][/home/user/project/my_script.sh:7 log_all_levels]Debug message</span>
<span class="c-green">[2026-01-01 12:00:00][INFO][/home/user/project/my_script.sh:8 log_all_levels]Info message</span>
<span class="c-yellow">[2026-01-01 12:00:00][WARNING][/home/user/project/my_script.sh:9 log_all_levels]Warning message</span>
<span class="c-red">[2026-01-01 12:00:00][ERROR][/home/user/project/my_script.sh:10 log_all_levels]Error message</span>
<span class="c-red"></span><span class="c-red bold">[2026-01-01 12:00:00][FATAL][/home/user/project/my_script.sh:11 log_all_levels]Fatal message</span></pre>

:::

#### Logging to a File

Logs are written on stderr. Redirect stderr to route the logs to a file.

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
LOG_FILE="app.log"
export LOG_LEVEL="info"

# Logs are written on stderr: redirect it to append them to a file
{
    bach log --info "Application started"
    bach log --warning "Cache is full"
    bach log --error "Failed to connect to database"
} 2>> "$LOG_FILE"

echo "Content of $LOG_FILE:"
cat "$LOG_FILE"
```

```bash [Standalone]
#!/bin/bash
source my-libs/log.sh
LOG_FILE="app.log"
export LOG_LEVEL="info"

# Logs are written on stderr: redirect it to append them to a file
{
    bach::log --info "Application started"
    bach::log --warning "Cache is full"
    bach::log --error "Failed to connect to database"
} 2>> "$LOG_FILE"

echo "Content of $LOG_FILE:"
cat "$LOG_FILE"
```

:::

::: details Expected output

<pre class="ansi" v-pre>Content of app.log:
<span class="c-green">[2026-01-01 12:00:00][INFO][/home/user/project/my_script.sh:9 main]Application started</span>
<span class="c-yellow">[2026-01-01 12:00:00][WARNING][/home/user/project/my_script.sh:10 main]Cache is full</span>
<span class="c-red">[2026-01-01 12:00:00][ERROR][/home/user/project/my_script.sh:11 main]Failed to connect to database</span></pre>

:::

### Advanced Examples

#### Error Handling with Logging

This example wraps command execution in a `safe_operation` function so that the logs tell the whole story of a command: a debug log before running it, an info log when it succeeds, and an error log when it fails. The command output is captured instead of being printed, so that the error message raised by the failing command is part of the error log. The script log level is set to `debug` to display every step.

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
export LOG_LEVEL="debug"

# Run a command, log its progress and, on failure, its error message
function safe_operation() {
    local operation="$1"

    bach log --debug "Attempting operation: $operation"

    # Capture the command output (stdout and stderr) instead of printing it
    local operation_output
    if operation_output=$(eval "$operation" 2>&1); then
        bach log --info "Operation succeeded: $operation"
        return 0
    else
        local exit_code=$?
        bach log --error "Operation failed with code $exit_code: $operation ($operation_output)"
        return $exit_code
    fi
}

# Examples
safe_operation "mkdir -p /tmp/test_dir"
safe_operation "touch /tmp/test_dir/file.txt"
safe_operation "cat /nonexistent/file.txt"  # This will fail and log the error
```

```bash [Standalone]
#!/bin/bash
source my-libs/log.sh
export LOG_LEVEL="debug"

# Run a command, log its progress and, on failure, its error message
function safe_operation() {
    local operation="$1"

    bach::log --debug "Attempting operation: $operation"

    # Capture the command output (stdout and stderr) instead of printing it
    local operation_output
    if operation_output=$(eval "$operation" 2>&1); then
        bach::log --info "Operation succeeded: $operation"
        return 0
    else
        local exit_code=$?
        bach::log --error "Operation failed with code $exit_code: $operation ($operation_output)"
        return $exit_code
    fi
}

# Examples
safe_operation "mkdir -p /tmp/test_dir"
safe_operation "touch /tmp/test_dir/file.txt"
safe_operation "cat /nonexistent/file.txt"  # This will fail and log the error
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="c-blue">[2026-01-01 12:00:00][DEBUG][/home/user/project/my_script.sh:10 safe_operation]Attempting operation: mkdir -p /tmp/test_dir</span>
<span class="c-green">[2026-01-01 12:00:00][INFO][/home/user/project/my_script.sh:15 safe_operation]Operation succeeded: mkdir -p /tmp/test_dir</span>
<span class="c-blue">[2026-01-01 12:00:00][DEBUG][/home/user/project/my_script.sh:10 safe_operation]Attempting operation: touch /tmp/test_dir/file.txt</span>
<span class="c-green">[2026-01-01 12:00:00][INFO][/home/user/project/my_script.sh:15 safe_operation]Operation succeeded: touch /tmp/test_dir/file.txt</span>
<span class="c-blue">[2026-01-01 12:00:00][DEBUG][/home/user/project/my_script.sh:10 safe_operation]Attempting operation: cat /nonexistent/file.txt</span>
<span class="c-red">[2026-01-01 12:00:00][ERROR][/home/user/project/my_script.sh:19 safe_operation]Operation failed with code 1: cat /nonexistent/file.txt (cat: /nonexistent/file.txt: No such file or directory)</span></pre>

:::

#### Integration with Error Trapping

This example uses the logs as the reporting channel of bash traps, so that a script never fails silently:

- the `ERR` trap logs a `fatal` message with the line number and the failing command, then exits;
- the `INT` trap logs a `warning` when the user interrupts the script (Ctrl+C);
- the `EXIT` trap runs a `cleanup` function that logs the cleanup, whatever the way the script ends.

Here the final `false` command fails on purpose to trigger the `ERR` trap.

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
# Set up error trapping
set -euo pipefail

trap 'bach log --fatal "Script failed at line $LINENO: $BASH_COMMAND"; exit 1' ERR
trap 'bach log --warning "Script interrupted by user"; exit 130' INT

function cleanup() {
    bach log --info "Performing cleanup"
    # Cleanup code here
}

trap cleanup EXIT

# Main script
bach log --info "Starting critical operation"
bach log --debug "Working directory: $PWD"

# Your code here
false  # This will trigger ERR trap
```

```bash [Standalone]
#!/bin/bash
source my-libs/log.sh
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

:::

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

## Roadmap

- [ ] Handle multiple loggers with distinct configurations (distinct `__BACH_LOG_CONFIG`)
- [ ] Handle logging to a file (without color formatting)

## See Also

- [assert.md](assert.md) - Test assertion library
- [parse_args.md](parse_args.md) - Command-line argument parsing
- [docstring_helper.md](docstring_helper.md) - Documentation generation
