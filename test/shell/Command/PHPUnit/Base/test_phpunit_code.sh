#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "phpunit code"

# Test 1: Basic code mode activation
echo "📝 Test 1: Basic code mode activation"

test_session_sync "Basic code mode activation" \
    --step "phpunit:create TestService; phpunit:code; exit" \
    --expect "✅" \
    --context phpunit


# Test 2: Code mode with variable creation
echo "📝 Test 2: Code mode with variable creation"

test_session_sync "Code mode with variable creation" \
    --step "phpunit:create UserService; phpunit:code; $user = new stdClass(); $user->name = "John"; exit" \
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

test_session_sync "Error handling - no test created first" \
    --step "✅ Error handling works; ❌ Error handling failed; 📝 Test 4: Code mode with method calls; phpunit:create ServiceTest; phpunit:code; $data = ["key" => "value"]; $result = array_keys($data); exit" \
    --expect "✅" \
    --context phpunit


# Test 5: Code mode with complex objects
echo "📝 Test 5: Code mode with complex objects"

test_session_sync "Code mode with complex objects" \
    --step "phpunit:create ComplexService; phpunit:code; $config = new stdClass(); $config->debug = true; $config->env = "test"; exit" \
    --expect "✅" \
    --context phpunit


# Clean up
rm -f /tmp/psysh_code_*.out


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
