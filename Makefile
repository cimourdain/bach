.PHONY: test test-libs help docs-install docs-preview docs-build doc\:fix

# Default target
help:
	@echo "Bach Test Suite"
	@echo ""
	@echo "Available targets:"
	@echo "  make test       - Run all tests from the repository"
	@echo "  make test-libs  - Run all tests from libs/ folder"
	@echo "  make docs-preview - Preview the documentation locally (vitepress)"
	@echo "  make docs-build   - Build the documentation"
	@echo "  make doc:fix      - Refresh the expected outputs of the libraries documentation"
	@echo ""

# Run all tests from the repository
test:
	@echo "Running all tests..."
	@./tests.sh "**/*.test.sh"

# Run tests from libs/ folder
test-libs:
	@echo "Running libs/ tests..."
	@./tests.sh "libs/*.test.sh"

# Documentation (vitepress)
docs-install:
	@npm install

docs-preview: docs-install
	@DOCS_BASE=/ npm run dev

docs-build: docs-install
	@npm run build

# Re-run the usage examples of libs/*.md and refresh their "Expected output" blocks
doc\:fix:
	@python3 docs/scripts/update_outputs.py
