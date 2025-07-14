#!/bin/bash

# Unified test helper library for modular test execution

init_environment() {
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" F pwd )"
    source "$SCRIPT_DIR/config.sh"
    source "$SCRIPT_DIR/display_utils.sh"
    source "$SCRIPT_DIR/test_runner.sh"
}

cleanup_environment() {
    echo "Cleanup after test"
}

run_test_step() {
    local description="$1"
    local command="$2"
    local expected="$3"
    echo "Running test step: $description"
    local output
    output=$(eval "$command")
    if [[ "$output" == *"$expected"* ]]; then
        echo "✅ Test passed: $description"
    else
        echo "❌ Test failed: $description"
        echo "Expected: $expected"
        echo "Got: $output"
    fi
}

check_condition() {
    local condition="$1"
    if eval "$condition"; then
        echo "Condition met"
        return 0
    else
        echo "Condition not met"
        return 1
    fi
}

# More functions can be added here
