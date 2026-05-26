# docstring_helper.sh - Documentation Generation Library

A powerful library for building and resolving command documentation with automatic subcommand discovery and help text generation.

## Overview

The docstring_helper library provides tools for creating rich, auto-generated documentation for CLI applications. It automatically discovers subcommands from directory structures, injects usage examples, and formats help text with proper options and version information.

## Features

- ✅ **Automatic subcommand discovery**: Scans directories for executable scripts
- ✅ **Usage section generation**: Auto-generates usage examples from subcommands
- ✅ **Help/version injection**: Automatically adds `-h/--help` and `-v/--version` options
- ✅ **Exclusion patterns**: Filter out unwanted files from subcommand lists
- ✅ **Nested subcommands**: Support for multi-level command hierarchies
- ✅ **Version extraction**: Parse version from docstrings
- ✅ **Flexible resolution**: Build docs from directories or pre-computed subcommand lists

## Usage

### Basic Examples

#### Simple Documentation Resolution

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
DOC="MyApp - Simple Application

A simple CLI application.

Usage:
    myapp [command]

----
1.0.0
"

# Subcommands from somewhere (e.g., router library)
SUBCOMMANDS="start
stop
status
restart"

# Resolve documentation
resolved=$(bach docstring_helper::resolve_docstring "$DOC" "myapp" "$SUBCOMMANDS")
echo "$resolved"
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
DOC="MyApp - Simple Application

A simple CLI application.

Usage:
    myapp [command]

----
1.0.0
"

# Subcommands from somewhere (e.g., router library)
SUBCOMMANDS="start
stop
status
restart"

# Resolve documentation
resolved=$(bach::docstring_helper::resolve_docstring "$DOC" "myapp" "$SUBCOMMANDS")
echo "$resolved"
```

:::

::: details Expected output

<pre class="ansi" v-pre>MyApp - Simple Application

A simple CLI application.

Usage:
    myapp [command]
    myapp start
    myapp stop
    myapp status
    myapp restart

----
1.0.0</pre>

:::

#### Extract Version

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
DOC="MyApp

Usage:
    myapp [options]

----
2.5.1
"

version=$(bach docstring_helper::get_version_from_doc "$DOC")
echo "Version: $version"
# Output: Version: 2.5.1
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
DOC="MyApp

Usage:
    myapp [options]

----
2.5.1
"

version=$(bach::docstring_helper::get_version_from_doc "$DOC")
echo "Version: $version"
# Output: Version: 2.5.1
```

:::

::: details Expected output

<pre class="ansi" v-pre>Version: 2.5.1</pre>

:::

#### Print Version

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
DOC="MyApp
----
1.0.0
"

bach docstring_helper::print_version "$DOC"
# Output: 1.0.0
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
DOC="MyApp
----
1.0.0
"

bach::docstring_helper::print_version "$DOC"
# Output: 1.0.0
```

:::

::: details Expected output

<pre class="ansi" v-pre>1.0.0</pre>

:::

#### Build Documentation from Directory

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
DOC="Tools - Development Tools

Usage:
    tools [command]

----
1.0.0
"

# Assuming directory structure:
# ./commands/
#   ├── build.sh
#   ├── test.sh
#   ├── deploy.sh
#   └── utils/
#       └── main.sh

built_doc=$(bach docstring_helper::build_documentation "$DOC" "./commands" "" "tools")
echo "$built_doc"
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
DOC="Tools - Development Tools

Usage:
    tools [command]

----
1.0.0
"

# Assuming directory structure:
# ./commands/
#   ├── build.sh
#   ├── test.sh
#   ├── deploy.sh
#   └── utils/
#       └── main.sh

built_doc=$(bach::docstring_helper::build_documentation "$DOC" "./commands" "" "tools")
echo "$built_doc"
```

:::

::: details Expected output

<pre class="ansi" v-pre>Tools - Development Tools

Usage:
    tools [command]

----
1.0.0</pre>

:::

### Advanced Examples

#### Complete CLI Application with Documentation

<!-- args: --help -->
::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOC="DevTools - Development Toolkit

A comprehensive toolkit for development workflows.

Usage:
    devtools [command] [options]

Options:
    -v,--verbose,Enable verbose output
    --config=,default=\"config.yaml\",Configuration file

----
2.0.0
"

# In production, get subcommands from router
# For this example, we'll use build_documentation
final_doc=$(bach docstring_helper::build_documentation "$DOC" "$SCRIPT_DIR/commands" "const.sh,*.bak")

# Use the documentation
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    bach docstring_helper::print_doc "$final_doc"
    exit 0
fi

if [[ "$1" == "--version" ]] || [[ "$1" == "-v" ]]; then
    bach docstring_helper::print_version "$DOC"
    exit 0
fi

# Continue with command execution...
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOC="DevTools - Development Toolkit

A comprehensive toolkit for development workflows.

Usage:
    devtools [command] [options]

Options:
    -v,--verbose,Enable verbose output
    --config=,default=\"config.yaml\",Configuration file

----
2.0.0
"

# In production, get subcommands from router
# For this example, we'll use build_documentation
final_doc=$(bach::docstring_helper::build_documentation "$DOC" "$SCRIPT_DIR/commands" "const.sh,*.bak")

# Use the documentation
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    bach::docstring_helper::print_doc "$final_doc"
    exit 0
fi

if [[ "$1" == "--version" ]] || [[ "$1" == "-v" ]]; then
    bach::docstring_helper::print_version "$DOC"
    exit 0
fi

# Continue with command execution...
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="cmd">$ ./my_script.sh --help</span>
DevTools - Development Toolkit

A comprehensive toolkit for development workflows.

Usage:
    devtools [command] [options]

Options:
    -h, --help              Show this help message
    -v, --version           Show version information
    -v,--verbose,Enable verbose output
    --config=,default="config.yaml",Configuration file

----
2.0.0</pre>

:::

#### Integration with Router Library

<!-- args: --help -->
::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
DOC="MyApp - Application Manager

Manage your applications with ease.

Usage:
    myapp [command] [options]

----
1.5.0
"

# Assume we have a router that provides bachcli::get_subcommands
# (This would be from router.sh in a real application)
get_subcommands() {
    # Simulated subcommand discovery
    echo "install"
    echo "uninstall"
    echo "update"
    echo "list"
}

# Get subcommands as newline-separated string
SUBCOMMANDS=$(get_subcommands)

# Resolve documentation
CMD_NAME=$(basename "$0" .sh)
resolved_doc=$(bach docstring_helper::resolve_docstring "$DOC" "$CMD_NAME" "$SUBCOMMANDS")

# Function to show help
show_help() {
    bach docstring_helper::print_doc "$resolved_doc"
}

# Check for help
if [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Continue with application logic...
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
DOC="MyApp - Application Manager

Manage your applications with ease.

Usage:
    myapp [command] [options]

----
1.5.0
"

# Assume we have a router that provides bachcli::get_subcommands
# (This would be from router.sh in a real application)
get_subcommands() {
    # Simulated subcommand discovery
    echo "install"
    echo "uninstall"
    echo "update"
    echo "list"
}

# Get subcommands as newline-separated string
SUBCOMMANDS=$(get_subcommands)

# Resolve documentation
CMD_NAME=$(basename "$0" .sh)
resolved_doc=$(bach::docstring_helper::resolve_docstring "$DOC" "$CMD_NAME" "$SUBCOMMANDS")

# Function to show help
show_help() {
    bach::docstring_helper::print_doc "$resolved_doc"
}

# Check for help
if [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Continue with application logic...
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="cmd">$ ./my_script.sh --help</span>
MyApp - Application Manager

Manage your applications with ease.

Usage:
    myapp [command] [options]
    my_script install
    my_script uninstall
    my_script update
    my_script list

----
1.5.0</pre>

:::

#### Nested Subcommands

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
DOC="CloudManager - Cloud Resource Manager

Usage:
    cloud [command]

----
3.0.0
"

# Nested subcommands (e.g., "aws ec2", "azure vm")
SUBCOMMANDS="aws ec2
aws s3
azure vm
azure storage
gcp compute
gcp storage"

resolved=$(bach docstring_helper::resolve_docstring "$DOC" "cloud" "$SUBCOMMANDS")
echo "$resolved"
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
DOC="CloudManager - Cloud Resource Manager

Usage:
    cloud [command]

----
3.0.0
"

# Nested subcommands (e.g., "aws ec2", "azure vm")
SUBCOMMANDS="aws ec2
aws s3
azure vm
azure storage
gcp compute
gcp storage"

resolved=$(bach::docstring_helper::resolve_docstring "$DOC" "cloud" "$SUBCOMMANDS")
echo "$resolved"
```

:::

::: details Expected output

<pre class="ansi" v-pre>CloudManager - Cloud Resource Manager

Usage:
    cloud [command]
    cloud aws ec2
    cloud aws s3
    cloud azure vm
    cloud azure storage
    cloud gcp compute
    cloud gcp storage

----
3.0.0</pre>

:::

#### Custom Usage with Subcommands

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
DOC="GitHelper - Git Workflow Helper

Simplify your git workflows.

Usage:
    git-helper [options] [command]
    git-helper commit -m \"message\"
    git-helper branch <name>

Options:
    -v,--verbose,Verbose output

----
1.2.0
"

SUBCOMMANDS="commit
branch
merge
rebase
tag"

resolved=$(bach docstring_helper::resolve_docstring "$DOC" "git-helper" "$SUBCOMMANDS")
echo "$resolved"
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
DOC="GitHelper - Git Workflow Helper

Simplify your git workflows.

Usage:
    git-helper [options] [command]
    git-helper commit -m \"message\"
    git-helper branch <name>

Options:
    -v,--verbose,Verbose output

----
1.2.0
"

SUBCOMMANDS="commit
branch
merge
rebase
tag"

resolved=$(bach::docstring_helper::resolve_docstring "$DOC" "git-helper" "$SUBCOMMANDS")
echo "$resolved"
```

:::

::: details Expected output

<pre class="ansi" v-pre>GitHelper - Git Workflow Helper

Simplify your git workflows.

Usage:
    git-helper [options] [command]
    git-helper commit -m "message"
    git-helper branch &lt;name&gt;
    git-helper commit
    git-helper branch
    git-helper merge
    git-helper rebase
    git-helper tag

Options:
    -h, --help              Show this help message
    -v, --version           Show version information
    -v,--verbose,Verbose output

----
1.2.0</pre>

:::

**Output:** Shows custom usage lines along with auto-generated subcommand usage.

#### Excluding Files from Subcommand Discovery

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
DOC="Builder - Build System

Usage:
    build [command]

----
1.0.0
"

# Directory structure:
# ./scripts/
#   ├── compile.sh
#   ├── test.sh
#   ├── package.sh
#   ├── const.sh       <- Excluded
#   ├── helpers.sh     <- Excluded
#   └── main.sh        <- Auto-excluded

# Exclude const.sh and any helpers*.sh files
exclude_list="const.sh,helpers*.sh"

built_doc=$(bach docstring_helper::build_documentation "$DOC" "./scripts" "$exclude_list" "build")
echo "$built_doc"
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
DOC="Builder - Build System

Usage:
    build [command]

----
1.0.0
"

# Directory structure:
# ./scripts/
#   ├── compile.sh
#   ├── test.sh
#   ├── package.sh
#   ├── const.sh       <- Excluded
#   ├── helpers.sh     <- Excluded
#   └── main.sh        <- Auto-excluded

# Exclude const.sh and any helpers*.sh files
exclude_list="const.sh,helpers*.sh"

built_doc=$(bach::docstring_helper::build_documentation "$DOC" "./scripts" "$exclude_list" "build")
echo "$built_doc"
```

:::

::: details Expected output

<pre class="ansi" v-pre>Builder - Build System

Usage:
    build [command]

----
1.0.0</pre>

:::

#### Dynamic Command Name Detection

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
DOC="Processor

Usage:
    [command]

----
1.0.0
"

# For main.sh in /usr/bin/data-processor/main.sh
# Automatically uses parent directory name "data-processor"

SUBCOMMANDS="validate
transform
export"

# Command name defaults to parent directory for main.sh
resolved=$(bach docstring_helper::resolve_docstring "$DOC" "$(basename "$(pwd)")" "$SUBCOMMANDS")
echo "$resolved"
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
DOC="Processor

Usage:
    [command]

----
1.0.0
"

# For main.sh in /usr/bin/data-processor/main.sh
# Automatically uses parent directory name "data-processor"

SUBCOMMANDS="validate
transform
export"

# Command name defaults to parent directory for main.sh
resolved=$(bach::docstring_helper::resolve_docstring "$DOC" "$(basename "$(pwd)")" "$SUBCOMMANDS")
echo "$resolved"
```

:::

::: details Expected output

<pre class="ansi" v-pre>Processor

Usage:
    [command]
    tmpXXXXXXXX validate
    tmpXXXXXXXX transform
    tmpXXXXXXXX export

----
1.0.0</pre>

:::

#### Multi-Section Documentation

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
DOC="DatabaseTool - Database Management

A powerful database management tool.

Features:
  - Backup and restore
  - Schema migration
  - Data import/export
  - Query optimization

Usage:
    dbtool [command] [options]

Options:
    -h,--host=,default=\"localhost\",Database host
    -p,--port=,default=\"5432\",Database port
    -d,--database=,Database name
    -u,--user=,Database user

Examples:
    dbtool backup --database mydb
    dbtool restore backup.sql
    dbtool migrate --version 5

----
2.1.0
"

SUBCOMMANDS="backup
restore
migrate
query
optimize"

resolved=$(bach docstring_helper::resolve_docstring "$DOC" "dbtool" "$SUBCOMMANDS")
echo "$resolved"
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
DOC="DatabaseTool - Database Management

A powerful database management tool.

Features:
  - Backup and restore
  - Schema migration
  - Data import/export
  - Query optimization

Usage:
    dbtool [command] [options]

Options:
    -h,--host=,default=\"localhost\",Database host
    -p,--port=,default=\"5432\",Database port
    -d,--database=,Database name
    -u,--user=,Database user

Examples:
    dbtool backup --database mydb
    dbtool restore backup.sql
    dbtool migrate --version 5

----
2.1.0
"

SUBCOMMANDS="backup
restore
migrate
query
optimize"

resolved=$(bach::docstring_helper::resolve_docstring "$DOC" "dbtool" "$SUBCOMMANDS")
echo "$resolved"
```

:::

::: details Expected output

<pre class="ansi" v-pre>DatabaseTool - Database Management

A powerful database management tool.

Features:
  - Backup and restore
  - Schema migration
  - Data import/export
  - Query optimization

Usage:
    dbtool [command] [options]
    dbtool backup
    dbtool restore
    dbtool migrate
    dbtool query
    dbtool optimize

Options:
    -h, --help              Show this help message
    -v, --version           Show version information
    -h,--host=,default="localhost",Database host
    -p,--port=,default="5432",Database port
    -d,--database=,Database name
    -u,--user=,Database user

Examples:
    dbtool backup --database mydb
    dbtool restore backup.sql
    dbtool migrate --version 5

----
2.1.0</pre>

:::

#### Conditional Documentation

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
# Different docs based on mode
if [[ "$MODE" == "admin" ]]; then
    DOC="AdminTool - Administration Mode

Usage:
    admin [command]

----
1.0.0
"
    SUBCOMMANDS="user-add
user-delete
permissions
audit-log"
else
    DOC="UserTool - User Mode

Usage:
    tool [command]

----
1.0.0
"
    SUBCOMMANDS="view
update
export"
fi

resolved=$(bach docstring_helper::resolve_docstring "$DOC" "tool" "$SUBCOMMANDS")
echo "$resolved"
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
# Different docs based on mode
if [[ "$MODE" == "admin" ]]; then
    DOC="AdminTool - Administration Mode

Usage:
    admin [command]

----
1.0.0
"
    SUBCOMMANDS="user-add
user-delete
permissions
audit-log"
else
    DOC="UserTool - User Mode

Usage:
    tool [command]

----
1.0.0
"
    SUBCOMMANDS="view
update
export"
fi

resolved=$(bach::docstring_helper::resolve_docstring "$DOC" "tool" "$SUBCOMMANDS")
echo "$resolved"
```

:::

::: details Expected output

<pre class="ansi" v-pre>UserTool - User Mode

Usage:
    tool [command]
    tool view
    tool update
    tool export

----
1.0.0</pre>

:::

#### Version Comparison

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
DOC_V1="App
----
1.0.0
"

DOC_V2="App
----
2.0.0
"

version1=$(bach docstring_helper::get_version_from_doc "$DOC_V1")
version2=$(bach docstring_helper::get_version_from_doc "$DOC_V2")

echo "Version 1: $version1"
echo "Version 2: $version2"

# Simple version comparison
if [[ "$version2" > "$version1" ]]; then
    echo "Version 2 is newer"
fi
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
DOC_V1="App
----
1.0.0
"

DOC_V2="App
----
2.0.0
"

version1=$(bach::docstring_helper::get_version_from_doc "$DOC_V1")
version2=$(bach::docstring_helper::get_version_from_doc "$DOC_V2")

echo "Version 1: $version1"
echo "Version 2: $version2"

# Simple version comparison
if [[ "$version2" > "$version1" ]]; then
    echo "Version 2 is newer"
fi
```

:::

::: details Expected output

<pre class="ansi" v-pre>Version 1: 1.0.0
Version 2: 2.0.0
Version 2 is newer</pre>

:::

#### Building Help for Subcommand

<!-- args: --help -->
::: code-group

```bash [With bach]
#!/bin/bash
# File: commands/backup.sh
source lib/bach/bach.sh
DOC="Backup Command

Create database backups.

Usage:
    backup [options] <database>

Options:
    -o,--output=,default=\"backup.sql\",Output file
    -c,--compress,Compress backup
    -v,--verbose,Verbose output

----
1.0.0
"

# This subcommand has no subcommands of its own
resolved=$(bach docstring_helper::resolve_docstring "$DOC" "backup" "")

if [[ "$1" == "--help" ]]; then
    echo "$resolved"
    exit 0
fi

# Execute backup...
```

```bash [Standalone]
#!/bin/bash
# File: commands/backup.sh
source my-libs/docstring_helper.sh
DOC="Backup Command

Create database backups.

Usage:
    backup [options] <database>

Options:
    -o,--output=,default=\"backup.sql\",Output file
    -c,--compress,Compress backup
    -v,--verbose,Verbose output

----
1.0.0
"

# This subcommand has no subcommands of its own
resolved=$(bach::docstring_helper::resolve_docstring "$DOC" "backup" "")

if [[ "$1" == "--help" ]]; then
    echo "$resolved"
    exit 0
fi

# Execute backup...
```

:::

::: details Expected output

<pre class="ansi" v-pre><span class="cmd">$ ./my_script.sh --help</span>
Backup Command

Create database backups.

Usage:
    backup [options] &lt;database&gt;

Options:
    -h, --help              Show this help message
    -v, --version           Show version information
    -o,--output=,default="backup.sql",Output file
    -c,--compress,Compress backup
    -v,--verbose,Verbose output

----
1.0.0</pre>

:::

#### Testing Documentation Generation

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
source assert.sh

test_version_extraction() {
    section "Test version extraction"

    local doc="Test
----
1.2.3
"
    local version=$(bach docstring_helper::get_version_from_doc "$doc")
    assert_contains "$version" "1.2.3" "Version should be 1.2.3"
}

test_resolve_with_subcommands() {
    section "Test resolve with subcommands"

    local doc="Test

Usage:
    test [command]

----
1.0.0
"

    local subcommands="cmd1
cmd2
cmd3"

    local resolved=$(bach docstring_helper::resolve_docstring "$doc" "test" "$subcommands")

    assert_contains "$resolved" "test cmd1" "Should contain cmd1"
    assert_contains "$resolved" "test cmd2" "Should contain cmd2"
    assert_contains "$resolved" "test cmd3" "Should contain cmd3"
    assert_contains "$resolved" "--help" "Should inject help flag"
    assert_contains "$resolved" "--version" "Should inject version flag"
}

test_version_extraction
test_resolve_with_subcommands
print_test_summary
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
source assert.sh

test_version_extraction() {
    section "Test version extraction"

    local doc="Test
----
1.2.3
"
    local version=$(bach::docstring_helper::get_version_from_doc "$doc")
    assert_contains "$version" "1.2.3" "Version should be 1.2.3"
}

test_resolve_with_subcommands() {
    section "Test resolve with subcommands"

    local doc="Test

Usage:
    test [command]

----
1.0.0
"

    local subcommands="cmd1
cmd2
cmd3"

    local resolved=$(bach::docstring_helper::resolve_docstring "$doc" "test" "$subcommands")

    assert_contains "$resolved" "test cmd1" "Should contain cmd1"
    assert_contains "$resolved" "test cmd2" "Should contain cmd2"
    assert_contains "$resolved" "test cmd3" "Should contain cmd3"
    assert_contains "$resolved" "--help" "Should inject help flag"
    assert_contains "$resolved" "--version" "Should inject version flag"
}

test_version_extraction
test_resolve_with_subcommands
print_test_summary
```

:::

#### Integration with Parse Args

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
source parse_args.sh

DOC="MyApp - Application

Usage:
    myapp [command] [options]

Options:
    -v,--verbose,Verbose mode
    -q,--quiet,Quiet mode

----
1.0.0
"

# Get subcommands (from router or hardcoded)
SUBCOMMANDS="start
stop
restart
status"

# Resolve documentation
resolved_doc=$(bach docstring_helper::resolve_docstring "$DOC" "myapp" "$SUBCOMMANDS")

# Parse arguments (this will use the resolved doc for help)
bach parse_args_from_docstring "$resolved_doc" "$@"

case $? in
    0) ;;  # Continue
    2|3) exit 0 ;;  # Help or version shown
    *) exit 1 ;;  # Error
esac

# Access parsed values
declare -n args="__ARGS"
echo "Verbose: ${args[verbose]}"
echo "Quiet: ${args[quiet]}"

# Handle subcommand from path args
if [[ ${#__PATH_ARGS[@]} -gt 0 ]]; then
    subcommand="${__PATH_ARGS[0]}"
    echo "Executing subcommand: $subcommand"
fi
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
source parse_args.sh

DOC="MyApp - Application

Usage:
    myapp [command] [options]

Options:
    -v,--verbose,Verbose mode
    -q,--quiet,Quiet mode

----
1.0.0
"

# Get subcommands (from router or hardcoded)
SUBCOMMANDS="start
stop
restart
status"

# Resolve documentation
resolved_doc=$(bach::docstring_helper::resolve_docstring "$DOC" "myapp" "$SUBCOMMANDS")

# Parse arguments (this will use the resolved doc for help)
bach::parse_args_from_docstring "$resolved_doc" "$@"

case $? in
    0) ;;  # Continue
    2|3) exit 0 ;;  # Help or version shown
    *) exit 1 ;;  # Error
esac

# Access parsed values
declare -n args="__ARGS"
echo "Verbose: ${args[verbose]}"
echo "Quiet: ${args[quiet]}"

# Handle subcommand from path args
if [[ ${#__PATH_ARGS[@]} -gt 0 ]]; then
    subcommand="${__PATH_ARGS[0]}"
    echo "Executing subcommand: $subcommand"
fi
```

:::

#### Directory Scanner with Filters

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
DOC="Scanner - File Scanner

Usage:
    scanner [command]

----
1.0.0
"

# Create test directory structure
mkdir -p /tmp/test_scanner/{cmd1,cmd2,utils}
touch /tmp/test_scanner/cmd1.sh
touch /tmp/test_scanner/cmd2.sh
touch /tmp/test_scanner/const.sh
touch /tmp/test_scanner/utils/main.sh
chmod +x /tmp/test_scanner/*.sh /tmp/test_scanner/utils/main.sh

# Build documentation excluding const.sh
built_doc=$(bach docstring_helper::build_documentation "$DOC" "/tmp/test_scanner" "const.sh" "scanner")

echo "$built_doc"

# Cleanup
rm -rf /tmp/test_scanner
```

```bash [Standalone]
#!/bin/bash
source my-libs/docstring_helper.sh
DOC="Scanner - File Scanner

Usage:
    scanner [command]

----
1.0.0
"

# Create test directory structure
mkdir -p /tmp/test_scanner/{cmd1,cmd2,utils}
touch /tmp/test_scanner/cmd1.sh
touch /tmp/test_scanner/cmd2.sh
touch /tmp/test_scanner/const.sh
touch /tmp/test_scanner/utils/main.sh
chmod +x /tmp/test_scanner/*.sh /tmp/test_scanner/utils/main.sh

# Build documentation excluding const.sh
built_doc=$(bach::docstring_helper::build_documentation "$DOC" "/tmp/test_scanner" "const.sh" "scanner")

echo "$built_doc"

# Cleanup
rm -rf /tmp/test_scanner
```

:::

## API Reference

### bach::docstring_helper::resolve_docstring

Resolve a docstring with subcommands and options (recommended for production).

**Signature:**
```bash
bach::docstring_helper::resolve_docstring "$doc_string" "$cmd_name" "$subcommands_list"
```

**Parameters:**
- `$1` (doc_string): Documentation string template
- `$2` (cmd_name): Name of the command
- `$3` (subcommands_list): Newline-separated list of subcommands

**Returns:** Prints resolved documentation with injected usage and options

**Use Case:** Production code where subcommands are already known (e.g., from router library)

### bach::docstring_helper::build_documentation

Build complete documentation with automatic subcommand discovery (for testing).

**Signature:**
```bash
bach::docstring_helper::build_documentation "$doc_string" "$script_dir" "$exclude_list" "$cmd_name"
```

**Parameters:**
- `$1` (doc_string): Documentation string template
- `$2` (script_dir): Directory to scan for subcommands
- `$3` (exclude_list): Comma-separated patterns to exclude (optional)
- `$4` (cmd_name): Command name (optional, defaults to script basename)

**Returns:** Prints complete documentation with discovered subcommands

**Use Case:** Testing, development, or standalone scripts

### bach::docstring_helper::get_version_from_doc

Extract version number from docstring.

**Signature:**
```bash
bach::docstring_helper::get_version_from_doc "$doc_string"
```

**Parameters:**
- `$1` (doc_string): Documentation string

**Returns:** Prints version string (e.g., "1.2.3")

### bach::docstring_helper::print_doc

Print documentation string to stdout.

**Signature:**
```bash
bach::docstring_helper::print_doc "$doc_string"
```

**Parameters:**
- `$1` (doc_string): Documentation string to print

### bach::docstring_helper::print_version

Extract and print version from docstring.

**Signature:**
```bash
bach::docstring_helper::print_version "$doc_string"
```

**Parameters:**
- `$1` (doc_string): Documentation string

**Returns:** Prints version number

## Docstring Format

### Basic Structure

```
Title - Description

Long description (optional)

Usage:
    command [subcommand] [options]

Options:
    -f,--flag,Description
    --option=,default="value",Description

----
1.0.0
```

### Sections

- **Title** (required): First line
- **Description** (optional): Additional lines before Usage
- **Usage** (optional): Will be auto-generated if missing
- **Options** (optional): Will have help/version auto-injected
- **Separator** (required): `----` line
- **Version** (required): Semantic version (X.Y.Z)

## Auto-Injection Behavior

### Usage Section

If missing or empty:
- Generates `command <subcommand>` for each discovered subcommand
- If no subcommands: generates `command [options]`

If present:
- Preserves custom usage lines
- Appends subcommand usage lines

### Options Section

If missing:
- Creates Options section with help/version

If present:
- Prepends help/version to existing options

### Help and Version

Always injected:
```
-h, --help              Show this help message
-v, --version           Show version information
```

## File Discovery Rules

### Included Files

- Executable `.sh` files (without .sh in command name)
- Executable files without extension
- Directories with executable `main.sh` or `main`
- Directories containing any executable scripts/subdirectories

### Excluded Files

Always excluded:
- `main.sh` (unless in subdirectory)
- `const.sh`
- Backup files (`*.sh~`, `*.swp`)
- Files matching exclude patterns

## Best Practices

1. **Use resolve_docstring in production**: It's faster and doesn't scan filesystem
2. **Provide usage examples**: Don't rely solely on auto-generation
3. **Set proper version**: Use semantic versioning (X.Y.Z)
4. **Use exclusion patterns**: Filter out helper files and constants
5. **Test your docs**: Use build_documentation to verify output
6. **Keep descriptions clear**: Write helpful option descriptions
7. **Group related commands**: Use nested subcommands for organization

## Roadmap

_No feature planned for the moment._

## See Also

- [parse_args.md](parse_args.md) - For parsing the arguments referenced in documentation
- [log.md](log.md) - For logging help requests
- [assert.md](assert.md) - For testing documentation generation
