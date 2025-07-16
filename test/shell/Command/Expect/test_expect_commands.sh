#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "expect commands"
# Test original phpunit:expect-exception command
echo "🔍 Testing original phpunit:expect-exception command..."
test_session_sync "Test exception expected" \
    --step "phpunit:expect-exception 'InvalidArgumentException' 'throw new InvalidArgumentException();'" \
    --expect "✅" \
    --context phpunit
echo ""

# Test original phpunit:expect-no-exception command
echo "🔍 Testing original phpunit:expect-no-exception command..."
test_session_sync "Test no exception expected" \
    --step "phpunit:expect-no-exception 'echo \"No exception here\";'" \
    --expect "✅" \
    --context phpunit
echo ""

# Test new phpunit:assert-exception alias
echo "🔍 Testing new phpunit:assert-exception alias..."
test_session_sync "Test assertion exception" \
    --step "phpunit:assert-exception 'RuntimeException' 'throw new RuntimeException(\"Test error\");'" \
    --expect "✅" \
    --context phpunit
echo ""

# Test new phpunit:assert-no-exception alias
echo "🔍 Testing new phpunit:assert-no-exception alias..."
test_session_sync "Test assertion no exception" \
    --step "phpunit:assert-no-exception 'return 42;'" \
    --expect "✅" \
    --context phpunit
echo ""

# Test exception with message validation
echo "🔍 Testing exception with message validation..."
test_session_sync "Test exception expected" \
    --step "phpunit:expect-exception 'Exception' 'throw new Exception(\"Custom message\");' --message='Custom message'" \
    --expect "✅" \
    --context phpunit
echo ""

# Test expected failure - no exception when one is expected
echo "🔍 Testing expected failure - no exception when one is expected..."
test_session_sync "Test exception expected" \
    --step "phpunit:expect-exception 'Exception' 'echo \"No exception here\";'" \
    --expect "✅" \
    --context phpunit
echo ""

# Test expected failure - exception when none is expected
echo "🔍 Testing expected failure - exception when none is expected..."
test_session_sync "Test no exception expected" \
    --step "phpunit:expect-no-exception 'throw new Exception(\"Unexpected exception\");'" \
    --expect "✅" \
    --context phpunit
echo ""

# Test combined scenarios with other commands
echo "🔍 Testing combined scenarios..."
test_session_sync "Test assertion no exception" \
    --step "phpunit:assert-no-exception 'return 123;'; phpunit:assert-equals 123 123" \
    --expect "✅" \
    --context phpunit
echo ""

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
