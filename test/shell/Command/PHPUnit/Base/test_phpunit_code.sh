#!/bin/bash

# Test phpunit:code command
# Tests all options and scenarios for interactive code mode

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"


echo "🧪 Testing phpunit:code command..."

# Test 1: Basic code mode activation
echo "📝 Test 1: Basic code mode activation"

    --step "phpunit:create TestService; phpunit:code; exit" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Basic code mode activation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 2: Code mode with variable creation
echo "📝 Test 2: Code mode with variable creation"

    --step "phpunit:create UserService; phpunit:code; $user = new stdClass(); $user->name = "John"; exit" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Code mode with variable creation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 3: Error handling - no test created first
echo "📝 Test 3: Error handling - no test created first"
echo 'phpunit:code' | $PSYSH_CMD --no-interactive > /tmp/psysh_code_3.out 2>&1 || true
if grep -q -E "(Aucun test|test actuel|error)" /tmp/psysh_code_3.out; then
else
    cat /tmp/psysh_code_3.out
fi

# Test 4: Code mode with method calls

    --step "✅ Error handling works; ❌ Error handling failed; 📝 Test 4: Code mode with method calls; phpunit:create ServiceTest; phpunit:code; $data = ["key" => "value"]; $result = array_keys($data); exit" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Error handling - no test created first" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 5: Code mode with complex objects
echo "📝 Test 5: Code mode with complex objects"

    --step "phpunit:create ComplexService; phpunit:code; $config = new stdClass(); $config->debug = true; $config->env = "test"; exit" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Code mode with complex objects" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Clean up
rm -f /tmp/psysh_code_*.out

echo "✨ phpunit:code tests completed"
