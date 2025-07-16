#!/bin/bash

# Test script for Expect commands
# Tests PHPUnitExceptionAssertCommand with aliases

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Expect Commands"
echo ""

# Test original phpunit:expect-exception command
echo "🔍 Testing original phpunit:expect-exception command..."
    --step "phpunit:expect-exception 'InvalidArgumentException' 'throw new InvalidArgumentException();'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Test exception expected" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit
echo ""

# Test original phpunit:expect-no-exception command
echo "🔍 Testing original phpunit:expect-no-exception command..."
    --step "phpunit:expect-no-exception 'echo \"No exception here\";'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Test no exception expected" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit
echo ""

# Test new phpunit:assert-exception alias
echo "🔍 Testing new phpunit:assert-exception alias..."
    --step "phpunit:assert-exception 'RuntimeException' 'throw new RuntimeException(\"Test error\");'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Test assertion exception" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit
echo ""

# Test new phpunit:assert-no-exception alias
echo "🔍 Testing new phpunit:assert-no-exception alias..."
    --step "phpunit:assert-no-exception 'return 42;'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Test assertion no exception" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit
echo ""

# Test exception with message validation
echo "🔍 Testing exception with message validation..."
    --step "phpunit:expect-exception 'Exception' 'throw new Exception(\"Custom message\");' --message='Custom message'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Test exception expected" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit
echo ""

# Test expected failure - no exception when one is expected
echo "🔍 Testing expected failure - no exception when one is expected..."
    --step "phpunit:expect-exception 'Exception' 'echo \"No exception here\";'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Test exception expected" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit
echo ""

# Test expected failure - exception when none is expected
echo "🔍 Testing expected failure - exception when none is expected..."
    --step "phpunit:expect-no-exception 'throw new Exception(\"Unexpected exception\");'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Test no exception expected" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit
echo ""

# Test combined scenarios with other commands
echo "🔍 Testing combined scenarios..."
    --step "phpunit:assert-no-exception 'return 123;'; phpunit:assert-equals 123 123" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Test assertion no exception" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit
echo ""

test_summary
