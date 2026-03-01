# BACH - Bash utilities framework

## Usage

```shell
$ mkdir -p lib/bach/
# Download the main bach script
$ curl -L -O --output-dir "lib/bach/" "https://raw.githubusercontent.com/cimourdain/bach/refs/heads/main/bach.sh"
```

Use it in your bash scripts to dynamically import and use the libraries.

```bash
# Source the previously downloaded file to get the `bach` function
source lib/bach/bach.sh

# Optional: define the path where lib scripts will be stored by bach.
#  - It is recommended when your script workflow runs along multiple files/directories
# Example: here we setup once that the bach libs will be stored in the current directory /lib/bach
# All the subscripts using the bach function will use the same path. This step is thus only
# required in your workflow entrypoint.
__BACH_CONFIG["libs_local_path_default"]="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/lib/bach"

# call the bash function using the library function name you want to call as first argument
# eg: call the bash::log function from libs/log.sh of this repository.
bach log "Hello"

# In a more generic way, call functions of libraries from the libs/ folder as follow:
# Given a library file: <THIS_REPO>/libs/my_lib.sh exposing the following functions:
# bach::my_lib () { ... }
# bach::my_lib::other_func () { ... }
# Call the above functions as follow:
bach my_lib ... # call the bach::my_lib function
bach my_lib::other_func ... # call the bach::my_lib::other_func function
```