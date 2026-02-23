# parse_args.sh - Argument Parsing Library

A comprehensive command-line argument parsing library with docstring validation, automatic help/version generation, and flexible parsing modes.

## Overview

The parse_args library provides two powerful argument parsing approaches: docstring-based parsing with validation and auto-generated help, or simple dynamic parsing without documentation requirements. Both modes support flags, options with values, and path arguments.

## Features

- ✅ **Two parsing modes**: Docstring-based (validated) and simple (dynamic)
- ✅ **Automatic help generation**: `--help` and `-h` flags auto-injected
- ✅ **Version extraction**: Automatic version parsing from docstrings
- ✅ **Default values**: Support for default values in options
- ✅ **Type detection**: Automatic flag vs option detection
- ✅ **Path arguments**: Separate handling of non-option arguments
- ✅ **Global state**: Parsed values accessible via global associative array
- ✅ **Helper functions**: Check if help or version was requested

## Installation

```bash
# Source the argument parsing library
source parse_args.sh
```

## Global Variables

### __ARGS

Global associative array storing parsed options and flags. Can be accessed using the name reference from `__ARGS_VAR_NAME`.

```bash
declare -gA __ARGS
```

### __PATH_ARGS

Global indexed array storing positional/path arguments (non-option arguments).

```bash
declare -ga __PATH_ARGS
```

### __ARGS_VAR_NAME

Name of the global associative array for parsed options (default: `__ARGS`). Can be overridden before sourcing the library.

## API Reference

### bach::parse_args_from_docstring

Parse command-line arguments with docstring validation and automatic help/version handling.

**Signature:**
```bash
bach::parse_args_from_docstring "$doc_string" "$@"
```

**Parameters:**
- `$1` (doc_string): Documentation string with Options section
- `$@`: Command-line arguments to parse

**Returns:**
- `0` - Parsing successful, continue execution
- `1` - Parse error occurred
- `2` - Help was requested and printed
- `3` - Version was requested and printed

**Side Effects:**
- Sets `__ARGS` associative array with parsed options
- Sets `__PATH_ARGS` array with path arguments

**Docstring Format:**
```
Command Description

Usage:
    command [options]

Options:
    -f,--flag,Description
    -o,--option=,default="value",Description

----
1.0.0
```

### bach::parse_args

Parse arguments without docstring validation (simple mode).

**Signature:**
```bash
bach::parse_args "$@"
```

**Parameters:**
- `$@`: Command-line arguments to parse

**Returns:** `0` - Parsing successful

**Side Effects:**
- Sets `__ARGS` associative array with parsed options
- Sets `__PATH_ARGS` array with path arguments

**Parsing Rules:**
- Flags: `-f`, `--flag` → sets to `"true"`
- Options: `--key=value`, `--key value` → sets key to value
- Merged flags: `-abc` → sets `a`, `b`, `c` to `"true"`
- Path args: Everything after first non-option or after `--`

### bach::is_help_requested

Check if help flag was set during parsing.

**Signature:**
```bash
bach::is_help_requested
```

**Returns:** `0` if help was requested, `1` otherwise

### bach::is_version_requested

Check if version flag was set during parsing.

**Signature:**
```bash
bach::is_version_requested
```

**Returns:** `0` if version was requested, `1` otherwise

### bach::get_version_from_doc

Extract version number from docstring.

**Signature:**
```bash
bach::get_version_from_doc "$doc_string"
```

**Parameters:**
- `$1` (doc_string): Documentation string

**Returns:** Prints version string (e.g., "1.2.3")

## Basic Examples

### Simple Flag Parsing (Dynamic Mode)

```bash
#!/bin/bash
source parse_args.sh

# Parse arguments without docstring
bach::parse_args "$@"

# Access parsed values
declare -n args="__ARGS"

echo "Verbose: ${args[verbose]:-false}"
echo "Debug: ${args[debug]:-false}"
echo "Path args: ${__PATH_ARGS[*]}"
```

**Usage:**
```bash
./script.sh --verbose --debug file1.txt file2.txt
# Output:
# Verbose: true
# Debug: true
# Path args: file1.txt file2.txt
```

### Parsing Options with Values (Dynamic Mode)

```bash
#!/bin/bash
source parse_args.sh

bach::parse_args "$@"
declare -n args="__ARGS"

echo "Output format: ${args[output-format]:-text}"
echo "Config file: ${args[config]:-config.json}"
echo "Verbose: ${args[verbose]:-false}"
```

**Usage:**
```bash
./script.sh --output-format=json --config myconfig.yaml --verbose
# Output:
# Output format: json
# Config file: myconfig.yaml
# Verbose: true
```

### Docstring-Based Parsing with Validation

```bash
#!/bin/bash
source parse_args.sh

DOC="MyApp - Example Application

A simple application demonstrating argument parsing.

Usage:
    myapp [options] <files>...

Options:
    -v,--verbose,Enable verbose output
    -q,--quiet,Suppress output
    --output-format=,default=\"text\",Output format (text, json, xml)
    -n,--number=,default=\"10\",Number of items to process

----
1.0.0
"

# Parse with validation
bach::parse_args_from_docstring "$DOC" "$@"

case $? in
    0) ;;  # Continue
    2|3) exit 0 ;;  # Help or version shown
    *) exit 1 ;;  # Error
esac

# Access parsed values
declare -n args="__ARGS"

echo "Verbose: ${args[verbose]}"
echo "Quiet: ${args[quiet]}"
echo "Format: ${args[output-format]}"
echo "Number: ${args[number]}"
echo "Files: ${__PATH_ARGS[*]}"
```

**Usage:**
```bash
./script.sh --help
./script.sh --version
./script.sh -v --output-format=json file1.txt file2.txt
```

### Short and Long Flags

```bash
#!/bin/bash
source parse_args.sh

DOC="Test App

Usage:
    test [options]

Options:
    -a,--all,Process all items
    -f,--force,Force operation
    -r,--recursive,Recursive processing

----
1.0.0
"

bach::parse_args_from_docstring "$DOC" "$@"
declare -n args="__ARGS"

# Both -a and --all set the same value
echo "All: ${args[all]}"
echo "Force: ${args[force]}"
echo "Recursive: ${args[recursive]}"
```

**Usage:**
```bash
./script.sh -a -f         # Short flags
./script.sh --all --force # Long flags
./script.sh -af           # Combined short flags (dynamic mode only)
```

## Advanced Examples

### Complete CLI Application

```bash
#!/bin/bash
source parse_args.sh

DOC="DataProcessor - Process data files

A utility for processing data files with various options.

Usage:
    dataprocessor [options] <input_files>...

Options:
    -v,--verbose,Enable verbose output
    -d,--dry-run,Show what would be done without doing it
    -o,--output=,default=\"output.txt\",Output file path
    --format=,default=\"json\",Output format (json, csv, xml)
    --workers=,default=\"4\",Number of parallel workers
    -c,--compress,Compress output file
    --skip-validation,Skip input validation

----
2.1.0
"

# Parse arguments
bach::parse_args_from_docstring "$DOC" "$@"

case $? in
    0) ;;
    2|3) exit 0 ;;
    *)
        echo "Error: Failed to parse arguments" >&2
        exit 1
        ;;
esac

# Access parsed values
declare -n args="__ARGS"

# Validate we have input files
if [[ ${#__PATH_ARGS[@]} -eq 0 ]]; then
    echo "Error: No input files specified" >&2
    exit 1
fi

# Process based on flags
if [[ "${args[verbose]}" == "true" ]]; then
    echo "Verbose mode enabled"
    echo "Output: ${args[output]}"
    echo "Format: ${args[format]}"
    echo "Workers: ${args[workers]}"
    echo "Input files: ${__PATH_ARGS[*]}"
fi

if [[ "${args[dry-run]}" == "true" ]]; then
    echo "DRY RUN - Would process:"
    for file in "${__PATH_ARGS[@]}"; do
        echo "  - $file"
    done
    exit 0
fi

# Actual processing
echo "Processing ${#__PATH_ARGS[@]} files..."
for file in "${__PATH_ARGS[@]}"; do
    if [[ ! -f "$file" ]] && [[ "${args[skip-validation]}" != "true" ]]; then
        echo "Error: File not found: $file" >&2
        continue
    fi

    echo "Processing: $file"
    # Process file...
done

if [[ "${args[compress]}" == "true" ]]; then
    echo "Compressing output: ${args[output]}"
    # Compress...
fi

echo "Done!"
```

### Checking Help and Version

```bash
#!/bin/bash
source parse_args.sh

DOC="MyTool v1.0

Usage:
    mytool [options]

Options:
    -c,--config=,default=\"config.yaml\",Configuration file

----
1.0.0
"

bach::parse_args_from_docstring "$DOC" "$@"
declare -n args="__ARGS"

# Custom handling of help request
if bach::is_help_requested; then
    echo "Custom help message"
    echo "For more info, visit: https://example.com"
    exit 0
fi

# Custom handling of version request
if bach::is_version_requested; then
    version=$(bach::get_version_from_doc "$DOC")
    echo "MyTool version $version"
    echo "Build: $(date)"
    exit 0
fi

# Normal operation
echo "Config: ${args[config]}"
```

### Mixing Flags and Options

```bash
#!/bin/bash
source parse_args.sh

DOC="BuildTool - Build automation

Usage:
    build [options] <targets>...

Options:
    -v,--verbose,Verbose output
    -q,--quiet,Quiet mode (only errors)
    -j,--jobs=,default=\"1\",Number of parallel jobs
    --clean,Clean before building
    --prod,Production build
    --dev,Development build
    --output-dir=,default=\"./dist\",Output directory

----
1.5.0
"

bach::parse_args_from_docstring "$DOC" "$@"
[ $? -ne 0 ] && exit $?

declare -n args="__ARGS"

# Validate mutually exclusive options
if [[ "${args[prod]}" == "true" ]] && [[ "${args[dev]}" == "true" ]]; then
    echo "Error: Cannot specify both --prod and --dev" >&2
    exit 1
fi

if [[ "${args[quiet]}" == "true" ]] && [[ "${args[verbose]}" == "true" ]]; then
    echo "Error: Cannot specify both --quiet and --verbose" >&2
    exit 1
fi

# Determine build mode
mode="default"
[[ "${args[prod]}" == "true" ]] && mode="production"
[[ "${args[dev]}" == "true" ]] && mode="development"

# Process
echo "Build mode: $mode"
echo "Jobs: ${args[jobs]}"
echo "Output: ${args[output-dir]}"

if [[ "${args[clean]}" == "true" ]]; then
    echo "Cleaning output directory..."
fi

for target in "${__PATH_ARGS[@]}"; do
    echo "Building target: $target"
done
```

### Dynamic Parsing with Unknown Options

```bash
#!/bin/bash
source parse_args.sh

# Use dynamic parsing when you don't know options ahead of time
bach::parse_args "$@"
declare -n args="__ARGS"

echo "Parsed options:"
for key in "${!args[@]}"; do
    echo "  $key = ${args[$key]}"
done

echo ""
echo "Path arguments:"
for arg in "${__PATH_ARGS[@]}"; do
    echo "  - $arg"
done
```

**Usage:**
```bash
./script.sh --custom-flag --some-option=value -abc target1 target2
# Output:
# Parsed options:
#   custom-flag = true
#   some-option = value
#   a = true
#   b = true
#   c = true
#
# Path arguments:
#   - target1
#   - target2
```

### Subcommand-Style Arguments

```bash
#!/bin/bash
source parse_args.sh

DOC="GitTool - Git helper

Usage:
    git-tool [command] [options]

Options:
    -v,--verbose,Verbose output
    -q,--quiet,Quiet mode

----
1.0.0
"

bach::parse_args_from_docstring "$DOC" "$@"
[ $? -ne 0 ] && exit $?

declare -n args="__ARGS"

# First path arg is the subcommand
if [[ ${#__PATH_ARGS[@]} -eq 0 ]]; then
    echo "Error: No command specified" >&2
    echo "Available commands: clone, pull, push, status" >&2
    exit 1
fi

command="${__PATH_ARGS[0]}"
shift  # Remove command from __PATH_ARGS

case "$command" in
    clone)
        echo "Cloning repository..."
        ;;
    pull)
        echo "Pulling changes..."
        ;;
    push)
        echo "Pushing changes..."
        ;;
    status)
        echo "Checking status..."
        ;;
    *)
        echo "Error: Unknown command: $command" >&2
        exit 1
        ;;
esac
```

### Default Values and Type Inference

```bash
#!/bin/bash
source parse_args.sh

DOC="ConfigApp

Usage:
    app [options]

Options:
    --host=,default=\"localhost\",Server hostname
    --port=,default=\"8080\",Server port
    --timeout=,default=\"30\",Request timeout in seconds
    -s,--ssl,Enable SSL
    --retry-count=,default=\"3\",Number of retries

----
1.0.0
"

bach::parse_args_from_docstring "$DOC" "$@"
declare -n args="__ARGS"

# Values use defaults if not specified
echo "Host: ${args[host]}"
echo "Port: ${args[port]}"
echo "Timeout: ${args[timeout]}"
echo "SSL: ${args[ssl]}"
echo "Retries: ${args[retry-count]}"

# Can use in conditionals
if [[ "${args[ssl]}" == "true" ]]; then
    protocol="https"
else
    protocol="http"
fi

echo "Connecting to: $protocol://${args[host]}:${args[port]}"
```

**Usage:**
```bash
./script.sh
# Uses all defaults

./script.sh --host=example.com --port=443 --ssl
# Overrides some values
```

### Handling Path Arguments

```bash
#!/bin/bash
source parse_args.sh

DOC="FileProcessor

Usage:
    process [options] <files>...

Options:
    -v,--verbose,Verbose mode
    --method=,default=\"copy\",Processing method

----
1.0.0
"

bach::parse_args_from_docstring "$DOC" "$@"
declare -n args="__ARGS"

# Iterate over path arguments
if [[ ${#__PATH_ARGS[@]} -eq 0 ]]; then
    echo "Error: No files specified" >&2
    exit 1
fi

echo "Processing ${#__PATH_ARGS[@]} files using method: ${args[method]}"

for file in "${__PATH_ARGS[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "Warning: File not found: $file" >&2
        continue
    fi

    [[ "${args[verbose]}" == "true" ]] && echo "Processing: $file"
    # Process file...
done
```

### Complex Validation

```bash
#!/bin/bash
source parse_args.sh

DOC="Validator

Usage:
    validator [options] <input>

Options:
    --min=,default=\"0\",Minimum value
    --max=,default=\"100\",Maximum value
    --type=,default=\"int\",Value type (int, float, string)
    -s,--strict,Strict validation

----
1.0.0
"

bach::parse_args_from_docstring "$DOC" "$@"
declare -n args="__ARGS"

# Validate numeric options
if ! [[ "${args[min]}" =~ ^[0-9]+$ ]]; then
    echo "Error: --min must be a number" >&2
    exit 1
fi

if ! [[ "${args[max]}" =~ ^[0-9]+$ ]]; then
    echo "Error: --max must be a number" >&2
    exit 1
fi

if [[ ${args[min]} -gt ${args[max]} ]]; then
    echo "Error: --min cannot be greater than --max" >&2
    exit 1
fi

# Validate enum option
case "${args[type]}" in
    int|float|string) ;;
    *)
        echo "Error: Invalid type: ${args[type]}" >&2
        echo "Valid types: int, float, string" >&2
        exit 1
        ;;
esac

echo "Validation config:"
echo "  Type: ${args[type]}"
echo "  Range: ${args[min]} - ${args[max]}"
echo "  Strict: ${args[strict]}"
```

## Docstring Format Specification

### Basic Structure

```
Title - Short Description

Long description of the command.
Can span multiple lines.

Usage:
    command [options] <args>

Options:
    -s,--short,Description of flag
    --long-option=,default="value",Description of option

----
1.0.0
```

### Option Line Format

**Flags (boolean):**
```
-f,--flag,Description text
```

**Options (with value):**
```
--option=,default="value",Description text
-o,--option=,default="value",Description text
```

### Version Line

Must come after the `----` separator:
```
----
1.0.0
```

## Best Practices

1. **Choose the right mode**: Use docstring-based for user-facing CLIs, simple mode for internal scripts
2. **Validate early**: Check required arguments immediately after parsing
3. **Provide defaults**: Always specify sensible defaults in docstrings
4. **Handle help/version**: Check return codes 2/3 for help/version display
5. **Use name references**: Access `__ARGS` via name reference for cleaner code
6. **Check path args**: Validate that required path arguments are present
7. **Error messages**: Provide clear error messages for invalid input

## See Also

- [docstring_helper.md](docstring_helper.md) - For building help documentation
- [log.md](log.md) - For logging parsed arguments
- [assert.md](assert.md) - For testing argument parsing
