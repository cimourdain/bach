# Log Library Demo

The **log library** provides a sophisticated logging system for bash scripts with multiple log levels, colored output, and environment-based filtering.

## Capabilities

- ✅ Multiple log levels (verbose, trace, debug, info, warning, error, fatal)
- ✅ Environment-based log level filtering (`LOG_LEVEL`)
- ✅ Colored output with level-specific colors
- ✅ Automatic timestamp formatting
- ✅ Level-based priority system
- ✅ Output to stderr by default

## Exposed Functions

### bach::log

**Signature:**
```bash
bach log [options] "<message>"
```

**Arguments:**
- `-v, --verbose` - Verbose level log (lowest priority)
- `-t, --trace` - Trace level log
- `-d, --debug` - Debug level log
- `-i, --info` - Info level log (default)
- `-w, --warning` - Warning level log
- `-e, --error` - Error level log
- `-f, --fatal` - Fatal level log (highest priority)
- `message` - The message to log

**Environment Variables:**
- `LOG_LEVEL` - Minimum log level to display (verbose|trace|debug|info|warning|error|fatal)

**Returns:** 
- `0` if message was logged (meets log level threshold)
- `1` if message was filtered (below log level threshold)

**Output:** Writes to stderr in format: `[YYYY-MM-DD HH:MM:SS] LEVEL message`

## Logging Levels

Log levels in order of priority (lowest to highest):

1. **verbose** (`-v`, `--verbose`) - Most detailed, diagnostic information
2. **trace** (`-t`, `--trace`) - Entry/exit points and function traces
3. **debug** (`-d`, `--debug`) - Development debugging information
4. **info** (`-i`, `--info`) - General informational messages (default)
5. **warning** (`-w`, `--warning`) - Potentially problematic situations
6. **error** (`-e`, `--error`) - Error conditions that need attention
7. **fatal** (`-f`, `--fatal`) - Critical errors that halt execution

## Running the Demo

```bash
cd demo/log
bash demo.sh
```

## Usage Examples

### Basic Logging

For sourcing in your local context, see [README.md](../../README.md).

```bash
#!/bin/bash
source bach.sh

# Log at different levels
bach log "Application started"
bach log --info "Processing user request"
bach log --warning "Cache is full"
bach log --error "Failed to connect to database"
bach log --fatal "Critical system failure"
```

### Using Shorthand Flags

```bash
bach log -d "Debug information"
bach log -w "Warning level message"
bach log -e "Error message"
```

### Filtering with Environment Variables

```bash
# Only show warnings and above
export LOG_LEVEL="warning"

bach::log --debug "This won't show"
bach::log --warning "This will show"
bach::log --error "This will show"

unset LOG_LEVEL
```

### Practical Use Case - Error Handling

```bash
#!/bin/bash
source ../../../libs/log.sh

process_file() {
    local filename="$1"

    bach::log --debug "Processing file: $filename"

    if [[ ! -f "$filename" ]]; then
        bach::log --error "File not found: $filename"
        return 1
    fi

    local line_count=$(wc -l < "$filename")
    bach::log --info "Processing $line_count lines from $filename"

    bach::log --debug "File processing completed"
    return 0
}

process_file "data.txt" || bach::log --error "Failed to process file"
```

## Output Example

When you run the demo, you'll see output similar to:

```
========================================
BACH Log Library Demonstration
========================================

1. Basic Logging at Different Levels
=====================================
All messages with default logging (info level and above):

[INFO]    This is an info message (default level)
[WARNING] This is a warning message
[ERROR]   This is an error message
[FATAL]   This is a fatal message (highest priority)

2. Using Shorthand Options
============================
Same log levels using shorthand flags:

[VERBOSE] Verbose with -v shorthand
[TRACE]   Trace with -t shorthand
[DEBUG]   Debug with -d shorthand
[INFO]    Info with -i shorthand
[WARNING] Warning with -w shorthand
[ERROR]   Error with -e shorthand
[FATAL]   Fatal with -f shorthand

...and more demonstrations
```

## Key Points

- **Level-based Filtering**: The log library respects log level priorities. Lower priority levels (verbose, trace, debug) won't show unless explicitly enabled via `LOG_LEVEL`.
- **Colored Output**: Each log level has a distinct color for easy visual scanning.
- **Stderr Output**: All log messages are written to stderr, keeping stdout clean for data output.
- **Environment-aware**: Use `LOG_LEVEL` environment variable to control verbosity across your scripts.
