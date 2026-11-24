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
- ✅ **docopt specification**: validate the arguments against a [docopt](http://docopt.org) usage with `bach::parse_args::from_spec`

## Usage Examples

The library relies on the `bach` function (for its internal logging). When used standalone, source `bach.sh` before `parse_args.sh`.

### Flags, Options and Positional Arguments

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

### Short and Merged Flags

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

### Positional Arguments

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

### Parse from specification

`bach::parse_args::from_spec` wraps `bach::parse_args` and matches the parsed arguments against a [docopt specification](#specification-syntax): the usage patterns tell which commands, options and arguments are expected, and the values are stored under the names used in the specification. When the arguments do not match the usage, an error is logged and the function returns `1`.

The example below also shows:

- **Allowed values**: `[choices: A, B]` in the description of an option, or of an argument in an `Arguments:` section, restricts its values; a value not allowed is refused and the function returns `1`.
- **Default values**: `[default: 10]` in the description of an option with an argument.
- **Names of the result**: leading dashes are removed, and when an option is described with both syntaxes (`-q --quiet`) the long name is used even if the arguments use the short one: `-q` is stored as `quiet`.

<!-- args: ship Guardian move 10 50 -q --flag=UK -->
::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
spec='Naval Fate.

Usage:
  naval_fate ship <name> move <x> <y> [--speed=<kn>] [--flag=<country>] [-q]
  naval_fate mine (set|remove) <x> <y> [--moored|--drifting]

Options:
  -q --quiet        Do not print anything.
  --speed=<kn>      Speed in knots [default: 10].
  --flag=<country>  Flag of the ship [choices: FR, UK, US] [default: FR]
  --moored          Moored (anchored) mine.
  --drifting        Drifting mine.

Arguments:
  <name>  Name of the ship [choices: Guardian, Voyager]
'
bach parse_args::from_spec "$spec" "$@" || exit 1

declare -n options="${__BACH_PARSED_ARGS[options]}"
for key in $(printf '%s\n' "${!options[@]}" | sort); do
    echo "${key} = ${options[$key]}"
done
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # parse_args relies on the `bach` function
source my-libs/parse_args.sh
spec='Naval Fate.

Usage:
  naval_fate ship <name> move <x> <y> [--speed=<kn>] [--flag=<country>] [-q]
  naval_fate mine (set|remove) <x> <y> [--moored|--drifting]

Options:
  -q --quiet        Do not print anything.
  --speed=<kn>      Speed in knots [default: 10].
  --flag=<country>  Flag of the ship [choices: FR, UK, US] [default: FR]
  --moored          Moored (anchored) mine.
  --drifting        Drifting mine.

Arguments:
  <name>  Name of the ship [choices: Guardian, Voyager]
'
bach::parse_args::from_spec "$spec" "$@" || exit 1

declare -n options="${__BACH_PARSED_ARGS[options]}"
for key in $(printf '%s\n' "${!options[@]}" | sort); do
    echo "${key} = ${options[$key]}"
done
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="cmd">$ ./my_script.sh ship Guardian move 10 50 -q --flag=UK</span>
drifting = false
flag = UK
mine = false
moored = false
move = true
&lt;name&gt; = Guardian
quiet = true
remove = false
set = false
ship = true
speed = 10
&lt;x&gt; = 10
&lt;y&gt; = 50</pre>

:::

### Separator `--` with a Specification

`--` ends the options: the following arguments are not parsed and are always stored in the `rest` key of the parsed arguments (`--` itself is removed). With a specification, they are matched against the usage only if it has a `[--]` element (the `--` is then stored under the key `--` and the arguments as positionals); otherwise they are not checked and stay in `rest`.

<!-- args: -q -- extra_1 extra_2 -->
::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
export LOG_LEVEL="info"
show() {
    declare -n options="${__BACH_PARSED_ARGS[options]}"
    declare -n rest="${__BACH_PARSED_ARGS[rest]}"
    for key in $(printf '%s\n' "${!options[@]}" | sort); do
        echo "options[${key}] = ${options[$key]}"
    done
    echo "rest = ${rest[*]}"
}

bach log --info "bach::parse_args without specification:"
bach parse_args "$@"
show

bach log --info "from_spec, usage without [--]:"
bach parse_args::from_spec "Usage: prog [-q]" "$@"
show

bach log --info "from_spec, usage with [--]:"
bach parse_args::from_spec "Usage: prog [-q] [--] <file>..." "$@"
show
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # parse_args relies on the `bach` function
source my-libs/parse_args.sh
export LOG_LEVEL="info"
show() {
    declare -n options="${__BACH_PARSED_ARGS[options]}"
    declare -n rest="${__BACH_PARSED_ARGS[rest]}"
    for key in $(printf '%s\n' "${!options[@]}" | sort); do
        echo "options[${key}] = ${options[$key]}"
    done
    echo "rest = ${rest[*]}"
}

bach log --info "bach::parse_args without specification:"
bach::parse_args "$@"
show

bach log --info "from_spec, usage without [--]:"
bach::parse_args::from_spec "Usage: prog [-q]" "$@"
show

bach log --info "from_spec, usage with [--]:"
bach::parse_args::from_spec "Usage: prog [-q] [--] <file>..." "$@"
show
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="cmd">$ ./my_script.sh -q -- extra_1 extra_2</span>
<span class="c-green">[2026-01-01 12:00:00][INFO][/home/user/project/my_script.sh:14 main]bach::parse_args without specification:</span>
options[q] = true
rest = extra_1 extra_2
<span class="c-green">[2026-01-01 12:00:00][INFO][/home/user/project/my_script.sh:18 main]from_spec, usage without [--]:</span>
options[q] = true
rest = extra_1 extra_2
<span class="c-green">[2026-01-01 12:00:00][INFO][/home/user/project/my_script.sh:22 main]from_spec, usage with [--]:</span>
options[--] = true
options[&lt;file&gt;] = extra_1 extra_2
options[&lt;file&gt;,#] = 2
options[&lt;file&gt;,0] = extra_1
options[&lt;file&gt;,1] = extra_2
options[q] = true
rest = extra_1 extra_2</pre>

:::

### Help (`-h`/`--help`)

`-h` and `--help` are always recognised, even if the specification does not describe them: the specification is printed and the execution is aborted.

<!-- args: --help -->
::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
spec='Usage: prog [--force] <path>

Options:
  --force  Overwrite the destination.
'
bach parse_args::from_spec "$spec" "$@" || exit 1
echo "Not reached when help is requested"

declare -n options="${__BACH_PARSED_ARGS[options]}"
for key in $(printf '%s\n' "${!options[@]}" | sort); do
    echo "${key} = ${options[$key]}"
done
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # parse_args relies on the `bach` function
source my-libs/parse_args.sh
spec='Usage: prog [--force] <path>

Options:
  --force  Overwrite the destination.
'
bach::parse_args::from_spec "$spec" "$@" || exit 1
echo "Not reached when help is requested"

declare -n options="${__BACH_PARSED_ARGS[options]}"
for key in $(printf '%s\n' "${!options[@]}" | sort); do
    echo "${key} = ${options[$key]}"
done
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="cmd">$ ./my_script.sh --help</span>
Usage: prog [--force] &lt;path&gt;

Options:
  --force  Overwrite the destination.</pre>

:::

### Version (`-v`/`--version`)

`-v` and `--version` are always recognised: the version of the specification is printed and the execution is aborted. The version is the text following `Version:` (at the beginning of a line) in the specification. When the specification does not state a version, an error is logged and the execution is aborted with status `1`.

<!-- args: --version -->
::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
export LOG_LEVEL="info"
spec_without_version='Usage: prog [--force] <path>

Options:
  --force  Overwrite the destination.
'
spec_with_version='Usage: prog [--force] <path>

Options:
  --force  Overwrite the destination.

Version: 1.4.2
'

# The execution is aborted when the version is requested: use subshells to run both
bach log --info "Specification without version:"
(bach parse_args::from_spec "$spec_without_version" "$@")
bach log --info "Specification with version:"
(bach parse_args::from_spec "$spec_with_version" "$@")
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # parse_args relies on the `bach` function
source my-libs/parse_args.sh
export LOG_LEVEL="info"
spec_without_version='Usage: prog [--force] <path>

Options:
  --force  Overwrite the destination.
'
spec_with_version='Usage: prog [--force] <path>

Options:
  --force  Overwrite the destination.

Version: 1.4.2
'

# The execution is aborted when the version is requested: use subshells to run both
bach log --info "Specification without version:"
(bach::parse_args::from_spec "$spec_without_version" "$@")
bach log --info "Specification with version:"
(bach::parse_args::from_spec "$spec_with_version" "$@")
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="cmd">$ ./my_script.sh --version</span>
<span class="c-green">[2026-01-01 12:00:00][INFO][/home/user/project/my_script.sh:19 main]Specification without version:</span>
<span class="c-red">[2026-01-01 12:00:00][ERROR][./lib/bach/parse_args.sh:979 bach::parse_args::__private::handle_help_and_version]The specification does not state a version (add a 'Version: &lt;version&gt;' line)</span>
<span class="c-green">[2026-01-01 12:00:00][INFO][/home/user/project/my_script.sh:21 main]Specification with version:</span>
1.4.2</pre>

:::

### Custom Parsed Arguments Variable

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

### Inspecting the Parsed Arguments

`bach::parse_args::debug_parsed` returns the content of the parsed arguments as a string, formatted as `json` (default), `markdown` or `ascii` with `--format=<format>`. Options are listed under their name and the rest arguments under `rest[0]`, `rest[1]`...

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
export LOG_LEVEL="info"
bach parse_args --verbose --output=json file.txt
bach log --info "Format json (default):"
bach parse_args::debug_parsed
bach log --info "Format markdown:"
bach parse_args::debug_parsed --format=markdown
bach log --info "Format ascii:"
bach parse_args::debug_parsed --format=ascii
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # parse_args relies on the `bach` function
source my-libs/parse_args.sh
export LOG_LEVEL="info"
bach::parse_args --verbose --output=json file.txt
bach log --info "Format json (default):"
bach::parse_args::debug_parsed
bach log --info "Format markdown:"
bach::parse_args::debug_parsed --format=markdown
bach log --info "Format ascii:"
bach::parse_args::debug_parsed --format=ascii
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="c-green">[2026-01-01 12:00:00][INFO][/home/user/project/my_script.sh:6 main]Format json (default):</span>
{
  "output": "json",
  "rest[0]": "file.txt",
  "verbose": "true"
}
<span class="c-green">[2026-01-01 12:00:00][INFO][/home/user/project/my_script.sh:8 main]Format markdown:</span>
| Key | Value |
| --- | --- |
| output | json |
| rest[0] | file.txt |
| verbose | true |
<span class="c-green">[2026-01-01 12:00:00][INFO][/home/user/project/my_script.sh:10 main]Format ascii:</span>
+---------+----------+
| Key     | Value    |
+---------+----------+
| output  | json     |
| rest[0] | file.txt |
| verbose | true     |
+---------+----------+</pre>

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
| `--` | Stops the parsing: the following arguments are appended as they are to the positional arguments (`--` itself is removed) |
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

Get the content of the parsed arguments variables as a string. The conversion is done by the [bash_utils](bash_utils.md) library (`bach::bash_utils::assoc_array::to_<format>`), loaded when needed.

**Signature:**
```bash
bach::parse_args::debug_parsed [--format=json|markdown|ascii]
```

**Parameters:**
- `--format=<format>`: Output format (default: `json`)

**Output:** The formatted string. Options are listed under their name and the rest arguments under `rest[0]`, `rest[1]`...

**Returns:** `0` on success, `1` on invalid format, or when the conversion function is not declared (a warning is logged and nothing is printed)

### bach::parse_args::from_spec

Parse arguments against a docopt specification.

**Signature:**
```bash
bach::parse_args::from_spec "$spec" "$@"
```

**Parameters:**
- `$1` (spec): The [docopt specification](#specification-syntax), as a string or the path of a file
- `$@`: Command-line arguments to parse (without the program name)

**Returns:** `0` on success, `1` if the specification is invalid or the arguments do not match the usage (the error is logged and the parsed arguments are left empty). With `-h`/`--help` or `-v`/`--version`, the specification or its version is printed and the shell exits (see [Help and Version](#help-and-version))

**Side Effects:**
- Resets then fills the parsed arguments variable: `options[KEY]` holds the value of every element of the specification (see [Result](#result)) and `rest` the positional arguments as given

## Specification Syntax

The specification is a [docopt](http://docopt.org) help message: a `Usage:` section listing the usage patterns, optionally followed by option descriptions. It is the help message of your command, formalized.

```text
Naval Fate.

Usage:
  naval_fate ship new <name>...
  naval_fate ship <name> move <x> <y> [--speed=<kn>]
  naval_fate mine (set|remove) <x> <y> [--moored|--drifting]
  naval_fate -h | --help

Options:
  -h --help     Show this screen.
  --speed=<kn>  Speed in knots [default: 10].
  --moored      Moored (anchored) mine.
  --drifting    Drifting mine.
```

**Usage patterns.** The text after `usage:` (case insensitive), up to a blank line, lists the patterns; the first word is the program name and each new occurrence of it starts another pattern. The arguments must match one of them.

| Element | Meaning |
|---|---|
| `<argument>`, `ARGUMENT` | Positional argument |
| `command` | Any other word is a (sub)command, matched literally |
| `-o`, `--option` | Short and long options; short options can be stacked: `-abc` = `-a -b -c` |
| `--option=<arg>` | Option with an argument |
| `[ ]` | Optional elements |
| `( )` | Required group |
| `a \| b` | Mutually exclusive elements |
| `...` | The element on its left is repeated one or more times |
| `[options]` | Shortcut for all the described options not used elsewhere in the usage |
| `[--]`, `[-]` | `--` and `-` are plain commands: they match the literal `--` and `-` arguments |

**Option descriptions.** In the indented lines following a line containing `options:`, every line starting with `-` describes an option: its synonyms (`-h --help`, `-o, --output`), whether it takes an argument (`--speed=<kn>`) and, after two spaces, a free text which may contain `[default: value]`. Describing options is only required for synonyms, arguments, default values and allowed values.

**Allowed values** (extension of docopt). `[choices: A, B, C]` in the description of an option with an argument restricts its values. Arguments are described in an `Arguments:` section, each line starting with the name used in the usage (`<name>` or `NAME`); they can state `[choices: ...]` too:

```text
Options:
  --flag=<country>  Flag of the ship [choices: FR, UK, US] [default: FR]

Arguments:
  <name>  Name of the ship [choices: Guardian, Voyager]
```

### Result

The result uses the names of the specification as keys: `ship`, `<name>`, `NAME`, `speed`, `v`. Options are named without their leading dashes, and by their long name when they have one: with `-q --quiet` described, `-q` in the arguments is stored under `quiet`. Two names giving the same key (`--name` and the command `name`) are refused.

| Element | Value |
|---|---|
| Command, option without argument | `true` / `false`; the number of occurrences if repeatable |
| Argument, option with argument | The value; `""` if not provided (or the `[default: ...]` of the option) |
| Repeatable argument or option | The values space separated, plus `<key>,#` (count) and `<key>,0`, `<key>,1`... (each value) |

### Help and Version

`-h`/`--help` and `-v`/`--version` are always recognised, whatever the usage says (so `-v` cannot be used for another option):

- `-h`, `--help`: the specification is printed on stdout and the execution is aborted (`exit 0`).
- `-v`, `--version`: the version is printed on stdout and the execution is aborted (`exit 0`). The version is the text following `Version:` (case insensitive) at the beginning of a line of the specification. Without such a line, an error is logged and the execution is aborted with status `1`.

### Separator `--`

As in docopt, `--` ends the options: the following arguments are positionals, even if they start with `-`. Add `[--]` before the positional arguments of the usage (`prog [options] [--] <file>...`) to match them against the usage. When the usage has no `[--]`, the arguments following `--` are not matched and are only stored in `rest`.

### Differences with docopt

Arguments are first parsed by `bach::parse_args`, so its rules apply:

- An option with an argument must be written `--option=value`: the short syntax with an argument (`-o FILE`, `-oFILE`, `--option FILE`) is not supported, so such an option needs a long syntax in the specification.
- `--option` alone is read as the value `true`.
- Repeated options (`-vvv`, `--tag=a --tag=b`) are seen once; the last value is kept.
- Arguments starting with `-` (e.g. `-5`) are read as options, unless they follow `--`.

## Best Practices

1. Call `bach::parse_args "$@"` once, at the beginning of your script or `main` function
2. Read the options with a default value: `${options[output]:-text}`
3. Validate the positional arguments you need right after parsing
4. Print `bach::parse_args::debug_parsed` when an argument is not parsed as expected

## Roadmap

_No feature planned for the moment._

## See Also

- [docstring_helper.md](docstring_helper.md) - Documentation (usage, help, version) generation
- [log.md](log.md) - Logging, used internally by this library
