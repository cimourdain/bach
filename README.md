# BACH - A library manager for bash

Bach is a **library manager for bash**. It aims to:

- **Simplify the import of libraries** in your bash scripts: download `bach.sh` once, then call any library function with a single `bach <lib> ...` command. Bach fetches the library for you when needed.
- **Expose common libraries** covering everyday scripting needs: testing assertions, logging, argument parsing, user messages, terminal utilities and more.
- **Provide a clear and complete documentation** for each library, with reference docs and runnable demos. See the [documentation](https://cimourdain.github.io/bach/).

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

## Libraries versions

Bach downloads a library from the GitHub repository the first time it is used, and sources the local copy on the next calls. The version of a downloaded library is the git reference used to build its download URL:
`<libs_repo_base_url_default><libs_repo_url_version_default><libs_repo_path_default><lib>.sh`

By default, libraries come from the `main` branch (`heads/main/`).

### Use a specific release for all libraries

Set `libs_repo_url_version_default` in your workflow entrypoint, before the first `bach` call. The value is a git reference path and must end with a `/`:

```bash
source lib/bach/bach.sh

# Download libraries from a release tag
__BACH_CONFIG["libs_repo_url_version_default"]="tags/v1.0.0/"

bach log --info "Uses log.sh from the v1.0.0 tag"
```

Pin the `bach.sh` script itself the same way, by changing the reference in its download URL:

```shell
$ curl -L -O --output-dir "lib/bach/" "https://raw.githubusercontent.com/cimourdain/bach/refs/tags/v1.0.0/bach.sh"
```

> A library already present in `libs_local_path_default` is never downloaded again: remove it to fetch another version.

### Use a specific version for one library

The `bach` function does not accept a version per library yet. As a library found locally is never downloaded, download the wanted version of that library yourself in the libraries folder (`lib/bach/` by default); the other libraries keep following the global setting:

```shell
$ curl -L -o "lib/bach/log.sh" "https://raw.githubusercontent.com/cimourdain/bach/refs/tags/v1.0.0/libs/log.sh"
```

```bash
source lib/bach/bach.sh

# log.sh is the one downloaded above, parse_args.sh is downloaded from the main branch
bach log --info "Hello"
bach parse_args "$@"
```

### Use a local version of a library

Bach looks for a library file in the local libraries folder before anything else, so a local file always wins over a remote one.

- To use your own copy of a library, put it in the libraries folder (`lib/bach/<lib>.sh` by default).
- To use a library stored elsewhere, declare its path in `__BACH_LIBS_LOCAL_CUSTOM_PATH`:

```bash
source lib/bach/bach.sh

# Use a local file for the log library
__BACH_LIBS_LOCAL_CUSTOM_PATH["log"]="./my-libs/log.sh"

bach log --info "Uses ./my-libs/log.sh"
```

When your script runs from a clone of the bach repository, libraries are not downloaded: they are linked to the `libs/` folder of the clone, so your working copy is used.
