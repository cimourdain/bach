# Bach Library Demonstrations

This folder contains executable demonstrations and documentation for each library in the bach framework.

## Structure

```
demo/
├── AGENT.md                  # Constraints and guidelines for demo creation
├── README.md                 # This file
├── assert/                   # Assert library - testing and validation
│   ├── demo.sh              # Executable demonstration
│   └── README.md            # Usage guide and examples
├── bash_utils/              # String manipulation utilities
│   ├── demo.sh
│   └── README.md
├── log/                     # Logging system
│   ├── demo.sh
│   └── README.md
├── parse_args/              # Command-line argument parsing
│   ├── demo.sh
│   └── README.md
├── term_utils/              # Terminal colors and formatting
│   ├── demo.sh
│   └── README.md
├── user_messages/           # User-friendly message display
│   ├── demo.sh
│   └── README.md
├── cli/                     # [Future] Command-line interface system
│   └── README.md
└── docstring_helpers/       # [Future] Docstring parsing and help generation
    └── README.md
```

## Available Demos

### 🚀 Ready to Use

#### 1. **Assert Library** - Testing and Validation
   - **Purpose**: Unit testing and assertions for bash scripts
   - **Run**: `cd assert && bash demo.sh`
   - **Key Functions**: `assert_contains`, `assert_not_contains`, `assert_empty`, `section`, `print_test_summary`
   - **See**: [assert/README.md](./assert/README.md)

#### 2. **Bash Utils Library** - String Manipulation
   - **Purpose**: Text processing and string utilities
   - **Run**: `cd bash_utils && bash demo.sh`
   - **Key Functions**: `only_alpha`, `only_alphanumeric`, `trim_leading_whitespaces`, `first_index_of_substring`, `unique_hash`
   - **See**: [bash_utils/README.md](./bash_utils/README.md)

#### 3. **Log Library** - Logging System
   - **Purpose**: Structured logging with multiple levels and colors
   - **Run**: `cd log && bash demo.sh`
   - **Key Functions**: `bach::log` with levels (verbose, trace, debug, info, warning, error, fatal)
   - **See**: [log/README.md](./log/README.md)

#### 4. **Parse Args Library** - Argument Parsing
   - **Purpose**: Command-line argument parsing with validation
   - **Run**: `cd parse_args && bash demo.sh`
   - **Key Functions**: `bach::parse_args`, `bach::parse_args::from_spec`, `bach::parse_args::config::set_parsed_args_global_var_name`
   - **See**: [parse_args/README.md](./parse_args/README.md)

#### 5. **Term Utils Library** - Terminal Colors
   - **Purpose**: Terminal color and text formatting
   - **Run**: `cd term_utils && bash demo.sh`
   - **Key Functions**: `bach::term_utils::declare_colors`, `bach::term_utils::colors_tput_demo`
   - **See**: [term_utils/README.md](./term_utils/README.md)

#### 6. **User Messages Library** - User-Friendly Output
   - **Purpose**: Formatted, user-friendly message display
   - **Run**: `cd user_messages && bash demo.sh`
   - **Key Functions**: `bach::user_msg` with types (info, warning, error, success, debug)
   - **See**: [user_messages/README.md](./user_messages/README.md)

### 📋 Future Implementations

#### **CLI Library** (Coming Soon)
   - Complex command-line interface system with subcommand routing
   - See: [cli/README.md](./cli/README.md)

#### **Docstring Helpers Library** (Coming Soon)
   - Docstring parsing and help text generation
   - See: [docstring_helpers/README.md](./docstring_helpers/README.md)

## Quick Start

### Run a Demo

Each library has a `demo.sh` script demonstrating its features:

```bash
# Navigate to a library folder
cd demo/log

# Run the demonstration
bash demo.sh

# Or with output to file
bash demo.sh > output.txt
```

### Learn the API

Each library has a comprehensive `README.md` with:

- **Features**: What the library does
- **Running the Demo**: How to execute the demo
- **Usage Examples**: Code snippets showing real-world usage
- **Common Use Cases**: Practical applications
- **Key Points**: Important notes and best practices

### Explore the Source

Visit the main [libs/](../libs/) directory to see the actual library implementations.

## Demo Script Structure

Each demo script follows this pattern:

```bash
#!/bin/bash

# Prevent re-sourcing
if declare -F function_name &>/dev/null; then
    return 0
fi

# Source the library
source ../../libs/library_name.sh

# Main function
main() {
    # Section 1: Feature demonstration
    # Section 2: Another feature
    # ...
    # Summary
}

# Execute on direct invocation
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## Guidelines

For more information on creating and maintaining library demos, see:

- [AGENT.md](./AGENT.md) - Constraints and standards for all demos
- [README.md](../README.md) - Main Bach framework documentation

## Dependencies

All demos require only:
- Bash 4.0+
- No external tools or dependencies beyond the bach libraries

## Contributing

When adding new library demonstrations:

1. Create a folder: `demo/library_name/`
2. Create `demo.sh` following the template pattern
3. Create `README.md` with features, examples, and use cases
4. Test thoroughly: `cd demo/library_name && bash demo.sh`
5. Update [AGENT.md](./AGENT.md) if adding new constraints

## Tips

- **Environment Variables**: Set `LOG_LEVEL=debug` to see extra logging details
- **Combining Demos**: You can use multiple libraries in a single script
- **Testing**: Run demos to understand how libraries work before integrating them
- **Debugging**: Most demos include detailed output showing what each section does

## License

These demonstrations are part of the Bach framework. See the main [LICENSE](../LICENSE) file for details.
