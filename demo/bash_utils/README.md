# Bash Utils Library Demo

The **bash_utils library** provides a collection of string manipulation utilities for processing and validating text in bash scripts.

## Capabilities

- ✅ Find substring positions with index tracking
- ✅ Extract only alphabetic characters
- ✅ Extract only alphanumeric characters  
- ✅ Trim leading whitespace
- ✅ Generate unique string identifiers
- ✅ Handle various text processing scenarios

## Exposed Functions

### bach bash_utils::string::first_index_of_substring

**Purpose:** Find the first occurrence of a substring and return its index position.

**Signature:**
```bash
bach bash_utils::string::first_index_of_substring <main_string> <substring>
```

**Arguments:**
- `main_string` - The string to search in
- `substring` - The substring to find

**Returns:**
- The 0-based index of the substring's first occurrence
- `-1` if substring is not found

**Output:** Outputs the index to stdout

### bach bash_utils::string::only_alpha

**Purpose:** Extract only alphabetic characters (a-z, A-Z) from a string.

**Signature:**
```bash
bach bash_utils::string::only_alpha <string>
```

**Arguments:**
- `string` - The input string to process

**Returns:**
- `0` on success

**Output:** String with only alphabetic characters to stdout

### bach bash_utils::string::only_alphanumeric

**Purpose:** Extract only alphanumeric characters (a-z, A-Z, 0-9) from a string.

**Signature:**
```bash
bach bash_utils::string::only_alphanumeric <string>
```

**Arguments:**
- `string` - The input string to process

**Returns:**
- `0` on success

**Output:** String with only alphanumeric characters to stdout

### bach bash_utils::string::trim_leading_whitespaces

**Purpose:** Remove leading spaces and tabs from strings.

**Signature:**
```bash
bach bash_utils::string::trim_leading_whitespaces <string>
```

**Arguments:**
- `string` - The input string to trim

**Returns:**
- `0` on success

**Output:** Trimmed string to stdout (preserves trailing spaces and internal spacing)

### bach bash_utils::string::unique_hash

**Purpose:** Generate a unique hash/identifier for strings.

**Signature:**
```bash
bach bash_utils::string::unique_hash <string>
```

**Arguments:**
- `string` - The input string to hash

**Returns:**
- `0` on success

**Output:** Hash string to stdout (consistent identifier for the same input)

## Running the Demo

```bash
cd demo/bash_utils
bash demo.sh
```

## Usage Examples

### Finding Substring Position

For sourcing in your local context, see [README.md](../../README.md).

```bash
#!/bin/bash
source bach.sh

# Use string functions
text="The quick brown fox"
index=$(bach bash_utils::string::first_index_of_substring "$text" "brown")
echo "Index of 'brown': $index"
```

### Extracting Only Alphabetic Characters

```bash
#!/bin/bash
source bach.sh

text="Project-Name_v2.1.0"
alpha=$(bach bash_utils::string::only_alpha "$text")
echo "$alpha"  # Output: ProjectNamev
```

### Sanitizing Filenames

```bash
#!/bin/bash
source bach.sh

# Clean user input for safe filename
user_input="User-Report_2024-Jan!@#"
safe_name=$(bach bash_utils::string::only_alphanumeric "$user_input")
echo "mv /tmp/report /tmp/${safe_name}.txt"
```

### Trimming Leading Whitespace

```bash
#!/bin/bash
source bach.sh

line="    Hello World"
trimmed=$(bach bash_utils::string::trim_leading_whitespaces "$line")
echo "|$trimmed|"  # Output: |Hello World|
```

### Generating Unique Hashes

```bash
#!/bin/bash
source bach.sh

# Create unique identifiers for configuration keys
app_key=$(bach bash_utils::string::unique_hash "my_application")
user_key=$(bach bash_utils::string::unique_hash "user_config")

echo "App ID: $app_key"
echo "User ID: $user_key"
```

## Common Use Cases

### 1. Filename Sanitization

```bash
# Remove special characters for safe filenames
sanitize_filename() {
    local input="$1"
    local safe=$(bach bash_utils::string::only_alphanumeric "$input")
    echo "${safe}.txt"
}

sanitize_filename "User Report 2024-Q1!@#"
# Output: UserReport2024Q1.txt
```

### 2. Configuration Key Validation

```bash
# Ensure config keys only contain valid characters
validate_key() {
    local key="$1"
    local valid=$(bach bash_utils::string::only_alphanumeric "$key")
    
    if [[ "$key" == "$valid" ]]; then
        echo "Valid key: $key"
    else
        echo "Invalid key: $key (contains special characters)"
    fi
}
```

### 3. Text Processing Pipelines

```bash
# Process log lines and extract only alphanumeric identifiers
process_log_line() {
    local line="$1"
    # Remove special characters from identifiers
    local clean_id=$(bach bash_utils::string::only_alphanumeric "$line")
    echo "$clean_id"
}
```

### 4. Leading Whitespace Handling

```bash
# Parse indented configuration files
parse_config_line() {
    local line="$1"
    local trimmed=$(bach bash_utils::string::trim_leading_whitespaces "$line")
    # Process trimmed line
    echo "$trimmed"
}
```

## Output Example

When you run the demo, you'll see:

```
========================================
BACH Bash Utils Library Demonstration
========================================

1. Finding First Index of Substring
====================================
String: 'The quick brown fox jumps over the lazy dog'

Index of 'brown': 10
Index of 'quick': 4
Index of 'dog': 40
Index of 'notfound' (not in string): -1

2. Extract Only Alphabetic Characters
======================================
Original: 'Hello-World_123!'
Alpha only: 'HelloWorld'

...and more demonstrations
```

## Key Points

- **Index Based**: String functions use 0-based indexing (same as bash)
- **Non-Destructive**: All functions return new strings without modifying originals
- **Safe for Filenames**: Use `only_alphanumeric` to create safe filenames
- **Hash Generation**: `unique_hash` produces consistent identifiers for the same input
- **Whitespace Handling**: Trim functions preserve internal spacing while removing leading/trailing
