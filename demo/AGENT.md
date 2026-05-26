---
task: Library demonstrations
description: Demonstrate usage of each library in the libs/ directory
---

# Demo Folder Structure and Constraints

This folder contains demonstrations for each library in the `libs/` directory.

## Folder Structure

Each library demo folder follows this structure:

```
demo/
├── AGENT.md                    (This file - constraints and guidelines)
├── log/
│   ├── demo.sh                (Executable demo)
│   └── README.md              (Usage guide)
├── parse_args/
│   ├── demo.sh
│   └── README.md
├── bash_utils/
│   ├── demo.sh
│   └── README.md
├── assert/
│   ├── demo.sh
│   └── README.md
├── term_utils/
│   ├── demo.sh
│   └── README.md
├── user_messages/
│   ├── demo.sh
│   └── README.md
├── cli/
│   └── README.md              (Future implementation notice)
└── docstring_helpers/
    └── README.md              (Future implementation notice)
```

## Constraints for Each Library Demo

### demo.sh File

- **Shebang**: Must start with `#!/bin/bash`
- **Library Sourcing**: Must follow this pattern:
  1. First, source `../../bach.sh` to load the bach framework
  2. Call the bach command to initialize symlinks (if needed for that library)
  3. Source the library directly from either the symlinked path or the parent repo
  ```bash
  source ../../bach.sh
  bach [library_function] &>/dev/null  # Load library via bach if applicable
  source ./lib/bach/[library_name].sh 2>/dev/null || source ../../libs/[library_name].sh
  ```
- **Main Function**: Must have a `main()` function that serves as the entry point
- **Default Execution**: The script must execute `main "$@"` at the end with proper direct execution guards
- **Examples**: The main function should demonstrate all publicly exported functions with:
  - Clear section headers for each function group
  - Comments explaining what each example does
  - Realistic use cases
  - Expected output when applicable

### README.md File

- **Capabilities**: Brief bulleted list of what the library can do
- **Exposed Functions**: Detailed documentation of all publicly exposed functions including:
  - Purpose: What the function does
  - Signature: Function call format with arguments
  - Arguments: Parameter descriptions with types/options
  - Returns: Exit codes and return values
  - Output: Where output goes (stdout/stderr) and format
- **Running the Demo**: Instructions to execute the demo
- **Usage Examples**: Code snippets showing how to use the library in your own scripts:
  - Start with a note: "For sourcing in your local context, see [README.md](../../README.md)"
  - Show example code blocks with `source bach.sh` (not the individual library path)

## Future Implementation

The following libraries require more complex setup and are deferred to future iterations:

- **cli.sh**: Complex command-line routing system with subcommands
- **docstring_helpers.sh**: Docstring parsing and help generation

Placeholder folders with README.md files will be created for these libraries explaining they are not yet implemented.

## Execution

To run a demo:

```bash
cd demo/[library_name]
bash demo.sh
```

All demos should be self-contained and runnable without external dependencies beyond the bach libraries.
