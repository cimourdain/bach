# User Messages Library Demo

The **user_msg library** provides a simple interface for displaying formatted, user-friendly messages in bash scripts with support for different message types.

## Capabilities

- ✅ Formatted user-friendly messages
- ✅ Multiple message types (info, warning, error, success, debug)
- ✅ Consistent message formatting
- ✅ Easy integration into scripts and applications
- ✅ Severity level differentiation

## Exposed Functions

### bach user_msg

**Purpose:** Display formatted messages with different severity levels and message types.

**Signature:**
```bash
bach user_msg <message> [message_type]
```

**Arguments:**
- `message` - The message text to display
- `message_type` (optional) - Type of message: `info` (default), `warning`, `error`, `success`, or `debug`

**Returns:** `0` on success

**Output:** Formatted message to stdout with type-specific formatting

**Message Types:**
- **info** - General informational messages (default)
- **warning** - Alerts about potentially problematic situations
- **error** - Error conditions requiring immediate attention
- **success** - Confirmation messages for successful operations
- **debug** - Debug/development information

## Running the Demo

```bash
cd demo/user_messages
bash demo.sh
```

## Usage Examples

### Basic Messages

For sourcing in your local context, see [README.md](../../README.md).

```bash
#!/bin/bash
source bach.sh

# Default info message
bach::user_msg "Configuration loaded successfully"

# Specific message type
bach::user_msg "Cache is close to capacity" "warning"
bach::user_msg "Failed to connect to database" "error"
bach::user_msg "Operation completed" "success"
```

### Message Types

```bash
#!/bin/bash
source bach.sh

# Display different message types
bach::user_msg "This is informational" "info"
bach::user_msg "This is a warning" "warning"
bach::user_msg "This is an error" "error"
bach::user_msg "This is a success message" "success"
bach::user_msg "This is debug info" "debug"
```

### Script Workflow Messages

```bash
#!/bin/bash
source bach.sh

# Report progress through workflow
bach::user_msg "Starting backup process" "info"
# ... perform backup ...
bach::user_msg "Backup completed successfully" "success"
```

### Error Handling with Messages

```bash
#!/bin/bash
source bach.sh

process_file() {
    local file="$1"

    bach::user_msg "Processing: $file" "info"

    if [[ ! -f "$file" ]]; then
        bach::user_msg "File not found: $file" "error"
        return 1
    fi

    # Process file...
    bach::user_msg "File processed successfully" "success"
    return 0
}

process_file "/path/to/data.txt"
```

### Configuration Validation

```bash
#!/bin/bash
source bach.sh

check_config() {
    bach::user_msg "Checking configuration..." "info"

    if [[ -z "$API_KEY" ]]; then
        bach::user_msg "API_KEY not set" "error"
        return 1
    fi

    if [[ -z "$DATABASE_URL" ]]; then
        bach::user_msg "DATABASE_URL not set" "warning"
    fi

    bach::user_msg "Configuration check complete" "success"
    return 0
}
```

## Common Use Cases

### 1. Application Initialization

```bash
#!/bin/bash
source bach.sh

main() {
    bach::user_msg "Initializing application" "info"

    # Initialize components
    bach::user_msg "Loading configuration" "info"
    load_config && bach::user_msg "Configuration loaded" "success" || {
        bach::user_msg "Failed to load configuration" "error"
        return 1
    }

    bach::user_msg "Connecting to database" "info"
    connect_db && bach::user_msg "Database connected" "success" || {
        bach::user_msg "Database connection failed" "error"
        return 1
    }

    bach::user_msg "Application ready" "success"
}
```

### 2. Deployment Script

```bash
#!/bin/bash
source bach.sh

deploy() {
    local version="$1"

    bach::user_msg "Starting deployment of version $version" "info"
    
    # Pre-deployment checks
    bach::user_msg "Running tests..." "info"
    run_tests || {
        bach::user_msg "Tests failed - aborting deployment" "error"
        return 1
    }
    bach::user_msg "Tests passed" "success"

    # Build
    bach::user_msg "Building application..." "info"
    build_app || {
        bach::user_msg "Build failed" "error"
        return 1
    }
    bach::user_msg "Build successful" "success"

    # Deploy
    bach::user_msg "Deploying to production..." "info"
    deploy_to_prod || {
        bach::user_msg "Deployment failed" "error"
        return 1
    }
    bach::user_msg "Deployment complete" "success"
}
```

### 3. Installation Script

```bash
#!/bin/bash
source bach.sh

install() {
    bach::user_msg "Starting installation" "info"

    # Check prerequisites
    bach::user_msg "Checking prerequisites..." "debug"
    check_prerequisites || {
        bach::user_msg "Missing required dependencies" "error"
        return 1
    }

    # Create directories
    bach::user_msg "Creating directories..." "debug"
    mkdir -p "$INSTALL_DIR" || {
        bach::user_msg "Failed to create installation directory" "error"
        return 1
    }

    # Copy files
    bach::user_msg "Copying files..." "debug"
    cp -r "$SOURCE_DIR"/* "$INSTALL_DIR"/ || {
        bach::user_msg "Failed to copy files" "error"
        return 1
    }

    bach::user_msg "Installation complete" "success"
}
```

### 4. Monitoring Script

```bash
#!/bin/bash
source bach.sh

check_services() {
    local -a services=("nginx" "postgresql" "redis")

    for service in "${services[@]}"; do
        if systemctl is-active "$service" &>/dev/null; then
            bach::user_msg "$service is running" "success"
        else
            bach::user_msg "$service is stopped" "warning"
            systemctl start "$service" && \
                bach::user_msg "$service restarted" "success" || \
                bach::user_msg "Failed to restart $service" "error"
        fi
    done
}
```

## Output Example

When you run the demo, you'll see formatted messages like:

```
========================================
BACH User Messages Library Demonstration
========================================

1. Basic User Messages
=====================

This is an info message (default type)

2. Different Message Types
==========================

Info message:
Configuration loaded successfully

Warning message:
Cache is close to capacity

Error message:
Failed to connect to database

...
```

## Key Points

- **Consistent Formatting**: All message types follow a unified format
- **Type-Specific Styling**: Different colors/styles for different message types
- **Simple API**: Easy to integrate into existing scripts
- **No Dependencies**: Only requires bash and the library
- **Readable Output**: Clear, at-a-glance status information
