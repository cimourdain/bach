# Bash notes, snippets, templates, examples and links


# Resources

- https://github.com/bash-bastion/awesome-bash
- https://google.github.io/styleguide/shellguide.html
- https://bertvv.github.io/cheat-sheets/Bash.html
- https://kalilinuxtutorials.com/bash-functions-explained-syntax-examples-and-best-practices/
- https://thelinuxcode.com/bash-subshells/
- https://github.com/juan131/bash-libraries?tab=readme-ov-file#bash-best-practices


# Files

## Extensions

[Prefer `.sh` extensions](https://google.github.io/styleguide/shellguide.html#file-extensions).

## Permissions

 - Only script entrypoint must be set as executable
 - Library files should not be executable.

```shell
# Given the following folder structure:
main.sh     # main script to be executed
mylib/      # libraries path
├─ main.sh  # library file

# The main script must be executable
$ chmod +x main.sh
$ ls -la .
[...]
drwxrwxrwx 2 [...] mylib
-rwxr-xr-x 1 [...] main.sh

# library files should not be executables
$ chmod -R a-x mylib/*
$ ls -la mylib/
[...]
-rw-rw-rw- 1 [...] main.sh
```

# Comments

## File headers

```bash
#!/bin/bash
#
# Perform hot backups of Oracle databases.
```


## Functions


```bash
#######################################
# Function description
#
# Globals: # Global vars required by function
#   None
# Arguments: # Arguments required
#   None
# Outputs: # Function output (= echo )
#   None
# Returns: # Return code
#   None
#
#######################################
my_func(){
    # ...
}

#######################################
# Function description.
#
# Globals: # Global vars required by function
#   MY_GLOBAL_ONE
#   MY_GLOBAL_TWO
#
# Arguments: # Arguments handled by function
#   1 (str): An important string
#   2 (str, optional): An optional string. Defaults to "undefined"
#
# Outputs: # Function output (= echo )
#   (str): String built from global vars & arguments
#
# Returns:
#   1 if first argument is "strangeValue"
#
#######################################
my_other_func(){
    if [[ "${1}" == "strangeValue" ]];then
        return 1
    fi

    echo "Global 1: ${MY_GLOBAL_ONE}, \
    Global 2: ${MY_GLOBAL_ONE}, \
    Argument1: ${1}, \
    Argument2: ${2:-"undefined"}
    "
}

```


# Conditions
https://www.gnu.org/software/bash/manual/bash.html#Bash-Conditional-Expressions


# Loops

## With counter

```bash
echo "Processing $# arguments:"
for ((i=1; i<=$#; i++)); do
    echo "Argument $i: ${!i}"
done
```

```bash
counter=1
for arg in "$@"; do
    printf "%2d: %s\n" $counter "$arg"
    ((counter++))
done
```

# Arrays
## Declaration

```bash
my_array=( "value1" "value2" "value3" )
```

## Checks
### Check array is not empty
```bash
if [[ ${#my_array[@]} -ne 0 ]]; then
    # do something when array is not empty
fi

if [[ ${#my_array[@]} -eq 0 ]]; then
    # do something when array is empty
fi
```

### Check if an element exists in an array
```bash
if [[ " ${array[*]} " =~ [[:space:]]${value}[[:space:]] ]]; then
    # whatever you want to do when array contains value
fi

if [[ ! " ${array[*]} " =~ [[:space:]]${value}[[:space:]] ]]; then
    # whatever you want to do when array doesn't contain value
fi
```

## Iterate

```bash
my_array=( "value1" "value2" "value3" )
for array_item in "${my_array[@]}";do
    echo "${array_item}"
done
```

## Slicing

```bash
A=( foo bar "a  b c" 42 )
B=("${A[@]:1:2}")
# A[@] returns the contents of the array, :1:2 takes a slice of length 2, starting at index 1.
echo "${B[@]}"        # bar a  b c

C=("${A[@]:1}")       # slice to the end of the array
echo "${C[@]}"        # bar a  b c 42
echo "${C[@]: -2:2}"  # a  b c 42 # The space before the - is necesssary
```

## Array/string conversion
### Array from string conversion
```bash
delimiter=","
my_string="toto,titi,tata"
IFS="${delimiter}" read -a my_array <<< "$my_string"
```

### Array to string conversion
```bash
delimiter=","
my_array=( "value1" "value2" "value3" )
my_str="$(IFS="${delimiter}"; echo "${!my_array[*]}")"
```

# Associative arrays
## Declare
```bash
declare -A my_associative_array
my_associative_array["key1"]="value1"
# or
my_associative_array+=(["key1"]="value1")

# or
declare -A my_associative_array=(
    ["key1"]="value1"
    ["key2"]="value2"
    ["key3"]="value3"
)
```

## Print/Inspect associative array content
```bash
declare -A my_associative_array=(
    ["key1"]="value1"
    ["key2"]="value2"
    ["key3"]="value3"
)

# Print values
echo ${my_associative_array[@]}

# Print keys
echo ${!my_associative_array[@]}

# Print all
printf -v fmtStr '[%s]=%%q\\n' "${!my_associative_array[@]}";printf "$fmtStr" "${my_associative_array[@]}"

# Length
echo ${#my_associative_array[@]}

# Check if key exists
if [[ -n "${my_associative_array["key1"]}" ]]
then
  echo "True"
else
  echo "False"
fi
```

## Iterate
```bash
declare -A my_associative_array=(
    ["key1"]="value1"
    ["key2"]="value2"
    ["key3"]="value3"
)

for key in ${!my_associative_array[@]}
do
  echo "${key}, ${my_associative_array[${key}]}"
done
```