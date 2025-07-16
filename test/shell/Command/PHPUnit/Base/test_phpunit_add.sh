#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "phpunit add"

# Test 1: Add basic test method
echo "📝 Test 1: Add basic test method"

test_session_sync "Add basic test method" \
    --step "phpunit:create TestService; phpunit:add testBasicMethod" \
    --expect "✅" \
    --context phpunit


# Test 2: Add multiple test methods
echo "📝 Test 2: Add multiple test methods"

test_session_sync "Add multiple test methods" \
    --step "phpunit:create UserService; phpunit:add testCreateUser; phpunit:add testUpdateUser; phpunit:add testDeleteUser" \
    --expect "✅" \
    --context phpunit


# Test 3: Add method with descriptive name
echo "📝 Test 3: Add method with descriptive name"

test_session_sync "Add method with descriptive name" \
    --step "phpunit:create EmailService; phpunit:add testValidateEmailFormat; phpunit:add testSendEmailWithAttachment" \
    --expect "✅" \
    --context phpunit


# Test 4: Error handling - no test created first
echo "📝 Test 4: Error handling - no test created first"
echo 'phpunit:add testWithoutTest' | $PSYSH_CMD --no-interactive > /tmp/psysh_add_4.out 2>&1 || true
if grep -q -E "(Aucun test|test actuel|error)" /tmp/psysh_add_4.out; then
else
    cat /tmp/psysh_add_4.out
fi

# Test 5: Error handling - no method name

test_session_sync "Error handling - no test created first" \
    --step "✅ Error handling works; ❌ Error handling failed; 📝 Test 5: Error handling - no method name; phpunit:create TestService; phpunit:add" \
    --expect "✅" \
    --context phpunit


# Test 6: Add method with camelCase
echo "📝 Test 6: Add method with camelCase"

test_session_sync "Add method with camelCase" \
    --step "phpunit:create PaymentService; phpunit:add testProcessPaymentWithCreditCard; phpunit:add testCalculateDiscountForPremiumUser" \
    --expect "✅" \
    --context phpunit


# Test 7: Add method with underscore
echo "📝 Test 7: Add method with underscore"

test_session_sync "Add method with underscore" \
    --step "phpunit:create DatabaseService; phpunit:add test_database_connection; phpunit:add test_query_execution" \
    --expect "✅" \
    --context phpunit


# Clean up
rm -f /tmp/psysh_add_*.out

# Afficher le résumé
test_summary

# Nettoyer l'environnement de test
cleanup_test_environment

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
