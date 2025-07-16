#!/bin/bash

# Test phpunit:assert command
# Tests all options and scenarios for assertions WITHOUT quotes (new syntax)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"


echo "🧪 Testing phpunit:assert command..."

# Test 1: Basic assertion without quotes
echo "📝 Test 1: Basic assertion without quotes"

    --step "phpunit:create TestService; phpunit:assert "42 === 42"" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Basic assertion without quotes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 2: String comparison without quotes
echo "📝 Test 2: String comparison without quotes"

    --step "phpunit:create UserService; phpunit:assert "\"John Doe\" == \"John Doe\""" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "String comparison without quotes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 3: Array count assertion
echo "📝 Test 3: Array count assertion"

    --step "phpunit:create DataService; phpunit:assert "count([1, 2, 3, 4, 5]) > 0"" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Array count assertion" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 4: instanceof assertion
echo "📝 Test 4: instanceof assertion"

    --step "phpunit:create ObjectService; phpunit:assert "(new stdClass()) instanceof stdClass"" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "instanceof assertion" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 5: Boolean assertion
echo "📝 Test 5: Boolean assertion"

    --step "phpunit:create BooleanService; phpunit:assert "true === true"" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Boolean assertion" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 6: Null assertion
echo "📝 Test 6: Null assertion"

    --step "phpunit:create NullService; phpunit:assert "null === null"" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Null assertion" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 7: Empty array assertion
echo "📝 Test 7: Empty array assertion"

    --step "phpunit:create EmptyService; phpunit:assert "empty([])"" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Empty array assertion" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 8: Complex expression assertion
echo "📝 Test 8: Complex expression assertion"

    --step "phpunit:create ComplexService; phpunit:assert "isset([\"debug\" => true][\"debug\"]) && [\"debug\" => true][\"debug\"] === true"" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Complex expression assertion" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 9: Numeric comparison assertion
echo "📝 Test 9: Numeric comparison assertion"

    --step "phpunit:create NumericService; phpunit:assert "99.99 >= 50.0"" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Numeric comparison assertion" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 10: Error handling - no test created first
echo "📝 Test 10: Error handling - no test created first"
echo 'phpunit:assert "42 === 42"' | $PSYSH_CMD --no-interactive > /tmp/psysh_assert_10.out 2>&1 || true
if grep -q -E "(Aucun test|test actuel|error)" /tmp/psysh_assert_10.out; then
else
    cat /tmp/psysh_assert_10.out
fi

# Test 11: Error handling - no assertion provided

    --step "✅ Error handling works; ❌ Error handling failed; 📝 Test 11: Error handling - no assertion provided; phpunit:create TestService; phpunit:assert" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Error handling - no test created first" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 12: Old syntax with quotes (compatibility)
echo "📝 Test 12: Old syntax with quotes (compatibility)"

    --step "phpunit:create LegacyService; phpunit:assert "42 === 42"" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Old syntax with quotes (compatibility)" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Clean up
rm -f /tmp/psysh_assert_*.out

echo "✨ phpunit:assert tests completed"
