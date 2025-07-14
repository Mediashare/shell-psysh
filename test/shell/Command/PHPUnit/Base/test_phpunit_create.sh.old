#!/bin/bash

# Test phpunit:create command
# Tests all options and scenarios for creating PHPUnit tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"


echo "🧪 Testing phpunit:create command..."

# Test 1: Basic class creation
echo "📝 Test 1: Basic class creation"
echo 'phpunit:create TestService' | $PSYSH_CMD --no-interactive > /tmp/psysh_test_1.out 2>&1 || true
if grep -q "Test créé" /tmp/psysh_test_1.out; then
    echo "✅ Basic creation works"
else
    echo "❌ Basic creation failed"
    cat /tmp/psysh_test_1.out
fi

# Test 2: Namespace class creation
echo "📝 Test 2: Namespace class creation"
echo 'phpunit:create App\\Service\\UserService' | $PSYSH_CMD --no-interactive > /tmp/psysh_test_2.out 2>&1 || true
if grep -q "Test créé" /tmp/psysh_test_2.out; then
    echo "✅ Namespace creation works"
else
    echo "❌ Namespace creation failed"
    cat /tmp/psysh_test_2.out
fi

# Test 3: Controller class creation
echo "📝 Test 3: Controller class creation"
echo 'phpunit:create App\\Controller\\ApiController' | $PSYSH_CMD --no-interactive > /tmp/psysh_test_3.out 2>&1 || true
if grep -q "Test créé" /tmp/psysh_test_3.out; then
    echo "✅ Controller creation works"
else
    echo "❌ Controller creation failed"
    cat /tmp/psysh_test_3.out
fi

# Test 4: Repository class creation
echo "📝 Test 4: Repository class creation"
echo 'phpunit:create App\\Repository\\UserRepository' | $PSYSH_CMD --no-interactive > /tmp/psysh_test_4.out 2>&1 || true
if grep -q "Test créé" /tmp/psysh_test_4.out; then
    echo "✅ Repository creation works"
else
    echo "❌ Repository creation failed"
    cat /tmp/psysh_test_4.out
fi

# Test 5: Error handling - no class name
echo "📝 Test 5: Error handling - no class name"
echo 'phpunit:create' | $PSYSH_CMD --no-interactive > /tmp/psysh_test_5.out 2>&1 || true
if grep -q -E "(required|error|Aucun|missing)" /tmp/psysh_test_5.out; then
    echo "✅ Error handling works"
else
    echo "❌ Error handling failed"
    cat /tmp/psysh_test_5.out
fi

# Test 6: Complex namespace
echo "📝 Test 6: Complex namespace"
echo 'phpunit:create My\\Domain\\User\\Service\\EmailService' | $PSYSH_CMD --no-interactive > /tmp/psysh_test_6.out 2>&1 || true
if grep -q "Test créé" /tmp/psysh_test_6.out; then
    echo "✅ Complex namespace works"
else
    echo "❌ Complex namespace failed"
    cat /tmp/psysh_test_6.out
fi

# Clean up
rm -f /tmp/psysh_test_*.out

echo "✨ phpunit:create tests completed"
