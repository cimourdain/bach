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

The project includes a comprehensive demo script that showcases all features of the BACHCLI command processor. The demo is organized into three major sections with detailed subsections.

### Running the Demo

Execute the complete demonstration:

```bash
./demo.sh
```

Or run specific sections:

```bash
# Run a specific subsection
./demo.sh --section-1-1
./demo.sh --section-2-2

# Run multiple sections
./demo.sh --section-1-1 --section-1-5 --section-2-1
```

## Demo Sections in Detail

### Section 1: Subcommand Execution & Routing

This section demonstrates how the command processor routes execution through the directory structure based on command-line arguments.

#### 1.1 - No Arguments (Direct main.sh Execution)

**Functionality:** When no arguments are provided, [cmd/main.sh](cmd/main.sh) executes directly and handles the command without routing to any subcommands.

```bash
$ cd cmd && ./main.sh
[cmd]Enter command execution
[cmd]Build documentation
[cmd]Resolve docstring
[cmd]Parse arguments from docstring
[cmd]Parsed options:
[version]=false
[help]=false
[cmd]Actions BEFORE executing subcommands
[cmd]Executing subcommands:
[cmd]Actions AFTER executing subcommands
[cmd]Finished executing command
```

**Routing Details:**
- **Executed files:** [cmd/main.sh](cmd/main.sh)
- **Routing path:** No path arguments → main.sh executes and completes without routing

**Options Parsing:**
- `--help` (alias: `-h`): Auto-injected by `bach::parse_args_from_docstring` in [lib/parse_args.sh](lib/parse_args.sh)
- `--version` (alias: `-v`): Auto-injected by `bach::parse_args_from_docstring` in [lib/parse_args.sh](lib/parse_args.sh)
- Both options are defined in [lib/parse_args.sh](lib/parse_args.sh) and parsed by [cmd/main.sh](cmd/main.sh)

---

#### 1.2 - Filename as Argument

**Functionality:** When a filename matching an executable file is provided as an argument, the router resolves it and executes that specific file.

```bash
$ cd cmd && ./main.sh cmd1
[cmd]Enter command execution
[cmd]Build documentation
[cmd]Resolve docstring
[cmd]Parse arguments from docstring
[cmd]Parsed options:
[version]=false
[help]=false
[cmd]Actions BEFORE executing subcommands
[cmd]Executing subcommands:
[cmd]Enter command execution
[cmd]Build documentation
[cmd]Resolve docstring
[cmd]Parse arguments from docstring
[cmd]Parsed options:
[verbose]=false
[all]=false
[force]=false
[version]=false
[help]=false
[cmd]Actions BEFORE executing subcommands
[cmd]Executing subcommands:
[cmd]Actions AFTER executing subcommands
[cmd]Finished executing command
```

**Routing Details:**
- **Executed files:** [cmd/main.sh](cmd/main.sh) → [cmd/cmd1.sh](cmd/cmd1.sh)
- **Routing path:**
  1. [cmd/main.sh](cmd/main.sh) receives argument `cmd1`
  2. Calls `bachcli::execute_subcommand` from [lib/executor.sh](lib/executor.sh)
  3. Finds [cmd/cmd1.sh](cmd/cmd1.sh) and executes it

**Options Parsing:**
- **cmd/main.sh options:**
  - `--help`, `--version`: Auto-injected, defined and parsed in [cmd/main.sh](cmd/main.sh)

- **cmd/cmd1.sh options:**
  - `-a, --all` (default: "false"): Defined in [cmd/cmd1.sh](cmd/cmd1.sh) doc_string, parsed by [lib/parse_args.sh](lib/parse_args.sh)
  - `-f, --force`: Defined in [cmd/cmd1.sh](cmd/cmd1.sh) doc_string, parsed by [lib/parse_args.sh](lib/parse_args.sh)
  - `-v, --verbose`: Defined in [cmd/cmd1.sh](cmd/cmd1.sh) doc_string, parsed by [lib/parse_args.sh](lib/parse_args.sh)
  - `--output-format=` (default: "text"): Defined in [cmd/cmd1.sh](cmd/cmd1.sh) doc_string, parsed by [lib/parse_args.sh](lib/parse_args.sh)
  - `--help`, `--version`: Auto-injected

---

#### 1.3 - Folder with main.sh as Argument

**Functionality:** When a directory name is provided and that directory contains a [main.sh](cmd/sone/main.sh) file, the router executes the directory's main.sh.

```bash
$ cd cmd && ./main.sh sone
[cmd]Enter command execution
[cmd]Build documentation
[cmd]Resolve docstring
[cmd]Parse arguments from docstring
[cmd]Parsed options:
[version]=false
[help]=false
[cmd]Actions BEFORE executing subcommands
[cmd]Executing subcommands:
[cmd/sone]Enter command execution
[cmd/sone]Build documentation
[cmd/sone]Resolve docstring
[cmd/sone]Parse arguments from docstring
[cmd/sone]Parsed options:
[sone-main-flag]=false
[version]=false
[help]=false
[cmd/sone]Actions BEFORE executing subcommands
[cmd/sone]Executing subcommands:
[cmd/sone]Actions AFTER executing subcommands
[cmd/sone]Finished executing command
```

**Routing Details:**
- **Executed files:** [cmd/main.sh](cmd/main.sh) → [cmd/sone/main.sh](cmd/sone/main.sh)
- **Routing path:**
  1. [cmd/main.sh](cmd/main.sh) receives argument `sone`
  2. Calls `bachcli::execute_subcommand` from [lib/executor.sh](lib/executor.sh)
  3. Finds directory `cmd/sone/` with [main.sh](cmd/sone/main.sh) inside
  4. Executes [cmd/sone/main.sh](cmd/sone/main.sh)

**Options Parsing:**
- **cmd/main.sh options:**
  - `--help`, `--version`: Auto-injected

- **cmd/sone/main.sh options:**
  - `-o, --sone-main-flag` (default: "false"): Defined in [cmd/sone/main.sh](cmd/sone/main.sh) doc_string, parsed by [lib/parse_args.sh](lib/parse_args.sh)
  - `--sone-val=` (default: "sone_is_great"): Defined in [cmd/sone/main.sh](cmd/sone/main.sh) doc_string, parsed by [lib/parse_args.sh](lib/parse_args.sh)
  - `--help`, `--version`: Auto-injected

---

#### 1.4 - Folder without main.sh as Argument

**Functionality:** When a directory name is provided but the directory lacks a main.sh file, the router generates an error indicating the command cannot be executed.

```bash
$ cd cmd && ./main.sh stwo
[cmd]Enter command execution
[cmd]Build documentation
[cmd]Resolve docstring
[cmd]Parse arguments from docstring
[cmd]Parsed options:
[version]=false
[help]=false
[cmd]Actions BEFORE executing subcommands
[cmd]Executing subcommands:
Error: Could not find or execute command: stwo
[cmd]Actions AFTER executing subcommands
[cmd]Finished executing command
```

**Routing Details:**
- **Executed files:** [cmd/main.sh](cmd/main.sh) only
- **Routing path:**
  1. [cmd/main.sh](cmd/main.sh) receives argument `stwo`
  2. Calls `bachcli::execute_subcommand` from [lib/executor.sh](lib/executor.sh)
  3. Finds directory `cmd/stwo/` but no [main.sh](cmd/stwo/main.sh) inside
  4. Returns error from [lib/router.sh](lib/router.sh)

**Options Parsing:**
- **cmd/main.sh options:**
  - `--help`, `--version`: Auto-injected, parsed in [cmd/main.sh](cmd/main.sh)

---

#### 1.5 - File in Subfolder

**Functionality:** Multiple path arguments traverse directories to find and execute the target file.

**Example 1 - sone bar:**

```bash
$ cd cmd && ./main.sh sone bar
[cmd]Enter command execution
[cmd]Build documentation
[cmd]Resolve docstring
[cmd]Parse arguments from docstring
[cmd]Parsed options:
[version]=false
[help]=false
[cmd]Actions BEFORE executing subcommands
[cmd]Executing subcommands:
[cmd/sone]Enter command execution
[cmd/sone]Build documentation
[cmd/sone]Resolve docstring
[cmd/sone]Parse arguments from docstring
[cmd/sone]Parsed options:
[sone-main-flag]=false
[version]=false
[help]=false
[cmd/sone]Actions BEFORE executing subcommands
[cmd/sone]Executing subcommands:
[cmd/sone]Enter command execution
[cmd/sone]Build documentation
[cmd/sone]Resolve docstring
[cmd/sone]Parse arguments from docstring
[cmd/sone]Parsed options:
[version]=false
[dry-run]=false
[quiet]=false
[help]=false
[cmd/sone]Actions BEFORE executing subcommands
[cmd/sone]Executing subcommands:
[cmd/sone]Actions AFTER executing subcommands
[cmd/sone]Finished executing command
```

**Routing Details:**
- **Executed files:** [cmd/main.sh](cmd/main.sh) → [cmd/sone/main.sh](cmd/sone/main.sh) → [cmd/sone/bar.sh](cmd/sone/bar.sh)
- **Routing path:**
  1. [cmd/main.sh](cmd/main.sh) receives arguments `sone bar`
  2. Calls `bachcli::execute_subcommand` which finds `cmd/sone/` directory with main.sh
  3. Executes [cmd/sone/main.sh](cmd/sone/main.sh) with argument `bar`
  4. [cmd/sone/main.sh](cmd/sone/main.sh) calls `bachcli::execute_subcommand` which finds [cmd/sone/bar.sh](cmd/sone/bar.sh)
  5. Executes [cmd/sone/bar.sh](cmd/sone/bar.sh)

**Options Parsing:**
- **cmd/main.sh:** `--help`, `--version` (auto-injected)
- **cmd/sone/main.sh:** `-o/--sone-main-flag`, `--sone-val=`, `--help`, `--version` (defined in [cmd/sone/main.sh](cmd/sone/main.sh))
- **cmd/sone/bar.sh:**
  - `-q, --quiet`: Defined in [cmd/sone/bar.sh](cmd/sone/bar.sh) doc_string, parsed by [lib/parse_args.sh](lib/parse_args.sh)
  - `-d, --dry-run`: Defined in [cmd/sone/bar.sh](cmd/sone/bar.sh) doc_string, parsed by [lib/parse_args.sh](lib/parse_args.sh)
  - `--config=` (default: "default.conf"): Defined in [cmd/sone/bar.sh](cmd/sone/bar.sh) doc_string, parsed by [lib/parse_args.sh](lib/parse_args.sh)
  - `--help`, `--version`: Auto-injected

**Example 2 - stwo foo:**

```bash
$ cd cmd && ./main.sh stwo foo
[cmd]Enter command execution
[cmd]Build documentation
[cmd]Resolve docstring
[cmd]Parse arguments from docstring
[cmd]Parsed options:
[version]=false
[help]=false
[cmd]Actions BEFORE executing subcommands
[cmd]Executing subcommands:
[cmd/stwo]Enter command execution
[cmd/stwo]Build documentation
[cmd/stwo]Resolve docstring
[cmd/stwo]Parse arguments from docstring
[cmd/stwo]Parsed options:
[execute]=false
[version]=false
[help]=false
[cmd/stwo]Actions BEFORE executing subcommands
[cmd/stwo]Executing subcommands:
[cmd/stwo]Actions AFTER executing subcommands
[cmd/stwo]Finished executing command
```

**Routing Details:**
- **Executed files:** [cmd/main.sh](cmd/main.sh) → [cmd/stwo/foo.sh](cmd/stwo/foo.sh)
- **Routing path:**
  1. [cmd/main.sh](cmd/main.sh) receives arguments `stwo foo`
  2. Calls `bachcli::execute_subcommand` which finds `cmd/stwo/` directory (no main.sh)
  3. Router continues with `foo` argument, finds [cmd/stwo/foo.sh](cmd/stwo/foo.sh)
  4. Executes [cmd/stwo/foo.sh](cmd/stwo/foo.sh)

**Options Parsing:**
- **cmd/main.sh:** `--help`, `--version` (auto-injected)
- **cmd/stwo/foo.sh:**
  - `-e, --execute`: Defined in [cmd/stwo/foo.sh](cmd/stwo/foo.sh) doc_string, parsed by [lib/parse_args.sh](lib/parse_args.sh)
  - `--mode=` (default: "standard"): Defined in [cmd/stwo/foo.sh](cmd/stwo/foo.sh) doc_string, parsed by [lib/parse_args.sh](lib/parse_args.sh)
  - `--help`, `--version`: Auto-injected

---

#### 1.6 - Deep Nested Path

**Functionality:** The router can traverse multiple directory levels to reach deeply nested commands.

```bash
$ cd cmd && ./main.sh stwo ssx yaya
[cmd]Enter command execution
[cmd]Build documentation
[cmd]Resolve docstring
[cmd]Parse arguments from docstring
[cmd]Parsed options:
[version]=false
[help]=false
[cmd]Actions BEFORE executing subcommands
[cmd]Executing subcommands:
[cmd/stwo/ssx]Enter command execution
[cmd/stwo/ssx]Build documentation
[cmd/stwo/ssx]Resolve docstring
[cmd/stwo/ssx]Parse arguments from docstring
[cmd/stwo/ssx]Parsed options:
[version]=false
[help]=false
[cmd/stwo/ssx]Actions BEFORE executing subcommands
[cmd/stwo/ssx]Executing subcommands:
[cmd/stwo/ssx]Enter command execution
[cmd/stwo/ssx]Build documentation
[cmd/stwo/ssx]Resolve docstring
[cmd/stwo/ssx]Parse arguments from docstring
[cmd/stwo/ssx]Parsed options:
[version]=false
[help]=false
[parallel]=false
[recursive]=false
[cmd/stwo/ssx]Actions BEFORE executing subcommands
[cmd/stwo/ssx]Executing subcommands:
[cmd/stwo/ssx]Actions AFTER executing subcommands
[cmd/stwo/ssx]Finished executing command
```

**Routing Details:**
- **Executed files:** [cmd/main.sh](cmd/main.sh) → [cmd/stwo/ssx/main.sh](cmd/stwo/ssx/main.sh) → [cmd/stwo/ssx/yaya.sh](cmd/stwo/ssx/yaya.sh)
- **Routing path:**
  1. [cmd/main.sh](cmd/main.sh) receives arguments `stwo ssx yaya`
  2. Router finds `cmd/stwo/` directory (no main.sh), continues with `ssx yaya`
  3. Router finds `cmd/stwo/ssx/` directory with main.sh
  4. Executes [cmd/stwo/ssx/main.sh](cmd/stwo/ssx/main.sh) with argument `yaya`
  5. [cmd/stwo/ssx/main.sh](cmd/stwo/ssx/main.sh) calls `bachcli::execute_subcommand` which finds [cmd/stwo/ssx/yaya.sh](cmd/stwo/ssx/yaya.sh)
  6. Executes [cmd/stwo/ssx/yaya.sh](cmd/stwo/ssx/yaya.sh)

**Options Parsing:**
- **cmd/main.sh:** `--help`, `--version` (auto-injected)
- **cmd/stwo/ssx/main.sh:** `--help`, `--version` (auto-injected, defined in [cmd/stwo/ssx/main.sh](cmd/stwo/ssx/main.sh))
- **cmd/stwo/ssx/yaya.sh:**
  - `-r, --recursive`: Defined in [cmd/stwo/ssx/yaya.sh](cmd/stwo/ssx/yaya.sh) doc_string, parsed by [lib/parse_args.sh](lib/parse_args.sh)
  - `-p, --parallel` (default: "false"): Defined in [cmd/stwo/ssx/yaya.sh](cmd/stwo/ssx/yaya.sh) doc_string, parsed by [lib/parse_args.sh](lib/parse_args.sh)
  - `--threads=` (default: "4"): Defined in [cmd/stwo/ssx/yaya.sh](cmd/stwo/ssx/yaya.sh) doc_string, parsed by [lib/parse_args.sh](lib/parse_args.sh)
  - `--help`, `--version`: Auto-injected

---

#### 1.7 - Resolution Errors

**Functionality:** When a command argument doesn't match any file or directory, the router returns a descriptive error message.

```bash
$ cd cmd && ./main.sh sone buzz
[cmd]Enter command execution
[cmd]Build documentation
[cmd]Resolve docstring
[cmd]Parse arguments from docstring
[cmd]Parsed options:
[version]=false
[help]=false
[cmd]Actions BEFORE executing subcommands
[cmd]Executing subcommands:
[cmd/sone]Enter command execution
[cmd/sone]Build documentation
[cmd/sone]Resolve docstring
[cmd/sone]Parse arguments from docstring
[cmd/sone]Parsed options:
[sone-main-flag]=false
[version]=false
[help]=false
[cmd/sone]Actions BEFORE executing subcommands
[cmd/sone]Executing subcommands:
Error: Could not find or execute command: buzz
[cmd/sone]Actions AFTER executing subcommands
[cmd/sone]Finished executing command
```

**Routing Details:**
- **Executed files:** [cmd/main.sh](cmd/main.sh) → [cmd/sone/main.sh](cmd/sone/main.sh)
- **Routing path:**
  1. [cmd/main.sh](cmd/main.sh) receives arguments `sone buzz`
  2. Router finds `cmd/sone/` directory with main.sh and executes it
  3. [cmd/sone/main.sh](cmd/sone/main.sh) calls `bachcli::execute_subcommand` with argument `buzz`
  4. Router cannot find `cmd/sone/buzz.sh` or `cmd/sone/buzz/`
  5. [lib/router.sh](lib/router.sh) returns error message

**Options Parsing:**
- **cmd/main.sh:** `--help`, `--version` (auto-injected)
- **cmd/sone/main.sh:** `-o/--sone-main-flag`, `--sone-val=`, `--help`, `--version`

---

#### 1.8 - Exclusion Pattern Behaviour

**Functionality:** Files matching patterns in the exclusion list cannot be executed as subcommands, even if they exist in the directory.

```bash
$ cd cmd && ./main.sh sone const
[cmd]Enter command execution
[cmd]Build documentation
[cmd]Resolve docstring
[cmd]Parse arguments from docstring
[cmd]Parsed options:
[version]=false
[help]=false
[cmd]Actions BEFORE executing subcommands
[cmd]Executing subcommands:
[cmd/sone]Enter command execution
[cmd/sone]Build documentation
[cmd/sone]Resolve docstring
[cmd/sone]Parse arguments from docstring
[cmd/sone]Parsed options:
[sone-main-flag]=false
[version]=false
[help]=false
[cmd/sone]Actions BEFORE executing subcommands
[cmd/sone]Executing subcommands:
Error: Could not find or execute command: const
[cmd/sone]Actions AFTER executing subcommands
[cmd/sone]Finished executing command
```

**Routing Details:**
- **Executed files:** [cmd/main.sh](cmd/main.sh) → [cmd/sone/main.sh](cmd/sone/main.sh)
- **Exclusion list:** `"const.sh,statics.sh"` defined in [cmd/sone/main.sh](cmd/sone/main.sh)
- **Routing path:**
  1. [cmd/main.sh](cmd/main.sh) receives arguments `sone const`
  2. Router executes [cmd/sone/main.sh](cmd/sone/main.sh) with argument `const`
  3. [cmd/sone/main.sh](cmd/sone/main.sh) has `exclude_list="const.sh,statics.sh"`
  4. Router finds [cmd/sone/const.sh](cmd/sone/const.sh) but it's excluded
  5. [lib/router.sh](lib/router.sh) returns error as if file doesn't exist

**Options Parsing:**
- **cmd/main.sh:** `--help`, `--version`
- **cmd/sone/main.sh:** `-o/--sone-main-flag`, `--sone-val=`, `--help`, `--version`

---

### Section 2: Options Definition & Parsing

This section demonstrates how options are defined in command scripts and parsed at each level of the routing hierarchy.

#### 2.1 - Flag Options (Short and Long Notation)

**Functionality:** Commands can define boolean flags with short notation (-a), long notation (--all), or both. Flags can be combined, and valued options can have default values.

**Example 1 - No flags (default values):**

```bash
$ cd cmd && ./main.sh cmd1
[cmd]Parsed options:
[version]=false
[help]=false
[cmd]Parsed options:
[verbose]=false
[all]=false
[force]=false
[version]=false
[help]=false
```

**Options Parsing:**
- All flags show their default values: `false`
- `-a/--all` default: `"false"` (defined in [cmd/cmd1.sh](cmd/cmd1.sh) doc_string Options section)
- `-f/--force`: No default specified, defaults to `false` (boolean flag behavior)
- `-v/--verbose`: No default specified, defaults to `false`
- `--output-format=`: default: `"text"` (valued option)

**Example 2 - Short flag notation combined:**

```bash
$ cd cmd && ./main.sh cmd1 -af
[cmd]Parsed options:
[verbose]=false
[all]=true
[force]=true
[version]=false
[help]=false
```

**Options Parsing:**
- `-af` is split into `-a` and `-f` by [lib/parse_args.sh](lib/parse_args.sh)
- `-a` maps to `--all`: Defined in [cmd/cmd1.sh](cmd/cmd1.sh), parsed to `true`
- `-f` maps to `--force`: Defined in [cmd/cmd1.sh](cmd/cmd1.sh), parsed to `true`
- `--verbose` remains false (not provided)

**Example 3 - Long flag notation:**

```bash
$ cd cmd && ./main.sh cmd1 --all --force --verbose
[cmd]Parsed options:
[verbose]=true
[all]=true
[force]=true
[version]=false
[help]=false
```

**Options Parsing:**
- `--all`: Defined in [cmd/cmd1.sh](cmd/cmd1.sh), parsed to `true`
- `--force`: Defined in [cmd/cmd1.sh](cmd/cmd1.sh), parsed to `true`
- `--verbose`: Defined in [cmd/cmd1.sh](cmd/cmd1.sh), parsed to `true`

**Example 5 - Valued option with custom value:**

```bash
$ cd cmd && ./main.sh cmd1 --output-format=json
```

**Options Parsing:**
- `--output-format=json`: Defined in [cmd/cmd1.sh](cmd/cmd1.sh) with default `"text"`, now set to `"json"`
- Parsed by [lib/parse_args.sh](lib/parse_args.sh) which recognizes the `=` syntax for valued options

---

#### 2.2 - Multi-Level Option Parsing

**Functionality:** Each script in the routing chain parses its own options independently. This allows layered option handling across the command hierarchy.

```bash
$ cd cmd && ./main.sh sone foo -ab --my-value="test123" target1
[cmd]Parsed options:
[version]=false
[help]=false
[cmd/sone]Parsed options:
[sone-main-flag]=false
[version]=false
[help]=false
[cmd/sone]Parsed options:
[all]=true
[bizz]=true
[version]=false
[my-value]=test123
[my-flag]=false
[help]=false
[cmd/sone]Executing subcommands:
Error: Could not find or execute command: target1
```

**Routing Details:**
- **Executed files:** [cmd/main.sh](cmd/main.sh) → [cmd/sone/main.sh](cmd/sone/main.sh) → [cmd/sone/foo.sh](cmd/sone/foo.sh)
- Each script parses only the options it recognizes

**Options Parsing:**
- **cmd/main.sh:**
  - Parses: `--help`, `--version` (auto-injected, both false)
  - Passes through: `-ab --my-value="test123" target1`

- **cmd/sone/main.sh:**
  - Parses: `--sone-main-flag` (false), `--sone-val=` (default), `--help`, `--version`
  - Options defined in [cmd/sone/main.sh](cmd/sone/main.sh) doc_string
  - Passes through: `-ab --my-value="test123" target1`

- **cmd/sone/foo.sh:**
  - Parses: `-a` → `--all=true`, `-b` → `--bizz=true`, `--my-value="test123"`
  - Options defined in [cmd/sone/foo.sh](cmd/sone/foo.sh) doc_string:
    - `-a, --all`: Apply to all targets (parsed to `true`)
    - `-b, --bizz`: Enable bizz mode (parsed to `true`)
    - `-f, --my-flag`: Set my flag (remains `false`, not provided)
    - `--my-value=`: Set custom value (parsed to `"test123"`)
  - Passes through: `target1` to `__PATH_ARGS`
  - Router attempts to execute `target1` as subcommand but fails (not found)

---

#### 2.3 - Option Error Handling

**Functionality:** When an invalid option is provided, the parser detects it but continues processing. Unknown options are treated as potential subcommand arguments.

```bash
$ cd cmd && ./main.sh cmd1 --invalid-option
[cmd]Parsed options:
[version]=false
[help]=false
[cmd]Parsed options:
[verbose]=false
[all]=false
[force]=false
[version]=false
[help]=false
```

**Options Parsing:**
- **cmd/main.sh:** Doesn't recognize `--invalid-option`, passes it through
- **cmd/cmd1.sh:** Doesn't recognize `--invalid-option`, treats it as unknown
- [lib/parse_args.sh](lib/parse_args.sh) treats unknown options as potential path arguments or displays an error depending on implementation

---

### Section 3: Direct Script Execution

**Functionality:** All command scripts are self-executable. They can be invoked directly without going through the router, which is useful for testing, debugging, or direct usage.

**Example 1 - Display help:**

```bash
$ ./cmd/sone/foo.sh --help
[cmd/sone]Enter command execution
[cmd/sone]Build documentation
[cmd/sone]Resolve docstring
[cmd/sone]Parse arguments from docstring

Command cmd/sone

Description of commands defined in /home/gabriel/bach/tools/cli/cmd/sone

Usage:
    /home/gabriel/bach/tools/cli/cmd/sone [options]
Options:
    -h, --help              Show this help message
    -v, --version           Show version information
    -a,--all,Apply to all targets
    -b,--bizz,Enable bizz mode
    -f,--my-flag,Set my flag
    --my-value=,Set custom value for processing
```

**Routing Details:**
- **Executed files:** [cmd/sone/foo.sh](cmd/sone/foo.sh) only (direct execution)
- No routing occurs - script executes standalone

**Options Parsing:**
- `--help` recognized by [lib/parse_args.sh](lib/parse_args.sh) (auto-injected)
- Help text generated from doc_string in [cmd/sone/foo.sh](cmd/sone/foo.sh) by [lib/doc_helper.sh](lib/doc_helper.sh)

**Example 2 - Direct execution with options:**

```bash
$ ./cmd/sone/bar.sh -qd --config=custom.conf
[cmd/sone]Parsed options:
[version]=false
[dry-run]=true
[quiet]=true
[help]=false
[config]=custom.conf
[cmd/sone]Actions BEFORE executing subcommands
[cmd/sone]Executing subcommands:
[cmd/sone]Actions AFTER executing subcommands
[cmd/sone]Finished executing command
```

**Routing Details:**
- **Executed files:** [cmd/sone/bar.sh](cmd/sone/bar.sh) only
- Direct execution bypasses all parent scripts

**Options Parsing:**
- `-q` → `--quiet=true`: Defined in [cmd/sone/bar.sh](cmd/sone/bar.sh), parsed by [lib/parse_args.sh](lib/parse_args.sh)
- `-d` → `--dry-run=true`: Defined in [cmd/sone/bar.sh](cmd/sone/bar.sh), parsed by [lib/parse_args.sh](lib/parse_args.sh)
- `--config=custom.conf`: Defined in [cmd/sone/bar.sh](cmd/sone/bar.sh) with default "default.conf", overridden to "custom.conf"
- All options defined in the doc_string of [cmd/sone/bar.sh](cmd/sone/bar.sh) and parsed in the same file

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

#### Command Scripts

All command scripts follow the same template structure. Use `cmd/sone/foo.sh` as your base template:

```bash
#!/bin/bash

main() {
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Adjust path depth as needed (../ for each level up to reach lib/)
    local lib_dir="$(cd "${script_dir}/.." && pwd)/lib"

    # Source required libraries
    source "${lib_dir}/parse_args.sh"
    source "${lib_dir}/doc_helper.sh"
    source "${lib_dir}/router.sh"

    # Subcommands directory - where the command scripts are located
    local subcommand_dir="${script_dir}"

    # Configurable exclusions - add files/patterns to exclude from execution
    local exclude_list="const.sh,statics.sh"

    local doc_string="
COMMAND_NAME - Brief Description

Longer description of what this command does.

Usage:
    command [options] <target>

Options:
    -a,--all,Apply to all targets
    -b,--flag,Enable flag mode
    --value=,Set custom value for processing
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

    # Access parsed options
    declare -n args="${__ARGS_VAR_NAME}"

    # Your command logic here (before subcommands)
    printf '%s\n' "=== Executing command ===" >&2

    if [[ "${args[all]}" == "true" ]]; then
        printf "%s\n" "ALL mode enabled!" >&2
    fi

    # Route to subcommands if any
    route_to_subcommand "${subcommand_dir}" "$exclude_list" "${__PATH_ARGS[@]}"

    # Your command logic here (after subcommands)
    printf '%s\n' "=== Command complete ===" >&2
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

**Key points:**

- **Always source `router.sh`**: Required for subcommand routing
- **Always call `route_to_subcommand`**: Enables nested command execution
- **Set `subcommand_dir="${script_dir}"`**: Looks for subcommands in same directory
- **Adjust `lib_dir` path**: Use correct number of `../` to reach the lib folder
- **Logic placement**:
  - Code before `route_to_subcommand`: executes before nested commands
  - Code after `route_to_subcommand`: executes after nested commands return

**For leaf commands** (no subcommands expected):

You can simplify by omitting router-related code:

```bash
#!/bin/bash

main() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local lib_dir="$(cd "${script_dir}/../.." && pwd)/lib"

    source "${lib_dir}/parse_args.sh"
    source "${lib_dir}/doc_helper.sh"

    local doc_string="
LEAF_COMMAND - Brief Description

Description of this leaf command.

Usage:
    leaf [options] [<args>...]

Options:
    -f,--force,Force execution
----
1.0.0
"

    parse_args "$doc_string" "" "" "$@"

    case $? in
        0) ;;
        2|3) return 0 ;;
        *) return 1 ;;
    esac

    declare -n args="${__ARGS_VAR_NAME}"

    # Your command logic here
    printf '%s\n' "Executing leaf command" >&2
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
    (OPTION_SPECIFICATION)
    ...
]
----
(X.X.X - semver version)
```

**Option Specification Format:**
```
[-<S>,](--<LL>)[=],[enum="<EE;>",][default="<DD>",](<DESC>) [# <CCC>]
```

Where:
- `[-<S>,]` - Optional short flag (single lowercase letter a-z)
- `(--<LL>)` - Required long flag (lowercase letters, hyphens, underscores: a-z, -, _)
- `[=]` - Optional, indicates the option requires a value
- `[enum="<EE;>"]` - Optional, semicolon-separated list of allowed values
- `[default="<DD>"]` - Optional, default value if not provided
- `(<DESC>)` - Required description (no commas or # allowed)
- `[# <CCC>]` - Optional comment

**Examples:**

```options
Options:
    -a,--all,default="true",Apply to all targets
    -b,--banana-is_a-fruit,default="false",Is Banana a fruit?
    -c,--cookie-me,Flag with no default  # TODO: raise error when not provided
    -d,--delim,default="| ",An option with extra spaces for clarity
    --e-value=,default="def_E",Option requires value for E with default
    --f-val=,enum="TOMATO;CHEEZE;SALMON",Option requires a value with enum restriction
    -v,--verbose,Enable verbose output
    --config=,default="default.conf",Configuration file to use
```

**Rules:**
- Spaces and tabs after commas are ignored
- Comments after `#` are stripped
- Short flags must be a single lowercase letter (a-z)
- Long flags must use lowercase letters, hyphens, and underscores
- Enum values are semicolon-separated
- Default values must be quoted with double quotes
- Descriptions cannot contain commas or `#` characters

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

You don't need to explicitly define `-h,--help` or `-v,--version` in your doc_string Options section. These are automatically injected by parse_args and will appear in the help output.

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
