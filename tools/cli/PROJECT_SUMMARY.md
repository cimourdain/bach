# CP Command Processor - Project Summary

## Overview

A complete bash command routing system has been created in `~/dotfiles/cp/`. This system allows executing bash scripts based on directory structure with automatic argument parsing, documentation generation, and flexible option handling.

## Created Files

### Core System (4 files)

1. **main.sh** - Entry point script
2. **lib/parse_args.sh** - Argument parsing library
3. **lib/doc_helper.sh** - Documentation utilities
4. **lib/router.sh** - Command routing logic

### Example Commands (11 files)

- **cmd/main.sh** - Default handler for cmd directory
- **cmd/cmd1.sh** - Simple command example
- **cmd/sone/main.sh** - Subcommand group handler
- **cmd/sone/foo.sh** - Example with multiple options
- **cmd/sone/bar.sh** - Example with valued options
- **cmd/sone/const.sh** - Excluded constants file
- **cmd/sone/statics.sh** - Excluded statics file
- **cmd/stwo/foo.sh** - Example in stwo group
- **cmd/stwo/ssx/main.sh** - Nested subcommand handler
- **cmd/stwo/ssx/yaya.sh** - Deeply nested command
- **cmd/stwo/ssx/const.sh** - Excluded constants file

### Documentation (2 files)

- **README.md** - Complete documentation
- **demo.sh** - Interactive demonstration script

## Key Features Implemented

### ✅ Directory-Based Routing
- Navigate through folders using arguments
- Example: `./main.sh sone foo` → executes `cmd/sone/foo.sh`

### ✅ Automatic Fallback to main.sh
- When path ends at a directory, execute its `main.sh`
- Example: `./main.sh sone` → executes `cmd/sone/main.sh`

### ✅ File Type Support
- Scripts with `.sh` extension
- Scripts without extension (if executable)

### ✅ Exclusion System
- Configure files/patterns to exclude from execution
- Default exclusions: `const.sh`, `statics.sh`, `main.sh`, `*.swp`, `*.sh~`
- Excluded files are not accessible via routing

### ✅ Self-Executable Scripts
- All command scripts can be run directly or via router
- Same behavior whether called as `./main.sh sone foo` or `./cmd/sone/foo.sh`

### ✅ Option Parsing
- **Short flags**: `-a`, `-b`, or merged `-ab`
- **Long flags**: `--all`, `--verbose`
- **Valued options**: `--output-format=json`, `--threads=8`
- Each script parses only its own options
- Unknown options passed through to next level

### ✅ Global Options Storage
- Parsed options stored in `__ARGS` associative array
- Path arguments stored in `__PATH_ARGS` regular array
- Customizable variable name via `__ARGS_VAR_NAME`

### ✅ Documentation System
- Structured docstring format in each script
- Auto-injection of subcommands into usage
- `--help` flag shows complete documentation
- `--version` flag extracts and displays version

### ✅ Layered Option Handling
- Options can be specified at each command level
- Example: `./main.sh --main-opt sone --sone-opt foo --foo-opt`
- Each script handles its subset of options

## Usage Examples

```bash
# Basic execution
./main.sh cmd1
./main.sh sone foo
./main.sh stwo ssx yaya

# With options
./main.sh cmd1 -afv --output-format=json file1 file2
./main.sh sone foo -ab --my-value="test" target

# Help and version
./main.sh --help
./main.sh cmd1 --version

# Direct execution
./cmd/sone/foo.sh -ab mytarget
./cmd/stwo/ssx/yaya.sh -rp --threads=16

# Fallback behavior
./main.sh           # Executes cmd/main.sh
./main.sh sone      # Executes cmd/sone/main.sh
./main.sh stwo ssx  # Executes cmd/stwo/ssx/main.sh
```

## Testing

Run the demo script to see all features in action:

```bash
cd ~/dotfiles/cp
./demo.sh
```

## Quick Start for Adding New Commands

1. Create your script in the appropriate directory:
   ```bash
   touch ~/dotfiles/cp/cmd/mynewcmd.sh
   chmod +x ~/dotfiles/cp/cmd/mynewcmd.sh
   ```

2. Copy the template from README.md and customize:
   - Update description
   - Define your options in the docstring
   - Implement your command logic
   - Update version number

3. Test it:
   ```bash
   ./main.sh mynewcmd --help
   ./main.sh mynewcmd <your-args>
   ```

## Architecture

```
main.sh
  ├─> parse_args (lib/parse_args.sh)
  │    └─> Parses own options, passes rest forward
  │
  ├─> doc_helper (lib/doc_helper.sh)
  │    ├─> Generates documentation
  │    └─> Auto-discovers subcommands
  │
  └─> router (lib/router.sh)
       └─> Navigates directory structure
            └─> Executes target script
                 └─> parse_args (parses its options)
                      └─> Executes command logic
```

## Configuration

Edit `main.sh` to customize:

```bash
# Add patterns to exclude from execution
EXCLUDE_LIST="const.sh,statics.sh,*.tmp,backup_*"

# Change global variable name (optional)
export __ARGS_VAR_NAME="MY_CUSTOM_ARGS"
```

## All Requirements Met

- ✅ Parses arguments to identify scripts based on folder structure
- ✅ Options (starting with dash) stored in global associative array
- ✅ Non-option arguments matched against directory structure
- ✅ Supports both `.sh` extension and no extension files
- ✅ Exclusion of files by path or pattern
- ✅ Non-executable files are ignored
- ✅ Scripts are self-executable using the provided template
- ✅ Supports valued options (`--option=value`) and flags (`-f/--flag`)
- ✅ Short format options can be merged (`-abc`)
- ✅ Each script parses its own subset of options
- ✅ Parsed options stored in global environment variable
- ✅ Global variable name is parametrizable (default: `__ARGS`)
- ✅ Options can be passed at each path level
- ✅ Documentation string in each script
- ✅ Documentation used for option parsing
- ✅ Documentation returned on `-h/--help` and errors
- ✅ Version returned on `-v/--version`
- ✅ Usage section auto-completed with discovered subcommands

## Project Location

**Path**: `~/dotfiles/cp/`

All scripts are executable and ready to use!
