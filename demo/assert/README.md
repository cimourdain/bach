# Assert Library Demo

The **assert library** provides testing and assertion functions for validating behavior in bash scripts. Perfect for writing unit tests and validation logic.

## Capabilities

- ✅ String containment assertions
- ✅ Negative assertions (string does not contain)
- ✅ Empty value verification
- ✅ Test section organization
- ✅ Test result summaries
- ✅ Structured testing framework

## Exposed Functions

### bach assert::contains

**Purpose:** Verify that a string contains a specific substring.

**Signature:**
```bash
bach assert::contains <haystack> <needle>
```

**Arguments:**
- `haystack` - The string to search in
- `needle` - The substring to search for

**Returns:**
- `0` if substring is found
- `1` if substring is not found

**Output:** Error message to stderr if assertion fails

### bach assert::not_contains

**Purpose:** Verify that a string does NOT contain a substring.

**Signature:**
```bash
bach assert::not_contains <haystack> <needle>
```

**Arguments:**
- `haystack` - The string to search in
- `needle` - The substring that should not exist

**Returns:**
- `0` if substring is not found
- `1` if substring is found

**Output:** Error message to stderr if assertion fails

### bach assert::empty

**Purpose:** Verify that a variable or output is empty.

**Signature:**
```bash
bach assert::empty <value>
```

**Arguments:**
- `value` - The value/variable to check for emptiness

**Returns:**
- `0` if value is empty
- `1` if value is not empty

**Output:** Error message to stderr if assertion fails

### bach assert::section

**Purpose:** Mark and display test sections with formatted headers.

**Signature:**
```bash
bach assert::section <section_name>
```

**Arguments:**
- `section_name` - Name/description of the test section

**Returns:**
- `0` on success

**Output:** Formatted section header to stderr

### bach assert::print_test_summary

**Purpose:** Display overall test results summary.

**Signature:**
```bash
bach assert::print_test_summary
```

**Arguments:** None

**Returns:**
- `0` on success

**Output:** Test summary statistics to stderr

## Running the Demo

```bash
cd demo/assert
bash demo.sh
```

## Usage Examples

### Basic String Assertions

For sourcing in your local context, see [README.md](../../README.md).

```bash
#!/bin/bash
source bach.sh

# Test if a string contains a substring
test_string="The quick brown fox"

bach assert::contains "$test_string" "brown"
echo "✓ String contains 'brown'"

bach assert::not_contains "$test_string" "invisible"
echo "✓ String does not contain 'invisible'"
```

### Testing Function Output

```bash
#!/bin/bash
source bach.sh

process_data() {
    if [[ $# -eq 0 ]]; then
        echo "ERROR: No input"
        return 1
    fi
    echo "SUCCESS: Processed $1"
    return 0
}

# Test successful case
result=$(process_data "test")
bach assert::contains "$result" "SUCCESS"
echo "✓ Function succeeded with input"

# Test error case
result=$(process_data "")
bach assert::contains "$result" "ERROR"
echo "✓ Function correctly handles empty input"
```

### Empty Variable Testing

```bash
#!/bin/bash
source ../../libs/assert.sh

empty=""
config_value=""

# Test if variable is empty
bach assert::empty "$empty"
echo "✓ Variable is empty"

# Test if configuration is unset
bach assert::empty "$config_value"
echo "✓ Config value is not set"
```

### Using Test Sections

```bash
#!/bin/bash
source ../../libs/assert.sh

bach assert::section "String Validation Tests"

test_string="hello@example.com"
bach assert::contains "$test_string" "@"
echo "✓ Contains email delimiter"

bach assert::section "Array Tests"

array=("one" "two" "three")
array_str="${array[@]}"
bach assert::contains "$array_str" "two"
echo "✓ Array contains expected element"
```

### Pattern Validation

```bash
#!/bin/bash
source ../../libs/assert.sh

validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "VALID"
    else
        echo "INVALID"
    fi
}

# Test valid email
result=$(validate_email "user@example.com")
bach assert::contains "$result" "VALID"
echo "✓ Correctly validated email"

# Test invalid email
result=$(validate_email "invalid@")
bach assert::contains "$result" "INVALID"
echo "✓ Correctly rejected invalid email"
```

## Common Use Cases

### 1. Unit Testing Functions

```bash
#!/bin/bash
source ../../../libs/assert.sh

bach assert::section "Math Function Tests"

add() {
    echo $((${1} + ${2}))
}

# Test addition
result=$(add 2 3)
bach assert::contains "$result" "5"
echo "✓ Addition works correctly"
```

### 2. Configuration Validation

```bash
#!/bin/bash
source ../../../libs/assert.sh

check_config() {
    [[ -n "$1" ]] && echo "OK" || echo "MISSING"
}

# Validate required settings
result=$(check_config "$DATABASE_URL")
bach assert::contains "$result" "OK"
echo "✓ DATABASE_URL is configured"
```

### 3. Error Handling Tests

```bash
#!/bin/bash
source ../../../libs/assert.sh

safe_delete() {
    if [[ -z "$1" ]]; then
        echo "ERROR: Path required"
        return 1
    fi
    echo "Deleting: $1"
    return 0
}

# Test error condition
result=$(safe_delete "")
bach assert::contains "$result" "ERROR"
echo "✓ Correctly rejects empty path"
```

### 4. State Verification

```bash
#!/bin/bash
source ../../../libs/assert.sh

check_service_status() {
    local service="$1"
    if systemctl is-active "$service" &>/dev/null; then
        echo "RUNNING"
    else
        echo "STOPPED"
    fi
}

# Verify service state
result=$(check_service_status "nginx")
bach assert::contains "$result" "RUNNING"
echo "✓ Service is running"
```

## Output Example

When you run the demo, you'll see:

```
========================================
BACH Assert Library Demonstration
========================================

1. Testing with bach assert::contains
===============================
String Containment Tests
─────────────────────────

Test string: 'The quick brown fox jumps over the lazy dog'

Testing: 'brown' in string... ✓ PASSED
Testing: 'fox' in string... ✓ PASSED

2. Testing with bach assert::not_contains
===================================
...

3. Testing with bach assert::empty
============================
...

4. Practical Use Case - Function Validation
=========================================
...
```

## Key Points

- **Simple Syntax**: Easy-to-read test assertions
- **Clear Failures**: Failed assertions show which condition failed
- **Composable**: Use multiple assertions to build comprehensive tests
- **Section Organization**: Group related tests with section headers
- **Summary Reports**: Get overview of all test results
