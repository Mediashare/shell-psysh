#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "mock commands"

# Test PHPUnitMockCommand (phpunit:mock)
echo "🔍 Testing phpunit:mock command..."
test_session_sync "Test command" --step "phpunit:mock 'MyClass' --methods='method1,method2' --returns='value1,value2'"
echo ""

# Test PHPUnitMockCommand with constructor arguments
echo "🔍 Testing phpunit:mock with constructor arguments..."
test_session_sync "Test command" --step "phpunit:mock 'DateTime' --constructor-args='2024-01-01'"
echo ""

# Test PHPUnitPartialMockCommand (phpunit:partial-mock)
echo "🔍 Testing phpunit:partial-mock command..."
test_session_sync "Test command" --step "phpunit:partial-mock 'MyClass' --methods='method1' --keep-original='method2,method3'"
echo ""

# Test PHPUnitSpyCommand (phpunit:spy)
echo "🔍 Testing phpunit:spy command..."
test_session_sync "Test command" --step "phpunit:spy 'MyClass' --track-calls"
echo ""

# Test mock with expectations
echo "🔍 Testing mock with expectations..."
test_session_sync "Test command" --step "phpunit:mock 'MyInterface' --expects='once' --method='getValue' --will-return='mocked_value'"
echo ""

# Test spy with method verification
echo "🔍 Testing spy with method verification..."
test_session_sync "Test command" --step "phpunit:spy 'Logger' --verify-calls --method='log' --times=2"
echo ""

# Test partial mock with original behavior
echo "🔍 Testing partial mock with original behavior..."
test_session_sync "Test command" --step "phpunit:partial-mock 'Calculator' --mock-methods='add' --original-methods='subtract,multiply'"
echo ""

# Test combined mock operations
echo "🔍 Testing combined mock operations..."
test_session_sync "Test command" --step "phpunit:mock 'Service'; phpunit:spy 'Logger'; phpunit:partial-mock 'Helper'"
echo ""

# Test mock with complex configuration
echo "🔍 Testing mock with complex configuration..."
test_session_sync "Test command" --step "phpunit:mock 'HttpClient' --methods='get,post' --returns='response1,response2' --expects='exactly,2'"
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
