# User Messages Library

## Purpose

The `user_msg.sh` library provides a flexible function for displaying formatted messages to the terminal with support for emoji prefixes and styled headers. All output is sent to stderr using printf for consistency with logging standards. Colors are applied using `tput` for terminal compatibility.

## Features

### Basic Messages
Print simple messages to stderr:
```bash
bach::user_msg "Hello world"
```

### Emoji Prefixes
Add multiple emoji prefixes to messages using `--emoji-name` options:
```bash
bach::user_msg --start --wait "Building project"
# Output: 🚀 ⏳ Building project
```

**Supported Emojis:**
- `--success` ✅
- `--fail` ❌
- `--warning` ⚠️
- `--start` 🚀
- `--kill` 💀
- `--update` ♻️
- `--repair` 🔧
- `--clean` 🧹
- `--test` 🧪
- `--secure` 🔒
- `--unsecure` 🔓
- `--send` 📩
- `--call` ☎️
- `--save` 💾
- `--inspect` 👓
- `--extra` 🎁
- `--wait` ⏳
- `--build` 👷

### Headers
Format text as headers with different styling levels (h1-h5):

#### H1 - Main Headers (Full-width, Cyan)
```bash
bach::user_msg --h1 "Main Title"
```
```
################################################################################
#
#  MAIN TITLE
#
################################################################################
```

#### H2 - Section Headers (Magenta)
```bash
bach::user_msg --h2 "Section Title"
```
```
Section Title
#############
```

#### H3 - Subsection Headers (Yellow)
```bash
bach::user_msg --h3 "Subsection"
```
```
Subsection
###########
```

#### H4 - Minor Headers (Blue, dimmed)
```bash
bach::user_msg --h4 "Minor Header"
```
```
Minor Header
-----------
```

#### H5 - Minimal Headers (Green, dimmed)
```bash
bach::user_msg --h5 "Minimal"
```
```
Minimal
```

## Usage Examples

::: code-group

```bash [With bach]
# Source the library
source lib/bach/bach.sh
# Basic message
bach user_msg "Operation started"

# Message with emoji
bach user_msg --success "Build completed"

# Multiple emojis
bach user_msg --warning --wait "This may take a while"

# Headers
bach user_msg --h1 "Project Setup"
bach user_msg --h2 "Dependencies"
bach user_msg --h3 "Installation Steps"

# Combining headers and messages
bach user_msg --h2 "Build Status"
bach user_msg --success "All tests passed"
```

```bash [Standalone]
# Source the library
source my-libs/user_msg.sh
# Basic message
bach::user_msg "Operation started"

# Message with emoji
bach::user_msg --success "Build completed"

# Multiple emojis
bach::user_msg --warning --wait "This may take a while"

# Headers
bach::user_msg --h1 "Project Setup"
bach::user_msg --h2 "Dependencies"
bach::user_msg --h3 "Installation Steps"

# Combining headers and messages
bach::user_msg --h2 "Build Status"
bach::user_msg --success "All tests passed"
```

:::

::: details Expected output

<pre class="ansi" v-pre>Operation started
✅ Build completed
⚠ ⏳ This may take a while
<span class="c-cyan"></span><span class="c-cyan bold">################################################################################</span>
<span class="c-cyan">#</span>
<span class="c-cyan"></span><span class="c-cyan bold">#  PROJECT SETUP</span>
<span class="c-cyan">#</span>
<span class="c-cyan"></span><span class="c-cyan bold">################################################################################</span>
<span class="c-magenta"></span><span class="c-magenta bold">Dependencies</span>
<span class="c-magenta">##############</span>
<span class="c-yellow"></span><span class="c-yellow bold">Installation Steps</span>
<span class="c-yellow">##################</span>
<span class="c-magenta"></span><span class="c-magenta bold">Build Status</span>
<span class="c-magenta">##############</span>
✅ All tests passed</pre>

:::

## API Reference

### bach::user_msg

Display a formatted message on stderr, with optional emoji prefixes or header styling.

**Signature:**
```bash
bach::user_msg [--emoji-name ...] [--h1|--h2|--h3|--h4|--h5] "<message>"
```

**Options:**
- `--<emoji-name>` - Prefix the message with an emoji (see [Emoji Prefixes](#emoji-prefixes))
- `--h1` .. `--h5` - Format the message as a header (see [Headers](#headers))

**Parameters:**
- `message` - The message to display

**Output:** Writes to stderr

## Technical Details

- **Output:** All messages are sent to stderr using `printf`
- **Colors:** Uses `tput` for applied colors (terminal-compatible)
- **Terminal Width:** H1 headers automatically adapt to terminal width (falls back to 80 columns if detection fails)
- **Text Case:** Header text is automatically converted to uppercase
- **Message format:** `[emoji] [emoji] ... message` with optional color codes
- **Multiple Sourcing:** The library uses source guards to prevent re-loading

## Dependencies

- bash 4.0+ (for associative arrays)
- `tput` (for terminal color/style capabilities)
- `printf` (standard utility)

## Roadmap

- [ ] Move title management to a dedicated library and handle title numbering across subshells
