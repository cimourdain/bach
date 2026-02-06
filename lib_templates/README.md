# Bash libraries templates and examples

This directory contains examples and templates to write and use bash libraries.

Its objective is to clarify the following points in order to clarify usecases where they are the most appropriate.

- Impact on declared script declared names to:
  - Prevent conflicts with existing var/functions with the same name as the library
  - Prevent exposition of private var/functions of the library
- Impact on performance: What is re-declared upon lib execution
- Prevent/Manage redundant sourcing and re-declaration of the library
- Usage:
  - Arguments management
  - Usage documentation
  - Errors handling