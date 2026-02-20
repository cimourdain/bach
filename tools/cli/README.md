# CLI - Command Line Interface Tool

A flexible bash command routing system that executes scripts based on directory structure with automatic argument parsing and documentation generation.

## Features

- **Directory-based routing**: Execute scripts by navigating through folder structure
- **Automatic fallback**: Falls back to `main.sh` in directories when no specific script is named
- **Option parsing**: Supports short flags (-a), long flags (--all), and valued options (--value=x)
- **Self-documenting**: Auto-generates help from docstrings and discovers subcommands
- **Self-executable scripts**: All scripts can be executed directly or via the router
- **Exclusion support**: Configure files/patterns to exclude from execution
- **Layered options**: Each script level can define and parse its own options

## Demo

The project includes a demo script that showcases all major features with example commands.

### Running the Demo

Execute the demo script to see the command processor in action:

```bash
./demo.sh
```

The demo will show examples of:
- Help and version flags
- Basic command execution
- Nested command routing
- Fallback to main.sh handlers
- Options parsing (short flags, long flags, valued options)
- Direct script execution
- Exclusion behavior for protected files

Each example includes the command being run and its output, providing a complete overview of the system's capabilities.


## Demos in details

### Subcommands executions based on directory path

Execute the root `main.sh` using file/directory path elements to reach subcommands of the `cmd/` folder.

```bash
# Execute cmd/cmd1.sh
./main.sh cmd1

# Execute cmd/sone/foo.sh
./main.sh sone foo

# Execute cmd/stwo/ssx/yaya.sh
./main.sh stwo ssx yaya
```

#### Fallback

When the provided path is a directory but no filename is explicitly set, execution will fallback on the main.sh of the directory (if exists).

```shell
# Fallback to cmd/main.sh
./main.sh

# Fallback to cmd/sone/main.sh
./main.sh sone

# FAIL because cmd/stwo do not have a main.sh
./main.sh stwo
```

### Options

Options can be expressed as flags or valued options.

```bash
# Short flags
./main.sh <cmd> -a -b
./main.sh <cmd> -ab  # Merged short flags

# Long flags
./main.sh <cmd> --all --bizz

# Valued options
./main.sh <cmd> --my-value="test123"

# Combined
./main.sh <cmd> -ab --my-value="test" target1
```

#### Help and Version

Help and version options are automatically handled in scripts. No need to explicitly define them into the commands documentation.

```bash
# Show help of ./main.sh
./main.sh --help
# Show help of cmd/sone/foo.sh
./main.sh sone foo -h

# Show version of ./main.sh
./main.sh --version
# Show version of cmd/stwo/ssx/yaya.sh
./main.sh stwo ssx yaya --version
```

### Scripts are self-executable

In order to improve shareability commands scripts are self-executables.

```bash
# Same result as: ./main.sh sone foo
./cmd/sone/foo.sh

# Same result as: ./main.sh stwo ssx yaya
./cmd/stwo/ssx/yaya.sh
```

## Usage

### Boostrap a new project

#### Client directory initialization

```shell
# Create a new directory
$ mkdir mycli
$ cp mycli

# TODO: copy the lib directory and its content

# create the directory that will contains your subcommands (use another name if required)
$ mkdir cmd
```

#### Main script entrypoint

Copy the `main.sh` script at the root of your project.

Optionally update the following.

```bash
# ...
main() {
    # ...

    # Update if your commands scripts are located elsewhere
    local subcommand_dir="${script_dir}/cmd"

    # Update if you need to exclude other files patterns from subcommands definition
    # eg: the following setup ignore all const.sh and statics.sh scripts, they will not be considered as subcommands.
    local exclude_list="const.sh,statics.sh"

    # Update the docstring if required, see docstring section below.
    local doc_string="
My new client

A flexible command routing system that executes scripts based on directory structure.

Usage:
    my-custom-cmd
    other-custom-cmd

Options:
    -a|--all|default=false|Apply to all
    --config=|default=\"default.conf\"|Configuration file to use
----
1.0.0
"
}
# ...
```

#### Commands files

Create commands files with the folder structure you want using the following template.

```bash
# eg: cmd/../my_command.sh
#!/bin/bash

main() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # TODO: update to the relative path of lib directory
    local lib_dir="$(cd "${script_dir}/../.." && pwd)/lib"

    # Source required libraries
    source "${lib_dir}/parse_args.sh"
    source "${lib_dir}/doc_helper.sh"

    local doc_string="
My command description

A longer description if required.

Usage:
    bar [options]

Options:
    -q|--quiet||Suppress output
    -d|--dry-run||Show what would be done without executing
    --config=|default=\"default.conf\"|Configuration file to use

----
1.5.0
"

    # Parse arguments (parse_args handles --help and --version internally)
    parse_args "$doc_string" "" "" "$@"

    case $? in
        0) ;;  # Continue execution
        2|3) return 0 ;;  # Help or version was handled
        *) return 1 ;;  # Parse error
    esac

    # Access parsed options
    declare -n args="${__ARGS_VAR_NAME}"

    if [[ "${args[quiet]}" != "true" ]]; then
        printf '%s\n' "=== BAR Command Executed ===" >&2
        printf '%s\n' "Config file: ${args[config]}" >&2

        if [[ "${args[dry-run]}" == "true" ]]; then
            printf '%s\n' "[DRY RUN] Would execute bar operations" >&2
        else
            printf '%s\n' "Executing bar operations..." >&2
        fi
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```


### Script Template

Every command script should follow this template:

```bash
#!/bin/bash

main() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local lib_dir="$(cd "${script_dir}/../.." && pwd)/lib"  # Adjust path depth as needed

    # Source required libraries
    source "${lib_dir}/parse_args.sh"
    source "${lib_dir}/doc_helper.sh"

    local doc_string="
Command Name - Brief Description

Longer description of what this command does.

Usage:
    command [options] [<args>...]

Options:
    -s|--short||Short flag description
    -l|--long|default=false|Long flag with explicit default
    --valued-option=|default=\"default_value\"|Option requiring a value
----
1.0.0
"

    # Parse arguments (parse_args handles --help and --version internally)
    parse_args "$doc_string" "" "" "$@"

    case $? in
        0) ;;  # Continue execution
        2|3) return 0 ;;  # Help or version was handled
        *) return 1 ;;  # Parse error
    esac

    # Access parsed options from global array
    declare -n args="${__ARGS_VAR_NAME}"

    # Your command logic here
    echo "Executing command..."
    echo "Flag --short: ${args[short]}"
    echo "Flag --long: ${args[long]}"
    echo "Option --valued-option: ${args[valued-option]}"

    # Access remaining path arguments
    if [[ ${#__PATH_ARGS[@]} -gt 0 ]]; then
        echo "Arguments: ${__PATH_ARGS[*]}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

**For scripts with subcommands** (e.g., `main.sh` in directories):

```bash
#!/bin/bash

main() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local lib_dir="$(cd "${script_dir}/../.." && pwd)/lib"

    source "${lib_dir}/parse_args.sh"
    source "${lib_dir}/doc_helper.sh"

    # Exclusion list for this directory
    local exclude_list="const.sh,statics.sh"

    local doc_string="
Command Group Name

Description of this command group.

Usage:
    group [options]
    group <subcommand> [options]
----
1.0.0
"

    # Parse arguments with subcommand discovery
    parse_args "$doc_string" "$script_dir" "$exclude_list" "$@"

    case $? in
        0) ;;  # Continue execution
        2|3) return 0 ;;  # Help or version was handled
        *) return 1 ;;  # Parse error
    esac

    # Command logic when called without subcommands
    echo "Default handler for command group"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Documentation Format

Documentation strings must follow this format:

```
(DESCRIPTION - multiline allowed)

[Usage:
    (CUSTOM_CMD or path to this script)
    ...
]

[Options:
    (FLAG_FORMAT or OPTION_FORMAT)
    ...
]
----
(X.X.X - semver version)
```

**Flag Format:**
```
-s|--long-name|[default=true/false]|Description text
```

**Option Format (requires value):**
```
--option-name=|[default="value"]|Description text
```

**Note:** `--help` (-h) and `--version` (-v) are automatically injected into all scripts and don't need to be defined in the Options section.

## Configuration

### Exclude Files from Execution

Edit `main.sh` or individual command scripts to add patterns to the exclusion list:

```bash
local exclude_list="const.sh,statics.sh,*.tmp,backup_*"
```

Exclusions can be:
- Exact filenames: `const.sh`
- Patterns: `*.tmp`, `backup_*`
- Always excluded: `main.sh`, `*.sh~`, `*.swp`

### Custom Global Variable Name

By default, parsed options are stored in `__ARGS`. To use a custom name:

```bash
export __ARGS_VAR_NAME="MY_CUSTOM_ARGS"
```

## Important Notes

### parse_args Return Codes

`parse_args` handles --help and --version internally and returns distinct codes:

- **0**: Parsing successful, continue execution
- **1**: Parse error occurred
- **2**: Help was requested and printed
- **3**: Version was requested and printed

Your main function should handle these with a case statement:

```bash
case $? in
    0) ;;  # Continue execution
    2|3) return 0 ;;  # Help or version was handled
    *) return 1 ;;  # Parse error
esac
```

### Variable Naming Convention

- **Local variables**: Use lowercase (e.g., `script_dir`, `lib_dir`, `exclude_list`)
- **Global arrays**: Use uppercase with underscores (e.g., `__ARGS`, `__PATH_ARGS`)
- All variables in main() should be declared as `local` to avoid polluting the global namespace

### Automatic Help/Version Injection

You don't need to explicitly define `-h|--help` or `-v|--version` in your doc_string Options section. These are automatically injected by parse_args and will appear in the help output.

## How It Works

### Argument Flow

1. **main.sh** receives all arguments
2. Parses only its own options (--help, --version)
3. Unknown options and path arguments are passed to router
4. **router.sh** navigates directory structure based on path args
5. Target script receives remaining args and parses its own options

### Option Parsing Strategy

- Each script level only parses options it recognizes
- Unknown options are passed through to the next level
- This allows layered option handling across command hierarchy

### Path Resolution

Given: `./main.sh sone foo -ab target`

1. Start at `cmd/` directory
2. Look for `sone` → found directory, navigate to `cmd/sone/`
3. Look for `foo` → found `foo.sh`, execute it with args: `-ab target`
4. `foo.sh` parses `-ab` and stores `target` in `__PATH_ARGS`

## Global Variables

- `__ARGS`: Associative array containing parsed options
- `__PATH_ARGS`: Regular array containing non-option arguments
- `__ARGS_VAR_NAME`: Name of the global args variable (default: `__ARGS`)

## Library Functions

### parse_args.sh

- `parse_args <doc_string> <subcommand_dir> <exclude_list> <args...>`: Parse arguments and handle help/version
  - Returns: 0 (success), 1 (error), 2 (help handled), 3 (version handled)
  - `subcommand_dir`: Directory for subcommand discovery (use `""` for leaf commands)
  - `exclude_list`: Comma-separated exclusions (use `""` if not needed)
- `is_help_requested`: Check if --help flag is set (rarely needed, parse_args handles this)
- `is_version_requested`: Check if --version flag is set (rarely needed, parse_args handles this)

### doc_helper.sh

- `build_documentation <doc> <dir> <excludes>`: Build complete documentation with subcommands
- `print_doc <doc>`: Print documentation string
- `print_version <doc>`: Print version from documentation
- `get_version_from_doc <doc>`: Extract version string

### router.sh

- `route_to_subcommand <base_dir> <excludes> <path_args...>`: Route and execute script
- `get_subcommand_dir <base_dir> <path_args...>`: Get directory for subcommand lookup

## Testing

The project includes a comprehensive test suite with 118 tests across all library functions.

### Running All Tests

Execute all tests with the test runner:

```bash
./tests/main.sh
```

This will run all test files matching the pattern `tests/**/*.test.sh` and display:
- Individual test results for each suite
- Per-suite summary (tests passed/failed)
- Overall summary across all test suites

### Running Specific Tests

You can provide a custom pattern to run specific tests:

```bash
# Run a single test file
./tests/main.sh "tests/lib/log.test.sh"

# Run tests matching a pattern
./tests/main.sh "tests/lib/*args.test.sh"

# Run all tests in a specific directory
./tests/main.sh "tests/lib/*.test.sh"
```

### Running Tests Directly

Individual test files can also be executed directly:

```bash
./tests/lib/parse_args.test.sh
./tests/lib/doc_helper.test.sh
./tests/lib/log.test.sh
./tests/lib/router.test.sh
```

### Test Coverage

- **parse_args.test.sh** (32 tests): Argument parsing, flags, options, help/version injection
- **doc_helper.test.sh** (22 tests): Documentation generation, subcommand discovery
- **log.test.sh** (49 tests): Logging library with level filtering and colored output
- **router.test.sh** (15 tests): Command routing, directory navigation, exclusions

## Limitations

- Scripts must have `.sh` extension or no extension
- Only one level of subcommands shown in auto-generated help
- Option names must use alphanumeric characters and hyphens only
- Short flags must be single letters

## License

This is example code created for demonstration purposes.
