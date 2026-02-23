.PHONY: test test-libs test-cli help

# Default target
help:
	@echo "Bach Test Suite"
	@echo ""
	@echo "Available targets:"
	@echo "  make test       - Run all tests from the repository"
	@echo "  make test-libs  - Run all tests from libs/ folder"
	@echo "  make test-cli   - Run all tests from tools/cli/ folder"
	@echo ""

# Run all tests from the repository
test:
	@echo "Running all tests..."
	@libs/tests.sh "**/*.test.sh"

# Run tests from libs/ folder
test-libs:
	@echo "Running libs/ tests..."
	@libs/tests.sh "libs/*.test.sh"

# Run tests from tools/cli/ folder
test-cli:
	@echo "Running tools/cli/ tests..."
	@libs/tests.sh "tools/cli/**/*.test.sh"
