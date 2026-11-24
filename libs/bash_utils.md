# bash_utils.sh - Bash Utilities Library

A collection of small helpers to manipulate strings and arrays in bash scripts.

## Overview

The bash_utils library gathers building-block functions used by the other Bach libraries and useful in any script: find the position of substrings, sanitize strings, compute stable identifiers and sort arrays and format associative arrays (json, markdown, ascii table), using only bash builtins and standard tools (`sha256sum`, `awk`, `sort`).

## Features

- ✅ Substring position lookup (first occurrence, or any of several substrings)
- ✅ String sanitizing (alphabetic only, alphanumeric only, leading whitespaces trimming)
- ✅ Unique identifiers from strings (sha256)
- ✅ In-place numeric array sorting
- ✅ Associative arrays to json, markdown or ascii table strings
- ✅ Results printed on stdout, status code reporting failures

## Usage Examples

The library relies on the `bach` function (for its internal logging and helpers). When used standalone, source `bach.sh` before `bash_utils.sh`.

### Index of a Substring

Get the 0-based position of the first occurrence of a substring. `-1` is returned (with status `1`) when it is not found.

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
bach bash_utils::string::first_index_of_substring "hello world" "world"
bach bash_utils::string::first_index_of_substring "hello world" "hello"
bach bash_utils::string::first_index_of_substring "abcabc" "bc"      # Only the first occurrence

if ! bach bash_utils::string::first_index_of_substring "hello" "xyz"; then
    echo "Substring not found"
fi
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # bash_utils relies on the `bach` function
source my-libs/bash_utils.sh
bach::bash_utils::string::first_index_of_substring "hello world" "world"
bach::bash_utils::string::first_index_of_substring "hello world" "hello"
bach::bash_utils::string::first_index_of_substring "abcabc" "bc"      # Only the first occurrence

if ! bach::bash_utils::string::first_index_of_substring "hello" "xyz"; then
    echo "Substring not found"
fi
```

:::

::: details Expected output

<pre class="ansi" v-pre>6
0
1
-1
Substring not found</pre>

:::

### Cleaning Strings

Keep only the letters, only the letters and digits, or remove the leading whitespaces of a string.

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
raw="  User_42 (admin)!"

echo "Alphabetic:    '$(bach bash_utils::string::only_alpha "$raw")'"
echo "Alphanumeric:  '$(bach bash_utils::string::only_alphanumeric "$raw")'"
echo "Left trimmed:  '$(bach bash_utils::string::trim_leading_whitespaces "$raw")'"
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # bash_utils relies on the `bach` function
source my-libs/bash_utils.sh
raw="  User_42 (admin)!"

echo "Alphabetic:    '$(bach::bash_utils::string::only_alpha "$raw")'"
echo "Alphanumeric:  '$(bach::bash_utils::string::only_alphanumeric "$raw")'"
echo "Left trimmed:  '$(bach::bash_utils::string::trim_leading_whitespaces "$raw")'"
```

:::

::: details Expected output

<pre class="ansi" v-pre>Alphabetic:    'Useradmin'
Alphanumeric:  'User42admin'
Left trimmed:  'User_42 (admin)!'</pre>

:::

### Unique Hash

Compute a stable identifier (sha256) from a string.

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
bach bash_utils::string::unique_hash "hello"
bach bash_utils::string::unique_hash "hello"   # Same string, same hash
bach bash_utils::string::unique_hash "world"
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # bash_utils relies on the `bach` function
source my-libs/bash_utils.sh
bach::bash_utils::string::unique_hash "hello"
bach::bash_utils::string::unique_hash "hello"   # Same string, same hash
bach::bash_utils::string::unique_hash "world"
```

:::

::: details Expected output

<pre class="ansi" v-pre>2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
486ea46224d1bb4fb680f34f7c9ad96a8f24ec88be73ea8e5a6c65260e9cb8a7</pre>

:::

### Index of Any Substring

Look for several substrings at once. The function returns the index **following** the earliest match, and an occurrence index (3rd argument, `0` by default) selects the n-th match in the string. The substrings are given as the name of an array.

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
delimiters=("-" "_")
text="foo-bar_baz"

# End index of the first delimiter found
bach bash_utils::string::index_of_any_substring "$text" delimiters

# End index of the second delimiter found
bach bash_utils::string::index_of_any_substring "$text" delimiters 1

# No match: prints -1 and returns 1
bach bash_utils::string::index_of_any_substring "$text" delimiters 5 || echo "No such occurrence"
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # bash_utils relies on the `bach` function
source my-libs/bash_utils.sh
delimiters=("-" "_")
text="foo-bar_baz"

# End index of the first delimiter found
bach::bash_utils::string::index_of_any_substring "$text" delimiters

# End index of the second delimiter found
bach::bash_utils::string::index_of_any_substring "$text" delimiters 1

# No match: prints -1 and returns 1
bach::bash_utils::string::index_of_any_substring "$text" delimiters 5 || echo "No such occurrence"
```

:::

::: details Expected output

<pre class="ansi" v-pre>4
8
-1
No such occurrence</pre>

:::

### Parsing a "key: value" Line

Combine the helpers to split a line at its first separator and clean both parts.

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
line="   timeout:   30s"
separators=(":" "=")

line=$(bach bash_utils::string::trim_leading_whitespaces "$line")
value_start=$(bach bash_utils::string::index_of_any_substring "$line" separators)

key="${line:0:value_start-1}"
value=$(bach bash_utils::string::trim_leading_whitespaces "${line:value_start}")

echo "key='${key}' value='${value}'"
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # bash_utils relies on the `bach` function
source my-libs/bash_utils.sh
line="   timeout:   30s"
separators=(":" "=")

line=$(bach::bash_utils::string::trim_leading_whitespaces "$line")
value_start=$(bach::bash_utils::string::index_of_any_substring "$line" separators)

key="${line:0:value_start-1}"
value=$(bach::bash_utils::string::trim_leading_whitespaces "${line:value_start}")

echo "key='${key}' value='${value}'"
```

:::

::: details Expected output

<pre class="ansi" v-pre>key='timeout' value='30s'</pre>

:::

### Sorting an Array

Sort an array numerically, in place. The array is given by name.

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
numbers=(10 2 33 1)
bach bash_utils::array::sort numbers

echo "${numbers[*]}"
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # bash_utils relies on the `bach` function
source my-libs/bash_utils.sh
numbers=(10 2 33 1)
bach::bash_utils::array::sort numbers

echo "${numbers[*]}"
```

:::

::: details Expected output

<pre class="ansi" v-pre>1 2 10 33</pre>

:::

### Formatting an Associative Array

Convert an associative array, given by name, to a json, markdown table or ascii table string. Keys are sorted alphabetically.

::: code-group

```bash [With bach]
#!/bin/bash
source lib/bach/bach.sh
declare -A user=([name]="Ada" [role]="admin|dev")
bach bash_utils::assoc_array::to_json user
bach bash_utils::assoc_array::to_markdown user
bach bash_utils::assoc_array::to_ascii user
```

```bash [Standalone]
#!/bin/bash
source lib/bach/bach.sh   # bash_utils relies on the `bach` function
source my-libs/bash_utils.sh
declare -A user=([name]="Ada" [role]="admin|dev")
bach::bash_utils::assoc_array::to_json user
bach::bash_utils::assoc_array::to_markdown user
bach::bash_utils::assoc_array::to_ascii user
```

:::

::: details Expected output

<pre class="ansi" v-pre>{
  "name": "Ada",
  "role": "admin|dev"
}
| Key | Value |
| --- | --- |
| name | Ada |
| role | admin\|dev |
+------+-----------+
| Key  | Value     |
+------+-----------+
| name | Ada       |
| role | admin|dev |
+------+-----------+</pre>

:::

## API Reference

### bach::bash_utils::string::first_index_of_substring

Get the index of the first occurrence of a substring.

**Signature:**
```bash
bach::bash_utils::string::first_index_of_substring "$main_string" "$substring"
```

**Parameters:**
- `$1` (main_string): The string to search in
- `$2` (substring): The substring to find

**Output:** The 0-based index of the first occurrence, or `-1` when not found

**Returns:** `0` if found, `1` otherwise

### bach::bash_utils::string::index_of_any_substring

Get the index following the n-th match of any of several substrings.

**Signature:**
```bash
bach::bash_utils::string::index_of_any_substring "$main_string" substrings_array_name [occurrence_index]
```

**Parameters:**
- `$1` (main_string): The string to search in
- `$2` (substrings_array_name): Name of the array holding the substrings to look for
- `$3` (occurrence_index): Rank of the match to use, among the matches of all substrings sorted by position (default: `0`)

**Output:** The index of the end of the selected match, or `-1` when there is no such match

**Returns:** `0` if found, `1` otherwise

### bach::bash_utils::string::unique_hash

Compute the sha256 hash of a string.

**Signature:**
```bash
bach::bash_utils::string::unique_hash "$main_string"
```

**Output:** The hexadecimal sha256 digest

### bach::bash_utils::string::only_alpha

Remove every character that is not a letter (`A-Z`, `a-z`).

**Signature:**
```bash
bach::bash_utils::string::only_alpha "$main_string"
```

**Output:** The filtered string

### bach::bash_utils::string::only_alphanumeric

Remove every character that is not a letter or a digit (`A-Z`, `a-z`, `0-9`).

**Signature:**
```bash
bach::bash_utils::string::only_alphanumeric "$main_string"
```

**Output:** The filtered string

### bach::bash_utils::string::trim_leading_whitespaces

Remove the whitespaces (spaces, tabs, newlines) at the beginning of a string. Trailing whitespaces are kept.

**Signature:**
```bash
bach::bash_utils::string::trim_leading_whitespaces "$main_string"
```

**Output:** The trimmed string

### bach::bash_utils::array::sort

Sort an array numerically, in place.

**Signature:**
```bash
bach::bash_utils::array::sort array_name
```

**Parameters:**
- `$1` (array_name): Name of the array to sort

### bach::bash_utils::assoc_array::to_json

Convert an associative array to a pretty formatted json object (2 spaces indentation, sorted keys, values are json strings).

**Signature:**
```bash
bach::bash_utils::assoc_array::to_json assoc_name
```

**Parameters:**
- `$1` (assoc_name): Name of the associative array

**Output:** The json string (`{}` for an empty array)

### bach::bash_utils::assoc_array::to_markdown

Convert an associative array to a markdown table with the columns `Key` and `Value` (sorted keys, `|` is escaped, new lines become `<br>`).

**Signature:**
```bash
bach::bash_utils::assoc_array::to_markdown assoc_name
```

**Parameters:**
- `$1` (assoc_name): Name of the associative array

**Output:** The markdown table

### bach::bash_utils::assoc_array::to_ascii

Convert an associative array to an ascii table with the columns `Key` and `Value` (sorted keys, new lines are displayed as `\n`).

**Signature:**
```bash
bach::bash_utils::assoc_array::to_ascii assoc_name
```

**Parameters:**
- `$1` (assoc_name): Name of the associative array

**Output:** The ascii table

## Roadmap

_No feature planned for the moment._

## See Also

- [log.md](log.md) - Logging, used internally by this library
