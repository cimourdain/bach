# Parse Args Library Demo

The **parse_args library** provides sophisticated command-line argument parsing with support for named options, positional arguments, type validation, and default values.

## Capabilities

- **Multiple Option Formats**: Support for both short (-f) and long (--file) option forms
- **Type Validation**: Supports string, int, bool, and float types
- **Default Values**: Define default values for optional arguments
- **Positional Arguments**: Mix positional and named arguments
- **Error Handling**: Comprehensive error messages for parsing failures
- **Flexible Specifications**: Define argument requirements in simple DSL format

## Exposed Functions

### bach parse_args::config::set_parsed_args_global_var_name

**Purpose:** Configure the global variable name to store parsed arguments.

**Signature:**
```bash
bach parse_args::config::set_parsed_args_global_var_name <variable_name>
```

**Arguments:**
- `variable_name` - Name of the associative array to store parsed arguments

**Returns:**
- `0` on success
- `1` if variable name is empty

**Output:** Initializes the specified global variable as an associative array

### bach::parse_args

**Purpose:** Parse command-line arguments with validation and type checking.

**Signature:**
```bash
bach::parse_args <parsed_args_var> <arg_spec_array> [arguments...]
```

**Arguments:**
- `parsed_args_var` - Name of the associative array to store results
- `arg_spec_array` - Name of the array defining argument specifications
- `arguments...` - Command-line arguments to parse

**Returns:**
- `0` on successful parsing
- `1` on parsing error

**Output:** Populates the parsed_args associative array with argument values

### bach parse_args::from_spec

**Purpose:** Parse arguments based on an argument specification.

**Signature:**
```bash
bach parse_args::from_spec <arg_spec> [arguments...]
```

**Arguments:**
- `arg_spec` - Specification string defining expected arguments
- `arguments...` - Command-line arguments to parse

**Returns:**
- `0` on successful parsing
- `1` on parsing error

**Output:** Outputs parsed arguments in specified format

## Running the Demo

```bash
cd demo/parse_args
bash demo.sh
```

## Usage Examples

### Basic Argument Parsing

For sourcing in your local context, see [README.md](../../README.md).

```bash
#!/bin/bash
source bach.sh

# Set up the global variable for parsed args
declare -gA parsed_args
bach parse_args::config::set_parsed_args_global_var_name "parsed_args"

# Define argument specification
local -a arg_spec=(
    "name:string"
    "age:int"
    "active:bool"
)

# Parse command-line arguments
bach::parse_args parsed_args arg_spec --name "John" --age "30" --active

# Access parsed values
echo "Name: ${parsed_args[name]}"
echo "Age: ${parsed_args[age]}"
echo "Active: ${parsed_args[active]}"
```

### Using Short and Long Options

```bash
#!/bin/bash
source bach.sh

declare -gA args
bach parse_args::config::set_parsed_args_global_var_name "args"

# Example argument spec
local -a spec=(
    "file:string"
    "output:string"
    "verbose:bool"
)

# Both work identically:
bach::parse_args args spec --file input.txt --output result.txt --verbose
# OR
bach::parse_args args spec -f input.txt -o result.txt -v
```

### Positional and Named Arguments

```bash
#!/bin/bash
source bach.sh

declare -gA args
bach parse_args::config::set_parsed_args_global_var_name "args"

local -a spec=(
    "source:string"
    "destination:string"
    "compress:bool"
)

# Mix positional and named arguments
bach::parse_args args spec /home/user /backup --compress
```

### Type Validation

```bash
#!/bin/bash
source bach.sh

declare -gA args
bach parse_args::config::set_parsed_args_global_var_name "args"

# Specify types in the spec
local -a spec=(
    "name:string"        # Text input
    "count:int"          # Must be integer
    "enabled:bool"       # Boolean flag
    "threshold:float"    # Floating point
)

# Parser validates types
bach::parse_args args spec --name "test" --count 42 --threshold 3.14
```

### Default Values

```bash
#!/bin/bash
source bach.sh

declare -gA args
bach parse_args::config::set_parsed_args_global_var_name "args"

# Argument specs with defaults
local -a spec=(
    "output:string=default.txt"
    "threads:int=4"
    "verbose:bool=false"
)

# If options not provided, defaults are used
bash::parse_args args spec --output "custom.txt"
# args[output] = "custom.txt"
# args[threads] = "4"  (default)
# args[verbose] = "false" (default)
```

## Common Use Cases

### 1. Backup Script

```bash
#!/bin/bash
source bach.sh

declare -gA args
bach parse_args::config::set_parsed_args_global_var_name "args"

local -a spec=(
    "source:string"
    "destination:string"
    "compress:bool=false"
    "verbose:bool=false"
)

bach::parse_args args spec "$@"

echo "Backing up ${args[source]} to ${args[destination]}"
[[ "${args[compress]}" == "true" ]] && echo "Compression enabled"
[[ "${args[verbose]}" == "true" ]] && echo "Verbose mode"
```

### 2. Processing Script

```bash
#!/bin/bash
source bach.sh

declare -gA args
bach parse_args::config::set_parsed_args_global_var_name "args"

local -a spec=(
    "input:string"
    "output:string"
    "format:string=json"
    "workers:int=4"
)

bach::parse_args args spec "$@"

# Use parsed arguments
process_file "${args[input]}" "${args[output]}" \
    --format="${args[format]}" \
    --workers="${args[workers]}"
```

### 3. Configuration Management

```bash
#!/bin/bash
source bach.sh

declare -gA args
bach parse_args::config::set_parsed_args_global_var_name "args"

local -a spec=(
    "config:string"
    "profile:string=default"
    "debug:bool=false"
)

bach::parse_args args spec "$@"

load_config "${args[config]}" "${args[profile]}"
[[ "${args[debug]}" == "true" ]] && set -x
```

## Output Example

When you run the demo, you'll see output showing various parsing scenarios:

```
========================================
BACH Parse Args Library Demonstration
========================================

1. Basic Argument Parsing
=========================
Parsing: --name John --age 30 --active
Expected args: name, age, active

Parsed arguments:
  name = John
  age = 30
  active = true

2. Positional and Named Arguments
==================================
...
```

## Key Points

- **Flexibility**: Mix and match positional, short, and long options
- **Type Safe**: Validate argument types during parsing
- **Error Messages**: Clear error messages for invalid input
- **Defaults**: Reduce boilerplate with sensible defaults
- **Extensible**: Define custom argument specs for your needs
