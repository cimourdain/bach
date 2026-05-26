# parse_args.sh - Argument Parsing Library

A command-line argument parsing library storing flags, options and positional arguments in global variables.

## Overview

The parse_args library parses the arguments of a script without any declaration: `--flag`, `-f`, `-abc`, `--key=value` and positional arguments are recognized and stored in global arrays that you read after parsing. Parsing a new set of arguments resets the previous results.

## Features

- ✅ **Long flags**: `--verbose` sets `verbose` to `true`
- ✅ **Short flags**: `-v` sets `v` to `true`, `-abc` sets `a`, `b` and `c`
- ✅ **Valued options**: `--output=json` sets `output` to `json`
- ✅ **Positional arguments**: kept in order, in a dedicated array
- ✅ **Global state**: parsed values read from global arrays
- ✅ **Configurable variable name**: store the results in the variable of your choice

## Usage

The library relies on the `bach` function (for its internal logging). When used standalone, source `bach.sh` before `parse_args.sh`.

### Basic Examples

#### Flags, Options and Positional Arguments

Parse the arguments of the script, then read the options and the positional ("rest") arguments from the parsed arguments variable.

<!-- args: --verbose --output=json report.txt data.csv -->
::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
bach parse_args "$@"

declare -n options="${__BACH_PARSED_ARGS[options]}"
declare -n rest="${__BACH_PARSED_ARGS[rest]}"

echo "verbose: ${options[verbose]:-false}"
echo "output:  ${options[output]:-text}"
echo "files:   ${rest[*]}"
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # parse_args relies on the `bach` function
source my-libs/parse_args.sh
bach::parse_args "$@"

declare -n options="${__BACH_PARSED_ARGS[options]}"
declare -n rest="${__BACH_PARSED_ARGS[rest]}"

echo "verbose: ${options[verbose]:-false}"
echo "output:  ${options[output]:-text}"
echo "files:   ${rest[*]}"
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="cmd">$ ./my_script.sh --verbose --output=json report.txt data.csv</span>
verbose: true
output:  json
files:   report.txt data.csv</pre>

:::

#### Short and Merged Flags

Short flags (`-v`) and merged short flags (`-abc`) are all set to `true`.

<!-- args: -v -abc -->
::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
bach parse_args "$@"

declare -n options="${__BACH_PARSED_ARGS[options]}"
declare -n rest="${__BACH_PARSED_ARGS[rest]}"

# Associative arrays are not ordered: sort the keys to get a stable output
for key in $(printf '%s\n' "${!options[@]}" | sort); do
    echo "-${key} = ${options[$key]}"
done
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # parse_args relies on the `bach` function
source my-libs/parse_args.sh
bach::parse_args "$@"

declare -n options="${__BACH_PARSED_ARGS[options]}"
declare -n rest="${__BACH_PARSED_ARGS[rest]}"

# Associative arrays are not ordered: sort the keys to get a stable output
for key in $(printf '%s\n' "${!options[@]}" | sort); do
    echo "-${key} = ${options[$key]}"
done
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="cmd">$ ./my_script.sh -v -abc</span>
-a = true
-b = true
-c = true
-v = true</pre>

:::

#### Positional Arguments

Everything that is neither a flag nor an option is a positional argument, kept in order (an argument containing spaces stays one argument).

<!-- args: "my file.txt" other.txt -->
::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
bach parse_args "$@"

declare -n options="${__BACH_PARSED_ARGS[options]}"
declare -n rest="${__BACH_PARSED_ARGS[rest]}"

echo "Number of arguments: ${#rest[@]}"
for argument in "${rest[@]}"; do
    echo "- ${argument}"
done
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # parse_args relies on the `bach` function
source my-libs/parse_args.sh
bach::parse_args "$@"

declare -n options="${__BACH_PARSED_ARGS[options]}"
declare -n rest="${__BACH_PARSED_ARGS[rest]}"

echo "Number of arguments: ${#rest[@]}"
for argument in "${rest[@]}"; do
    echo "- ${argument}"
done
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="cmd">$ ./my_script.sh 'my file.txt' other.txt</span>
Number of arguments: 2
- my file.txt
- other.txt</pre>

:::

### Advanced Examples

#### Subcommand-Style Script

The first positional argument is used as the subcommand, the options apply to it.

<!-- args: build --force -->
::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
main() {
    bach parse_args "$@"

    declare -n options="${__BACH_PARSED_ARGS[options]}"
    declare -n rest="${__BACH_PARSED_ARGS[rest]}"

    local subcommand="${rest[0]:-}"
    if [[ -z "$subcommand" ]]; then
        echo "Usage: script.sh <build|test> [--force]" >&2
        return 1
    fi

    case "$subcommand" in
        build) echo "Building (force: ${options[force]:-false})" ;;
        test)  echo "Testing (force: ${options[force]:-false})" ;;
        *)     echo "Unknown subcommand: ${subcommand}" >&2; return 1 ;;
    esac
}

main "$@"
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # parse_args relies on the `bach` function
source my-libs/parse_args.sh
main() {
    bach::parse_args "$@"

    declare -n options="${__BACH_PARSED_ARGS[options]}"
    declare -n rest="${__BACH_PARSED_ARGS[rest]}"

    local subcommand="${rest[0]:-}"
    if [[ -z "$subcommand" ]]; then
        echo "Usage: script.sh <build|test> [--force]" >&2
        return 1
    fi

    case "$subcommand" in
        build) echo "Building (force: ${options[force]:-false})" ;;
        test)  echo "Testing (force: ${options[force]:-false})" ;;
        *)     echo "Unknown subcommand: ${subcommand}" >&2; return 1 ;;
    esac
}

main "$@"
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="cmd">$ ./my_script.sh build --force</span>
Building (force: true)</pre>

:::

#### Parsing Several Times

Each call to `bach::parse_args` resets the parsed arguments, the results of a previous call are not kept.

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
bach parse_args --first one
declare -n options="${__BACH_PARSED_ARGS[options]}"
declare -n rest="${__BACH_PARSED_ARGS[rest]}"
echo "after first call:  options=${!options[*]} rest=${rest[*]}"

bach parse_args --second two
echo "after second call: options=${!options[*]} rest=${rest[*]}"
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # parse_args relies on the `bach` function
source my-libs/parse_args.sh
bach::parse_args --first one
declare -n options="${__BACH_PARSED_ARGS[options]}"
declare -n rest="${__BACH_PARSED_ARGS[rest]}"
echo "after first call:  options=${!options[*]} rest=${rest[*]}"

bach::parse_args --second two
echo "after second call: options=${!options[*]} rest=${rest[*]}"
```

:::

::: details Expected output

<pre class="ansi" v-pre>after first call:  options=first rest=one
after second call: options=second rest=two</pre>

:::

#### Custom Parsed Arguments Variable

By default the parsed arguments are stored in `__BACH_PARSED_ARGS`. Use `bach::parse_args::config::set_parsed_args_global_var_name` to choose another name.

<!-- args: --dry-run production -->
::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
bach parse_args::config::set_parsed_args_global_var_name "CLI_ARGS"
bach parse_args "$@"

declare -n options="${CLI_ARGS[options]}"
declare -n rest="${CLI_ARGS[rest]}"

echo "dry-run: ${options[dry-run]:-false}"
echo "target:  ${rest[0]}"
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # parse_args relies on the `bach` function
source my-libs/parse_args.sh
bach::parse_args::config::set_parsed_args_global_var_name "CLI_ARGS"
bach::parse_args "$@"

declare -n options="${CLI_ARGS[options]}"
declare -n rest="${CLI_ARGS[rest]}"

echo "dry-run: ${options[dry-run]:-false}"
echo "target:  ${rest[0]}"
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="cmd">$ ./my_script.sh --dry-run production</span>
dry-run: true
target:  production</pre>

:::

#### Inspecting the Parsed Arguments

`bach::parse_args::debug_parsed` logs the content of the parsed arguments at debug level (set `LOG_LEVEL=debug` to see it).

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
export LOG_LEVEL="debug"
bach parse_args --verbose --output=json file.txt
bach parse_args::debug_parsed
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # parse_args relies on the `bach` function
source my-libs/parse_args.sh
export LOG_LEVEL="debug"
bach::parse_args --verbose --output=json file.txt
bach::parse_args::debug_parsed
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="c-blue">[2026-01-01 12:00:00][DEBUG][./lib/bach/parse_args.sh:48 bach::parse_args::config::set_parsed_args_global_var_name]Parsed args global variable name set to __BACH_PARSED_ARGS</span>
<span class="c-blue">[2026-01-01 12:00:00][DEBUG][./lib/bach/parse_args.sh:129 bach::parse_args::debug_parsed]Inspect keys of parsed args global variable __BACH_PARSED_ARGS.</span>
<span class="c-blue">[2026-01-01 12:00:00][DEBUG][./lib/bach/parse_args.sh:130 bach::parse_args::debug_parsed][__BACH_PARSED_ARGS][options]: __BACH_PARSED_ARGS_options</span>
<span class="c-blue">[2026-01-01 12:00:00][DEBUG][./lib/bach/parse_args.sh:130 bach::parse_args::debug_parsed][__BACH_PARSED_ARGS][rest]: __BACH_PARSED_ARGS_rest</span>
<span class="c-blue">[2026-01-01 12:00:00][DEBUG][./lib/bach/parse_args.sh:132 bach::parse_args::debug_parsed]Get parsed options from global variable: __BACH_PARSED_ARGS_options</span>
<span class="c-blue">[2026-01-01 12:00:00][DEBUG][./lib/bach/parse_args.sh:133 bach::parse_args::debug_parsed][__BACH_PARSED_ARGS_options][verbose]: true</span>
<span class="c-blue">[2026-01-01 12:00:00][DEBUG][./lib/bach/parse_args.sh:133 bach::parse_args::debug_parsed][__BACH_PARSED_ARGS_options][output]: json</span>
<span class="c-blue">[2026-01-01 12:00:00][DEBUG][./lib/bach/parse_args.sh:135 bach::parse_args::debug_parsed]Get parsed rest arguments from global variable: __BACH_PARSED_ARGS_rest</span>
<span class="c-blue">[2026-01-01 12:00:00][DEBUG][./lib/bach/parse_args.sh:136 bach::parse_args::debug_parsed][__BACH_PARSED_ARGS_rest][0]: file.txt</span></pre>

:::

## Parsed Arguments Variables

Parsing stores its results in a global associative array (default name: `__BACH_PARSED_ARGS`) referencing two other variables:

| Key | Variable | Content |
|---|---|---|
| `options` | `<name>_options` (associative array) | Flags and options: `options[verbose]=true`, `options[output]=json` |
| `rest` | `<name>_rest` (indexed array) | Positional arguments, in order |

Read them through name references:

```bash
declare -n options="${__BACH_PARSED_ARGS[options]}"
declare -n rest="${__BACH_PARSED_ARGS[rest]}"
```

## Parsing Rules

| Argument | Result |
|---|---|
| `--flag` | `options[flag]=true` |
| `-f` | `options[f]=true` |
| `-abc` | `options[a]`, `options[b]` and `options[c]` are `true` |
| `--key=value` | `options[key]=value` (the value may contain `=`) |
| anything else | appended to the positional arguments |

## API Reference

### bach::parse_args

Parse arguments without specification.

**Signature:**
```bash
bach::parse_args "$@"
```

**Parameters:**
- `$@`: Command-line arguments to parse

**Returns:** `0` always

**Side Effects:**
- Resets then fills the options and positional arguments of the parsed arguments variable

### bach::parse_args::config::set_parsed_args_global_var_name

Set the name of the global variable receiving the parsed arguments.

**Signature:**
```bash
bach::parse_args::config::set_parsed_args_global_var_name "$var_name"
```

**Parameters:**
- `$1` (var_name): Name of the global associative array (default: `__BACH_PARSED_ARGS`)

**Returns:** `0` on success, `1` if the name is empty

### bach::parse_args::debug_parsed

Log the content of the parsed arguments variables at debug level.

**Signature:**
```bash
bach::parse_args::debug_parsed
```

**Returns:** `0` always

### bach::parse_args::from_spec

Parse arguments against an arguments specification (docstring). **Work in progress**: the specification is not handled yet, see the [Roadmap](#roadmap).

## Best Practices

1. Call `bach::parse_args "$@"` once, at the beginning of your script or `main` function
2. Read the options with a default value: `${options[output]:-text}`
3. Validate the positional arguments you need right after parsing
4. Use `LOG_LEVEL=debug` with `bach::parse_args::debug_parsed` when an argument is not parsed as expected

## Roadmap

- [ ] Parse arguments against a specification (docstring): validation, default values, automatic help and version
- [ ] Support `--key value` options (value in the next argument)
- [ ] Support the `--` end-of-options separator
- [ ] Provide helpers checking if help or version is requested

## See Also

- [docstring_helper.md](docstring_helper.md) - Documentation (usage, help, version) generation
- [log.md](log.md) - Logging, used internally by this library
