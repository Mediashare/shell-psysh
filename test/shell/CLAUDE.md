# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a comprehensive test suite for PsySH (PHP Shell) command functionality, specifically designed to test a custom `monitor` command that enables real-time monitoring and testing of PHP code execution. The repository contains an extensive collection of shell scripts that test various PHP features, Symfony services, and advanced PHP concepts through automated PsySH sessions.

## Architecture

### Core Structure
```
shell/
├── run.sh                    # Main test runner with interactive menus
├── config.sh                 # Global configuration and environment variables
├── lib/                      # Core testing libraries
│   ├── display_utils.sh      # Output formatting and display utilities  
│   ├── psysh_utils.sh        # PsySH-specific utilities
│   ├── test_helper.sh        # Basic test helper functions
│   ├── timeout_handler.sh    # Timeout management for tests
│   ├── unified_test_executor.sh # Main test execution engine
│   └── func/
│       ├── loader.sh         # Function loader and environment setup
│       └── test_session_sync_enhanced.sh # Advanced session sync testing
├── Command/                  # Test categories organized by functionality
│   ├── Assert/              # Assertion-based tests
│   ├── Config/              # Configuration tests  
│   ├── Demo/                # Demo and example tests
│   ├── Expect/              # Expectation-based tests
│   ├── Mock/                # Mocking and test double tests
│   ├── Monitor/             # Core monitor command tests (27 files)
│   ├── Other/               # Miscellaneous command tests
│   ├── Performance/         # Performance and benchmarking tests
│   ├── PHPUnit/             # PHPUnit integration tests
│   ├── Runner/              # Test runner functionality tests
│   ├── Snapshot/            # Snapshot testing capabilities
│   └── Symfony/             # Symfony-specific tests
└── kernel/                  # Symfony kernel for integration testing
    ├── composer.json        # Symfony 7.3 dependencies
    ├── src/                 # Symfony application source
    └── vendor/              # Composer dependencies
```

### Key Testing Components

1. **Test Session Synchronization**: Advanced system for maintaining state across multiple PsySH commands in a single session
2. **Monitor Command Testing**: Comprehensive testing of a custom PsySH monitor command that provides real-time code monitoring
3. **Multi-step Testing**: Support for complex test scenarios with multiple interconnected steps
4. **Error Handling**: Robust error detection and reporting with detailed stack traces
5. **Performance Monitoring**: Built-in performance metrics and timing analysis

## Common Commands

### Running Tests

**Interactive mode (recommended for development):**
```bash
./run.sh
```

**Run all tests automatically:**
```bash
./run.sh --all
```

**Simple mode with minimal output:**
```bash
./run.sh --simple
```

**Debug mode with detailed output:**
```bash
./run.sh --debug
```

**Simple mode with pause on failure:**
```bash
./run.sh --simple --pause-on-fail
```

### Test Categories

**Run specific test categories:**
```bash
# Basic tests (variables, functions, classes)
./run.sh  # Choose option 3

# Real-time and debug tests  
./run.sh  # Choose option 4

# Symfony service tests
./run.sh  # Choose option 5

# Advanced PHP tests (namespaces, traits, generators)
./run.sh  # Choose option 6

# Regression tests
./run.sh  # Choose option 7
```

**Run individual tests:**
```bash
# Navigate to specific test directory
cd Command/Monitor
./01_test_basic_variables.sh

# Or run from main directory
./Command/Monitor/01_test_basic_variables.sh
```

### Development and Debugging

**Enable debug mode for detailed output:**
```bash
export DEBUG_MODE=1
./run.sh
```

**Run tests with performance metrics:**
```bash
export SHOW_PERFORMANCE_METRICS=1
./run.sh
```

**Save detailed logs:**
```bash
export SAVE_DETAILED_LOGS=1
./run.sh
```

## Testing Framework Features

### Session Synchronization
The test framework includes advanced session synchronization capabilities that allow:
- Maintaining variable state across multiple PsySH commands
- Testing complex multi-step scenarios
- Bidirectional synchronization between test steps
- Real-time monitoring of PHP execution

### Test Execution Modes
- **Interactive Mode**: Full UI with test previews and user control
- **Auto Mode**: Automatic execution of all tests
- **Simple Mode**: Minimal output for CI/CD environments  
- **Debug Mode**: Detailed logging and error analysis
- **Pause-on-Fail**: Automatic pause when tests fail for investigation

### Error Handling and Debugging
- Comprehensive error detection with pattern matching
- Real-time stack trace generation for shell execution
- Detailed failure analysis with context
- Integration with PsySH error reporting

## Test Categories

### Monitor Tests (Command/Monitor/)
Core functionality tests for the monitor command:
- **01-05**: Basic variables, functions, classes, Symfony services, performance
- **06-10**: Real-time display, debug mode, error handling, memory usage, multiline code
- **11-15**: Data processing, image processing, closures, stress calculations, exceptions
- **16-20**: Namespaces, generators, traits, iterators, performance comparisons
- **21-27**: Expression results, error line numbers, responsiveness, sync features, compatibility

### PHPUnit Integration (Command/PHPUnit/)
Tests for PHPUnit integration features:
- Test creation and management
- Assertion testing
- Mock object testing
- Code generation for PHPUnit tests
- Synchronization with PHPUnit execution

### Performance Tests (Command/Performance/)
- Performance benchmarking
- Memory usage analysis
- Execution time measurements
- Resource utilization monitoring

## Development Guidelines

### Adding New Tests
1. Place test files in appropriate Command subdirectory
2. Follow naming convention: `##_test_description.sh`
3. Use the loader framework: `source "$SCRIPT_DIR/../../lib/func/loader.sh"`
4. Initialize environment: `init_test_environment`
5. Use `test_session_sync` for multi-step tests
6. Clean up: `cleanup_test_environment`

### Test Script Structure
```bash
#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

init_test_environment
init_test "Test Description"

test_session_sync "Test Name" \
    --step 'PHP code to execute' \
    --context psysh \
    --psysh \
    --tag "session_name" \
    --expect 'expected_output' \
    --output-check exact

test_summary
cleanup_test_environment
exit $([[ $FAIL_COUNT -gt 0 ]] && echo 1 || echo 0)
```

### Configuration Variables
Key environment variables defined in `config.sh`:
- `DEBUG_MODE`: Enable detailed debugging output
- `AUTO_MODE`: Run tests automatically without user interaction
- `SIMPLE_MODE`: Minimal output mode
- `PAUSE_ON_FAIL`: Pause execution on test failures
- `PSYSH_BINARY`: Path to PsySH executable

## Dependencies

### System Requirements
- Bash 4.0+ 
- PHP 8.2+
- PsySH (PHP Shell)
- Symfony 7.3+ (for kernel tests)

### PHP Dependencies (kernel/composer.json)
- symfony/console: 7.3.*
- symfony/framework-bundle: 7.3.*
- symfony/dotenv: 7.3.*
- symfony/runtime: 7.3.*

### Installation
```bash
cd kernel
composer install
```

## Advanced Features

### Custom Monitor Command
The tests are designed around a custom PsySH monitor command that provides:
- Real-time monitoring of PHP code execution
- Variable state tracking across commands
- Performance metrics collection
- Integration with Symfony services

### Test Synchronization
Advanced synchronization features allow:
- Multi-step test scenarios with shared state
- Bidirectional data flow between test steps
- Session persistence across command executions
- Error propagation and handling

### Performance Analysis
Built-in performance monitoring includes:
- Execution time measurement
- Memory usage tracking
- Resource utilization analysis
- Comparative performance testing