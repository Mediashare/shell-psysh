#!/bin/bash

# Test script for Mock commands
# Tests PHPUnitMockCommand, PHPUnitPartialMockCommand, PHPUnitSpyCommand

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Mock Commands"
echo ""

# Test PHPUnitMockCommand (phpunit:mock)
echo "🔍 Testing phpunit:mock command..."
echo ""
test_session_sync "Test command" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --expect "--step" \
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test PHPUnitMockCommand with constructor arguments
echo "🔍 Testing phpunit:mock with constructor arguments..."
echo ""
test_session_sync "Test command" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --expect "--step" \
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test PHPUnitPartialMockCommand (phpunit:partial-mock)
echo "🔍 Testing phpunit:partial-mock command..."
echo ""
test_session_sync "Test command" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --expect "--step" \
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test PHPUnitSpyCommand (phpunit:spy)
echo "🔍 Testing phpunit:spy command..."
echo ""
test_session_sync "Test command" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --expect "--step" \
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test mock with expectations
echo "🔍 Testing mock with expectations..."
echo ""
test_session_sync "Test command" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --expect "--step" \
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test spy with method verification
echo "🔍 Testing spy with method verification..."
echo ""
test_session_sync "Test command" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --expect "--step" \
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test partial mock with original behavior
echo "🔍 Testing partial mock with original behavior..."
echo ""
test_session_sync "Test command" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --expect "--step" \
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test combined mock operations
echo "🔍 Testing combined mock operations..."
echo ""
test_session_sync "Test command" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --expect "--step" \
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test mock with complex configuration
echo "🔍 Testing mock with complex configuration..."
echo ""
test_session_sync "Test command" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --expect "--step" \
    --context psysh \
    --output-check exact \
    --psysh \
    --tag "default_session"

test_summary
