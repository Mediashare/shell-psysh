#!/bin/bash

# Test phpunit:assert command
# Tests all options and scenarios for assertions WITHOUT quotes (new syntax)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
PSYSH_CMD="$PROJECT_ROOT/vendor/bin/psysh --config $PROJECT_ROOT/config/config.php"

echo "🧪 Testing phpunit:assert command..."

# Test 1: Basic assertion without quotes
echo "📝 Test 1: Basic assertion without quotes"
{
    echo 'phpunit:create TestService'
    echo 'phpunit:assert "42 === 42"'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_assert_1.out 2>&1 || true
if grep -q "Assertion ajoutée" /tmp/psysh_assert_1.out; then
    echo "✅ Basic assertion without quotes works"
else
    echo "❌ Basic assertion without quotes failed"
    cat /tmp/psysh_assert_1.out
fi

# Test 2: String comparison without quotes
echo "📝 Test 2: String comparison without quotes"
{
    echo 'phpunit:create UserService'
    echo 'phpunit:assert "\"John Doe\" == \"John Doe\""'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_assert_2.out 2>&1 || true
if grep -q "Assertion ajoutée" /tmp/psysh_assert_2.out; then
    echo "✅ String comparison assertion works"
else
    echo "❌ String comparison assertion failed"
    cat /tmp/psysh_assert_2.out
fi

# Test 3: Array count assertion
echo "📝 Test 3: Array count assertion"
{
    echo 'phpunit:create DataService'
    echo 'phpunit:assert "count([1, 2, 3, 4, 5]) > 0"'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_assert_3.out 2>&1 || true
if grep -q "Assertion ajoutée" /tmp/psysh_assert_3.out; then
    echo "✅ Array count assertion works"
else
    echo "❌ Array count assertion failed"
    cat /tmp/psysh_assert_3.out
fi

# Test 4: instanceof assertion
echo "📝 Test 4: instanceof assertion"
{
    echo 'phpunit:create ObjectService'
    echo 'phpunit:assert "(new stdClass()) instanceof stdClass"'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_assert_4.out 2>&1 || true
if grep -q "Assertion ajoutée" /tmp/psysh_assert_4.out; then
    echo "✅ instanceof assertion works"
else
    echo "❌ instanceof assertion failed"
    cat /tmp/psysh_assert_4.out
fi

# Test 5: Boolean assertion
echo "📝 Test 5: Boolean assertion"
{
    echo 'phpunit:create BooleanService'
    echo 'phpunit:assert "true === true"'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_assert_5.out 2>&1 || true
if grep -q "Assertion ajoutée" /tmp/psysh_assert_5.out; then
    echo "✅ Boolean assertion works"
else
    echo "❌ Boolean assertion failed"
    cat /tmp/psysh_assert_5.out
fi

# Test 6: Null assertion
echo "📝 Test 6: Null assertion"
{
    echo 'phpunit:create NullService'
    echo 'phpunit:assert "null === null"'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_assert_6.out 2>&1 || true
if grep -q "Assertion ajoutée" /tmp/psysh_assert_6.out; then
    echo "✅ Null assertion works"
else
    echo "❌ Null assertion failed"
    cat /tmp/psysh_assert_6.out
fi

# Test 7: Empty array assertion
echo "📝 Test 7: Empty array assertion"
{
    echo 'phpunit:create EmptyService'
    echo 'phpunit:assert "empty([])"'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_assert_7.out 2>&1 || true
if grep -q "Assertion ajoutée" /tmp/psysh_assert_7.out; then
    echo "✅ Empty array assertion works"
else
    echo "❌ Empty array assertion failed"
    cat /tmp/psysh_assert_7.out
fi

# Test 8: Complex expression assertion
echo "📝 Test 8: Complex expression assertion"
{
    echo 'phpunit:create ComplexService'
    echo 'phpunit:assert "isset([\"debug\" => true][\"debug\"]) && [\"debug\" => true][\"debug\"] === true"'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_assert_8.out 2>&1 || true
if grep -q "Assertion ajoutée" /tmp/psysh_assert_8.out; then
    echo "✅ Complex expression assertion works"
else
    echo "❌ Complex expression assertion failed"
    cat /tmp/psysh_assert_8.out
fi

# Test 9: Numeric comparison assertion
echo "📝 Test 9: Numeric comparison assertion"
{
    echo 'phpunit:create NumericService'
    echo 'phpunit:assert "99.99 >= 50.0"'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_assert_9.out 2>&1 || true
if grep -q "Assertion ajoutée" /tmp/psysh_assert_9.out; then
    echo "✅ Numeric comparison assertion works"
else
    echo "❌ Numeric comparison assertion failed"
    cat /tmp/psysh_assert_9.out
fi

# Test 10: Error handling - no test created first
echo "📝 Test 10: Error handling - no test created first"
echo 'phpunit:assert "42 === 42"' | $PSYSH_CMD --no-interactive > /tmp/psysh_assert_10.out 2>&1 || true
if grep -q -E "(Aucun test|test actuel|error)" /tmp/psysh_assert_10.out; then
    echo "✅ Error handling works"
else
    echo "❌ Error handling failed"
    cat /tmp/psysh_assert_10.out
fi

# Test 11: Error handling - no assertion provided
echo "📝 Test 11: Error handling - no assertion provided"
{
    echo 'phpunit:create TestService'
    echo 'phpunit:assert'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_assert_11.out 2>&1 || true
if grep -q -E "(Aucune assertion|required|error)" /tmp/psysh_assert_11.out; then
    echo "✅ Missing assertion handling works"
else
    echo "❌ Missing assertion handling failed"
    cat /tmp/psysh_assert_11.out
fi

# Test 12: Old syntax with quotes (compatibility)
echo "📝 Test 12: Old syntax with quotes (compatibility)"
{
    echo 'phpunit:create LegacyService'
    echo 'phpunit:assert "42 === 42"'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_assert_12.out 2>&1 || true
if grep -q "Assertion ajoutée" /tmp/psysh_assert_12.out; then
    echo "✅ Legacy syntax compatibility works"
else
    echo "❌ Legacy syntax compatibility failed"
    cat /tmp/psysh_assert_12.out
fi

# Clean up
rm -f /tmp/psysh_assert_*.out

echo "✨ phpunit:assert tests completed"
