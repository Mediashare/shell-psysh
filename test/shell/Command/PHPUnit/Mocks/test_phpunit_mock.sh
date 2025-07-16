#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "phpunit mock"

# Test 1: Basic mock creation
echo "📝 Test 1: Basic mock creation"

test_session_sync "Basic mock creation" \
    --step "phpunit:create TestService; phpunit:mock stdClass" \
    --expect "✅" \
    --context phpunit


# Test 2: Mock with custom variable name
echo "📝 Test 2: Mock with custom variable name"

test_session_sync "Mock with custom variable name" \
    --step "phpunit:create UserService; phpunit:mock stdClass customMock" \
    --expect "✅" \
    --context phpunit


# Test 3: Mock with specific methods
echo "📝 Test 3: Mock with specific methods"

test_session_sync "Mock with specific methods" \
    --step "phpunit:create EmailService; phpunit:mock stdClass emailMock --methods=send,validate" \
    --expect "✅" \
    --context phpunit


# Test 4: Partial mock creation
echo "📝 Test 4: Partial mock creation"

test_session_sync "Partial mock creation" \
    --step "phpunit:create ServiceTest; phpunit:mock stdClass partialMock --partial" \
    --expect "✅" \
    --context phpunit


# Test 5: Mock with namespace class
echo "📝 Test 5: Mock with namespace class"

test_session_sync "Mock with namespace class" \
    --step "phpunit:create NamespaceTest; class App\Service\EmailService { public function send() {} }; phpunit:mock App\Service\EmailService" \
    --expect "✅" \
    --context phpunit


# Test 6: Error handling - no test created first
echo "📝 Test 6: Error handling - no test created first"
echo 'phpunit:mock stdClass' | $PSYSH_CMD --no-interactive > /tmp/psysh_mock_6.out 2>&1 || true
if grep -q -E "(Aucun test|test actuel|error)" /tmp/psysh_mock_6.out; then
else
    cat /tmp/psysh_mock_6.out
fi

# Test 7: Error handling - no class name

test_session_sync "Error handling - no test created first" \
    --step "✅ Error handling works; ❌ Error handling failed; 📝 Test 7: Error handling - no class name; phpunit:create TestService; phpunit:mock" \
    --expect "✅" \
    --context phpunit


# Test 8: Mock interface
echo "📝 Test 8: Mock interface"

test_session_sync "Mock interface" \
    --step "phpunit:create InterfaceTest; interface TestInterface { public function test(); }; phpunit:mock TestInterface" \
    --expect "✅" \
    --context phpunit


# Test 9: Multiple mocks in same test
echo "📝 Test 9: Multiple mocks in same test"

test_session_sync "Multiple mocks in same test" \
    --step "phpunit:create MultiMockTest; phpunit:mock stdClass firstMock; phpunit:mock stdClass secondMock" \
    --expect "✅" \
    --context phpunit


# Test 10: Mock with method list
echo "📝 Test 10: Mock with method list"

test_session_sync "Mock with method list" \
    --step "phpunit:create MethodListTest; phpunit:mock stdClass methodMock --methods=create,update,delete" \
    --expect "✅" \
    --context phpunit


# Clean up
rm -f /tmp/psysh_mock_*.out


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
