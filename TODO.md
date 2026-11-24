# TODO

## Generic

### Architecture

Update bach.sh to handle libraries defined with a folder structure.

Current libraries structure:
```
libs/
├── <lib1>.md
├── <lib1>.sh
├── <lib1>.tests.sh
├── <lib2>.md
├── <lib2>.sh
├── <lib2>.tests.sh
└── ...
```

```
libs/
├── AGENT.md                 # Agent documentation of a library structure, code, tests and documentation to ensure consistency between libraries.
├── README.md                # Documentation with a table containing each library name, description and link to its README.md
├── lib1/                    # Folder holding lib1
│   ├── main.sh              # Lib1 functions = existing <lib1>.sh
│   ├── tests.sh              # Library tests = existing <lib1>.tests.sh
│   └── README.md            # Library documentation = existing <lib1>.md
├── lib2/                    # Folder holding lib2
│   ├── main.sh              # Lib1 functions = existing <lib2>.sh
│   ├── tests.sh              # Library tests = existing <lib2>.tests.sh
│   └── README.md            # Library documentation = existing <lib2>.md
```

I expect you to update bach.sh:
- to handle libraries with the above structure
- when installing a library, name the symlink with the library name: lib1/main.sh > libs/bach/lib1.sh

### Demos in lib folders

Move demos in libraries folders as follow: `demo/<LIB>/*` > `libs/<LIB>/demo/*`
 - Capabilities, exposed features, env vars etc. from the demo README must be moved to the library README so the demo readme only contains its executions instructions and details of the features showcased by the demo.sh

### AGENT instructions

Create a root AGENT.md file with the required element to understand the project context, structure, requirements and usage (refer to .skill/ folder for technical constraints).

Ensure it states that:
  - after every agent action on a library:
   - Ensure updates reflect in the library tests.sh file
   - Ensure the library README.md reflect the updates
   - If applicable, reflect the update impact in the library demo
  - After any update:
    - Tests: Run ./tests.sh, all libs/<LIB>.tests.sh and libs/<LIB>/demo/demo.sh files ensure no error was raised
    - Documentation files are up to date

## Project documentation

- In the main README.md, refer to the libs/README.md for details on the list of provided libraries
- Create a CONTRIBUTE.md


## Bash setup (to refine)

- [ ] bach::setup > init global variables
- [ ] 🎁 Init from a file

## Git local repo management from dotfiles (to refine)

Create a git repo management library from ../../dotfiles/cli/cmd/git/func

Create a distinct vscode library to manage repo/workspace opening. (to refine)

## Color library from dotfiles (to refine)

Create a color library from bash-utils/colors (and COLORS_TODO.md)

- [ ] Exposed functions interface to refine

## Client (to refine)

Command:
  - Usage docstring
  - Parse arguments
  - Arguments against docstring
  - etc.

## Parse arguments Library: libs/parse_args.sh

### Validate against specification

Done: docopt specification (string or file), `bach::parse_args::from_spec`, see libs/parse_args.md. Remaining: options with argument in short syntax (-o FILE).

`bach::parse_args::from_spec` > Wrapper around `bach::parse_args` to check element is valid against spec.

Spec:
- Formats (txt, json) & source (string, file etc.)
- Usage definition (regex?)
- Options & Flag definition (short/long, required, allowed values etc.)
- Default --help && --version

Option to raise an error for undefined arguments


## Ideas to refine

- lib versioning
- Lib framework ??
- Makefile alternative
- Git/Markdown based wiki