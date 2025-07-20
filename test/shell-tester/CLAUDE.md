# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is PsySH Enhanced - an interactive PHP shell with extended features including PHPUnit integration, monitoring capabilities, and comprehensive testing framework. The project is built on top of the standard PsySH shell and adds significant enhancements for development workflow.

## Core Architecture

### Main Components

**PsySH Core** (`/src/`):
- Base PsySH shell functionality with PHP REPL capabilities
- Command system for interactive PHP execution
- Code cleaning, parsing, and execution pipeline
- Built on Symfony Console component

**Enhanced Services** (`/src/Extended/`):
- `UnifiedSyncService`: Variable synchronization across shell contexts
- `PHPUnitService`: Interactive test creation and execution
- `EnvironmentService`: Framework detection (Symfony, Laravel, generic PHP)
- `MonitoringDisplayService`: Real-time execution monitoring

**Test Framework** (`/test/shell-tester/`):
- Comprehensive shell testing system
- Category-based test organization (Assert, Monitor, PHPUnit, etc.)
- Interactive and automated test execution modes

### Key Services

- **Session Sync**: Maintains variable state across shell sessions and sub-shells
- **PHPUnit Integration**: Create, run, and export tests interactively
- **Environment Detection**: Auto-configures for different PHP frameworks
- **Monitoring**: Real-time display of variable changes and execution flow

## Development Commands

### Building and Testing
```bash
# Run unit tests (PHPUnit)
make test

# Run static analysis
make phpstan

# Build PHAR
make build

# Run comprehensive shell tests
cd test/shell-tester && ./run.sh

# Run tests in simple mode with pause on failure
cd test/shell-tester && ./run.sh --simple --pause-on-fail

# Run tests with debug output
cd test/shell-tester && ./run.sh --debug
```

### Composer Commands
```bash
# Install dependencies
composer install

# Update dependencies  
composer update

# Install development tools
composer bin phpunit install
composer bin phpstan install
```

### Test Execution Modes

**Interactive Mode**: Default test runner with full interface
```bash
./run.sh
```

**Automated Mode**: Run all tests without interaction
```bash  
./run.sh --all
```

**Simple Mode**: Minimal output with test status
```bash
./run.sh --simple
```

**Debug Mode**: Detailed failure analysis and execution traces
```bash
./run.sh --debug --simple --pause-on-fail
```

## Test Structure

### Test Categories
- **Assert**: Basic assertion and validation tests
- **Monitor**: Real-time monitoring and display tests  
- **PHPUnit**: Interactive PHPUnit test creation/execution
- **Config**: Configuration and environment tests
- **Performance**: Load and performance validation
- **Mock**: Mocking and stub functionality

### Test Library (`/test/shell-tester/lib/`)
- `unified_test_executor.sh`: Core test execution engine
- `test_session_sync_enhanced.sh`: Session synchronization testing
- `assertion_utils.sh`: Assertion helpers and validation
- `display_utils.sh`: UI formatting and display utilities
- `psysh_utils.sh`: PsySH interaction utilities

## Key Development Patterns

### Variable Synchronization
The UnifiedSyncService ensures variables persist across:
- Main shell sessions
- Sub-shell executions  
- PHPUnit test contexts
- Monitoring sessions

### Test Organization
Tests are organized in Command/ subdirectories by functionality:
```
Command/
├── Assert/          # Assertion testing
├── Monitor/         # Monitoring tests (01-27)
├── PHPUnit/         # PHPUnit integration (30-35)
├── Config/          # Configuration tests
└── Performance/     # Performance tests
```

### Enhanced Commands
The shell provides extended commands via `src/Extended/Command/`:
- `phpunit:create`, `phpunit:add`, `phpunit:code` - Interactive test development
- `monitor` - Real-time variable monitoring
- Environment-specific commands for Symfony/Laravel projects

## Framework Integration

### Auto-Detection
The EnvironmentService automatically detects and configures for:
- **Symfony**: Loads kernel, services, doctrine
- **Laravel**: Integrates with Artisan, Eloquent
- **Generic PHP**: Standard autoloader integration

### Context Preservation  
Variables and state are maintained across different execution contexts using the UnifiedSyncService, ensuring seamless development workflow.

## Development Notes

- All shell tests should use the `test_session_sync_enhanced.sh` function for consistent variable handling
- New commands should extend the Extended command structure  
- Test files follow naming convention: `test_[category]_[description].sh`
- Debug mode provides detailed execution traces for troubleshooting test failures
- The monitoring system supports real-time display of variable changes during development