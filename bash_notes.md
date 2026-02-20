# Bash nodes

# Conditions
https://www.gnu.org/software/bash/manual/bash.html#Bash-Conditional-Expressions


# Arrays
## Check array is not empty
```bash
if [[ ${#printf_data_suffix[@]} -ne 0 ]]; then
    # ...
fi
```

## Check array is empty
```bash
if [[ ${#printf_data_suffix[@]} -eq 0 ]]; then
    # ...
fi
```

## Check if an element exists in an array
```bash
if [[ " ${array[*]} " =~ [[:space:]]${value}[[:space:]] ]]; then
    # whatever you want to do when array contains value
fi

if [[ ! " ${array[*]} " =~ [[:space:]]${value}[[:space:]] ]]; then
    # whatever you want to do when array doesn't contain value
fi
```

## Array from string conversion
```bash
delimiter=","
my_string="toto,titi,tata"
IFS="${delimiter}" read -a my_array <<< "$my_string"
```

## Array to string conversion
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