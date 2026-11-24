---
name: libs-bash
description: Bash standards for libraries in the BACH project, including shared library design patterns, code organization, and function best practices.
---

# Bash Library Standards (libs/ Level)

This skill applies to bash libraries in the `libs/` directory. Libraries are reusable bash functions and utilities shared across the BACH project.

This skill extends the general bash scripting standards with specific guidelines for library design, structure, and best practices to ensure maintainability and reusability.

## When This Skill Applies

This skill should be automatically invoked when performing actions in the libs/ directory that involve bash scripting, such as:

- Creating new bash scripts or shell scripts
- Editing existing .sh, .bash or files without extension but containing bash shebang (`#!/bin/bash` or similar) as first line
- User requests scripts for automation, deployment, backup, or system tasks
- Reviewing or refactoring bash code
- User mentions: bash, shell script, main function, argument parsing, script structure

## Library Purpose and Scope

Each library should:

- Have a **single, well-defined responsibility**
- Provide reusable functions for multiple projects
- Be independent and not tightly coupled to specific tools

## Library Naming Conventions

- Library filenames: `<library-name>.sh`
- Functions prefixed with `bach::`:
  - Public functions: `bach::<function-name>` (prefer simple names like `bach::log`)
  - Private functions: `bach::__private::<function-name>`
- Global variables: `__BACH_<LIBRARY_NAME>_<VARIABLE_NAME>`

## Library Dependencies

Libraries should:

- Minimize external dependencies
- Rely on bash built-ins where possible
- Clearly document any required external commands
- Use other BACH libraries when appropriate

# Checklist

In addition to the repository-wide bash scripting checklist, libraries must also meet the following criteria:

- [ ] Library use `bach::<library-name>::` prefix for functions
- [ ] Library has a test script in `libs/<library-name>.test.sh` that demonstrates usage and verifies functionality
- [ ] Library has a documentation file `libs/<library-name>.md` with usage instructions and examples, its contents is up to date with the code
