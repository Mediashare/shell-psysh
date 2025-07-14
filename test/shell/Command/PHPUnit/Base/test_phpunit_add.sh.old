#!/bin/bash

# Test phpunit:add command
# Tests all options and scenarios for adding test methods

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"


echo "🧪 Testing phpunit:add command..."

# Test 1: Add basic test method
echo "📝 Test 1: Add basic test method"
{
    echo 'phpunit:create TestService'
    echo 'phpunit:add testBasicMethod'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_add_1.out 2>&1 || true
if grep -q "Méthode.*ajoutée" /tmp/psysh_add_1.out; then
    echo "✅ Basic method addition works"
else
    echo "❌ Basic method addition failed"
    cat /tmp/psysh_add_1.out
fi

# Test 2: Add multiple test methods
echo "📝 Test 2: Add multiple test methods"
{
    echo 'phpunit:create UserService'
    echo 'phpunit:add testCreateUser'
    echo 'phpunit:add testUpdateUser'
    echo 'phpunit:add testDeleteUser'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_add_2.out 2>&1 || true
if grep -q "Méthode.*ajoutée" /tmp/psysh_add_2.out; then
    echo "✅ Multiple methods addition works"
else
    echo "❌ Multiple methods addition failed"
    cat /tmp/psysh_add_2.out
fi

# Test 3: Add method with descriptive name
echo "📝 Test 3: Add method with descriptive name"
{
    echo 'phpunit:create EmailService'
    echo 'phpunit:add testValidateEmailFormat'
    echo 'phpunit:add testSendEmailWithAttachment'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_add_3.out 2>&1 || true
if grep -q "Méthode.*ajoutée" /tmp/psysh_add_3.out; then
    echo "✅ Descriptive method names work"
else
    echo "❌ Descriptive method names failed"
    cat /tmp/psysh_add_3.out
fi

# Test 4: Error handling - no test created first
echo "📝 Test 4: Error handling - no test created first"
echo 'phpunit:add testWithoutTest' | $PSYSH_CMD --no-interactive > /tmp/psysh_add_4.out 2>&1 || true
if grep -q -E "(Aucun test|test actuel|error)" /tmp/psysh_add_4.out; then
    echo "✅ Error handling works"
else
    echo "❌ Error handling failed"
    cat /tmp/psysh_add_4.out
fi

# Test 5: Error handling - no method name
echo "📝 Test 5: Error handling - no method name"
{
    echo 'phpunit:create TestService'
    echo 'phpunit:add'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_add_5.out 2>&1 || true
if grep -q -E "(required|error|Aucun|missing)" /tmp/psysh_add_5.out; then
    echo "✅ Missing method name handling works"
else
    echo "❌ Missing method name handling failed"
    cat /tmp/psysh_add_5.out
fi

# Test 6: Add method with camelCase
echo "📝 Test 6: Add method with camelCase"
{
    echo 'phpunit:create PaymentService'
    echo 'phpunit:add testProcessPaymentWithCreditCard'
    echo 'phpunit:add testCalculateDiscountForPremiumUser'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_add_6.out 2>&1 || true
if grep -q "Méthode.*ajoutée" /tmp/psysh_add_6.out; then
    echo "✅ CamelCase method names work"
else
    echo "❌ CamelCase method names failed"
    cat /tmp/psysh_add_6.out
fi

# Test 7: Add method with underscore
echo "📝 Test 7: Add method with underscore"
{
    echo 'phpunit:create DatabaseService'
    echo 'phpunit:add test_database_connection'
    echo 'phpunit:add test_query_execution'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_add_7.out 2>&1 || true
if grep -q "Méthode.*ajoutée" /tmp/psysh_add_7.out; then
    echo "✅ Underscore method names work"
else
    echo "❌ Underscore method names failed"
    cat /tmp/psysh_add_7.out
fi

# Clean up
rm -f /tmp/psysh_add_*.out

echo "✨ phpunit:add tests completed"
