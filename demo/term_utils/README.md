# Term Utils Library Demo

The **term_utils library** provides terminal color and formatting utilities for creating visually appealing bash scripts and CLI applications.

## Capabilities

- ✅ 8 standard terminal colors
- ✅ 8 background colors
- ✅ Text formatting (bold, dim, underline)
- ✅ Color reset for cleanup
- ✅ Terminal compatibility handling
- ✅ Comprehensive color demo

## Exposed Functions

### bach term_utils::declare_colors

**Purpose:** Initialize color and formatting variables for use in terminal output.

**Signature:**
```bash
bach term_utils::declare_colors
```

**Arguments:** None

**Returns:** `0` on success

**Output:** Sets global color variables:
- Basic colors: `RED`, `GREEN`, `YELLOW`, `BLUE`, `MAGENTA`, `CYAN`, `WHITE`, `BLACK`
- Background colors: `BG_RED`, `BG_GREEN`, `BG_YELLOW`, `BG_BLUE`, `BG_MAGENTA`, `BG_CYAN`, `BG_WHITE`, `BG_BLACK`
- Formatting: `BOLD`, `DIM`, `UNDERLINE`, `RESET`

### bach term_utils::colors_tput_demo

**Purpose:** Display a comprehensive demo of all available terminal colors.

**Signature:**
```bash
bach term_utils::colors_tput_demo
```

**Arguments:** None

**Returns:** `0` on success

**Output:** Displays all available colors and formatting options to stdout

## Color Variables

After calling `bach term_utils::declare_colors`, the following variables are available:

### Basic Colors
- `RED`, `GREEN`, `YELLOW`, `BLUE`, `MAGENTA`, `CYAN`, `WHITE`, `BLACK`

### Background Colors
- `BG_RED`, `BG_GREEN`, `BG_YELLOW`, `BG_BLUE`, `BG_MAGENTA`, `BG_CYAN`, `BG_WHITE`, `BG_BLACK`

### Text Formatting
- `BOLD` - Bold text
- `DIM` - Dimmed/faded text
- `UNDERLINE` - Underlined text
- `RESET` - Reset all formatting

## Running the Demo

```bash
cd demo/term_utils
bash demo.sh
```

## Usage Examples

### Basic Colored Output

For sourcing in your local context, see [README.md](../../README.md).

```bash
#!/bin/bash
source bach.sh

# Initialize colors
bach term_utils::declare_colors

# Use colors in output
echo "${RED}Error message${RESET}"
echo "${GREEN}Success message${RESET}"
echo "${YELLOW}Warning message${RESET}"
```

### Status Indicators

```bash
#!/bin/bash
source bach.sh

bach term_utils::declare_colors

# Display status with colors
echo "${GREEN}[✓]${RESET} Operation succeeded"
echo "${RED}[✗]${RESET} Operation failed"
echo "${YELLOW}[!]${RESET} Warning detected"
echo "${BLUE}[ℹ]${RESET} Information message"
```

### Formatted Headers

```bash
#!/bin/bash
source bach.sh

bach term_utils::declare_colors

# Create colored header
printf "%s" "$BG_BLUE"
printf "%s%s" "$WHITE" "$BOLD"
printf "%*s\n" 30 "  Application Header  "
printf "%s" "$RESET"

printf "%s%sVersion:%s 1.0.0\n" "$CYAN" "$BOLD" "$RESET"
```

### Styled Text

```bash
#!/bin/bash
source ../../libs/term_utils.sh

bach term_utils::declare_colors

# Bold and colored text
echo "${BOLD}${GREEN}Important information${RESET}"

# Underlined text
echo "${UNDERLINE}${BLUE}Click here${RESET}"

# Dimmed text
echo "${DIM}This is less important${RESET}"
```

### Color Tables

```bash
#!/bin/bash
source ../../libs/term_utils.sh

bach term_utils::declare_colors

# Table header
printf "%s%-15s %-20s %-10s%s\n" "$BOLD$CYAN" "Name" "Description" "Status" "$RESET"
printf "%s%s%s\n" "$DIM" "$(printf '%*s' 45 | tr ' ' '-')" "$RESET"

# Table rows with status indicators
printf "%-15s %-20s %s[✓]%s\n" "Feature1" "Working correctly" "$GREEN" "$RESET"
printf "%-15s %-20s %s[✗]%s\n" "Feature2" "Needs attention" "$RED" "$RESET"
```

## Common Use Cases

### 1. Application Messages

```bash
#!/bin/bash
source ../../../libs/term_utils.sh

bach term_utils::declare_colors

show_message() {
    local level="$1"
    local message="$2"

    case "$level" in
        error)
            echo "${RED}[ERROR]${RESET} $message"
            ;;
        warn)
            echo "${YELLOW}[WARN]${RESET} $message"
            ;;
        info)
            echo "${BLUE}[INFO]${RESET} $message"
            ;;
        success)
            echo "${GREEN}[OK]${RESET} $message"
            ;;
    esac
}

show_message error "Configuration not found"
show_message warn "Using default values"
show_message info "Initializing service"
show_message success "Service started"
```

### 2. Progress Display

```bash
#!/bin/bash
source ../../../libs/term_utils.sh

bach term_utils::declare_colors

show_progress() {
    local current=$1
    local total=$2
    local percentage=$((current * 100 / total))

    printf "%s[" "$CYAN"
    printf "%-${total}s" $(printf '#%.0s' $(seq 1 $current))
    printf "%s] %3d%%\r" "$RESET" "$percentage"
}

for i in {0..100}; do
    show_progress $i 100
    sleep 0.05
done
echo ""
echo "${GREEN}Complete!${RESET}"
```

### 3. Log Output Formatting

```bash
#!/bin/bash
source ../../../libs/term_utils.sh

bach term_utils::declare_colors

log() {
    local level="$1"
    local message="$2"

    case "$level" in
        DEBUG)
            echo "${DIM}[DEBUG]${RESET} $message" >&2
            ;;
        INFO)
            echo "${BLUE}[INFO]${RESET} $message" >&2
            ;;
        WARN)
            echo "${YELLOW}[WARN]${RESET} $message" >&2
            ;;
        ERROR)
            echo "${RED}[ERROR]${RESET} $message" >&2
            ;;
    esac
}

log DEBUG "Starting application"
log INFO "Loading configuration"
log WARN "Cache not found, using defaults"
log ERROR "Failed to open file"
```

### 4. Interactive Menus

```bash
#!/bin/bash
source ../../../libs/term_utils.sh

bach term_utils::declare_colors

show_menu() {
    printf "\n%s%s=== Main Menu ===%s\n" "$BOLD" "$CYAN" "$RESET"
    printf "%s1)%s Option One\n" "$GREEN" "$RESET"
    printf "%s2)%s Option Two\n" "$GREEN" "$RESET"
    printf "%s3)%s Exit\n" "$RED" "$RESET"
    printf "\n%s%sEnter choice:%s " "$BOLD" "$YELLOW" "$RESET"
}

show_menu
```

## Output Example

When you run the demo, you'll see colored output demonstrating:

```
========================================
BACH Term Utils Library Demonstration
========================================

1. Declaring Colors
===================
RED - Sample text in RED
GREEN - Sample text in GREEN
YELLOW - Sample text in YELLOW
BLUE - Sample text in BLUE
...

4. Practical Use Case - Status Messages
======================================
[✓] Operation succeeded
[!] Warning detected
[✗] Operation failed
[ℹ] Information message
...
```

## Key Points

- **Terminal Detection**: Works with various terminal emulators
- **Fallback Support**: Gracefully handles terminals without color support
- **Reset Needed**: Always use `$RESET` after color to prevent text spillover
- **Compatibility**: POSIX-compatible color codes
- **Performance**: Efficient color rendering for large outputs
