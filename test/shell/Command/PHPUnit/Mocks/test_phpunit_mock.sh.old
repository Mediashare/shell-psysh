#!/bin/bash

# Test phpunit:mock command
# Tests all options and scenarios for creating mocks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"


echo "🧪 Testing phpunit:mock command..."

# Test 1: Basic mock creation
echo "📝 Test 1: Basic mock creation"
{
    echo 'phpunit:create TestService'
    echo 'phpunit:mock stdClass'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_mock_1.out 2>&1 || true
if grep -q -E "(Mock créé|Mock.*créé)" /tmp/psysh_mock_1.out; then
    echo "✅ Basic mock creation works"
else
    echo "❌ Basic mock creation failed"
    cat /tmp/psysh_mock_1.out
fi

# Test 2: Mock with custom variable name
echo "📝 Test 2: Mock with custom variable name"
{
    echo 'phpunit:create UserService'
    echo 'phpunit:mock stdClass customMock'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_mock_2.out 2>&1 || true
if grep -q -E "(Mock créé.*customMock|customMock)" /tmp/psysh_mock_2.out; then
    echo "✅ Mock with custom variable name works"
else
    echo "❌ Mock with custom variable name failed"
    cat /tmp/psysh_mock_2.out
fi

# Test 3: Mock with specific methods
echo "📝 Test 3: Mock with specific methods"
{
    echo 'phpunit:create EmailService'
    echo 'phpunit:mock stdClass emailMock --methods=send,validate'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_mock_3.out 2>&1 || true
if grep -q -E "(Mock créé|methods|méthodes)" /tmp/psysh_mock_3.out; then
    echo "✅ Mock with specific methods works"
else
    echo "❌ Mock with specific methods failed"
    cat /tmp/psysh_mock_3.out
fi

# Test 4: Partial mock creation
echo "📝 Test 4: Partial mock creation"
{
    echo 'phpunit:create ServiceTest'
    echo 'phpunit:mock stdClass partialMock --partial'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_mock_4.out 2>&1 || true
if grep -q -E "(Mock.*créé|partial|partiel)" /tmp/psysh_mock_4.out; then
    echo "✅ Partial mock creation works"
else
    echo "❌ Partial mock creation failed"
    cat /tmp/psysh_mock_4.out
fi

# Test 5: Mock with namespace class
echo "📝 Test 5: Mock with namespace class"
{
    echo 'phpunit:create NamespaceTest'
    echo 'class App\Service\EmailService { public function send() {} }'
    echo 'phpunit:mock App\Service\EmailService'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_mock_5.out 2>&1 || true
if grep -q -E "(Mock créé|EmailService)" /tmp/psysh_mock_5.out; then
    echo "✅ Mock with namespace class works"
else
    echo "❌ Mock with namespace class failed"
    cat /tmp/psysh_mock_5.out
fi

# Test 6: Error handling - no test created first
echo "📝 Test 6: Error handling - no test created first"
echo 'phpunit:mock stdClass' | $PSYSH_CMD --no-interactive > /tmp/psysh_mock_6.out 2>&1 || true
if grep -q -E "(Aucun test|test actuel|error)" /tmp/psysh_mock_6.out; then
    echo "✅ Error handling works"
else
    echo "❌ Error handling failed"
    cat /tmp/psysh_mock_6.out
fi

# Test 7: Error handling - no class name
echo "📝 Test 7: Error handling - no class name"
{
    echo 'phpunit:create TestService'
    echo 'phpunit:mock'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_mock_7.out 2>&1 || true
if grep -q -E "(required|error|Nom.*classe)" /tmp/psysh_mock_7.out; then
    echo "✅ Missing class name handling works"
else
    echo "❌ Missing class name handling failed"
    cat /tmp/psysh_mock_7.out
fi

# Test 8: Mock interface
echo "📝 Test 8: Mock interface"
{
    echo 'phpunit:create InterfaceTest'
    echo 'interface TestInterface { public function test(); }'
    echo 'phpunit:mock TestInterface'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_mock_8.out 2>&1 || true
if grep -q -E "(Mock créé|TestInterface)" /tmp/psysh_mock_8.out; then
    echo "✅ Mock interface works"
else
    echo "❌ Mock interface failed"
    cat /tmp/psysh_mock_8.out
fi

# Test 9: Multiple mocks in same test
echo "📝 Test 9: Multiple mocks in same test"
{
    echo 'phpunit:create MultiMockTest'
    echo 'phpunit:mock stdClass firstMock'
    echo 'phpunit:mock stdClass secondMock'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_mock_9.out 2>&1 || true
if grep -q -E "(firstMock.*secondMock|Mock créé)" /tmp/psysh_mock_9.out; then
    echo "✅ Multiple mocks works"
else
    echo "❌ Multiple mocks failed"
    cat /tmp/psysh_mock_9.out
fi

# Test 10: Mock with method list
echo "📝 Test 10: Mock with method list"
{
    echo 'phpunit:create MethodListTest'
    echo 'phpunit:mock stdClass methodMock --methods=create,update,delete'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_mock_10.out 2>&1 || true
if grep -q -E "(Mock créé|create.*update.*delete|méthodes)" /tmp/psysh_mock_10.out; then
    echo "✅ Mock with method list works"
else
    echo "❌ Mock with method list failed"
    cat /tmp/psysh_mock_10.out
fi

# Clean up
rm -f /tmp/psysh_mock_*.out

echo "✨ phpunit:mock tests completed"
