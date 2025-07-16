#!/bin/bash

# Test script for Mock commands
# Tests PHPUnitMockCommand, PHPUnitPartialMockCommand, PHPUnitSpyCommand

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/test_utils.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Mock Commands"
echo ""

# Test PHPUnitMockCommand (phpunit:mock)
echo "🔍 Testing phpunit:mock command..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:mock 'MyClass' --methods='method1,method2' --returns='value1,value2'\""
$PROJECT_ROOT/bin/psysh -c "phpunit:mock 'MyClass' --methods='method1,method2' --returns='value1,value2'"
echo ""

# Test PHPUnitMockCommand with constructor arguments
echo "🔍 Testing phpunit:mock with constructor arguments..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:mock 'DateTime' --constructor-args='2024-01-01'\""
$PROJECT_ROOT/bin/psysh -c "phpunit:mock 'DateTime' --constructor-args='2024-01-01'"
echo ""

# Test PHPUnitPartialMockCommand (phpunit:partial-mock)
echo "🔍 Testing phpunit:partial-mock command..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:partial-mock 'MyClass' --methods='method1' --keep-original='method2,method3'\""
$PROJECT_ROOT/bin/psysh -c "phpunit:partial-mock 'MyClass' --methods='method1' --keep-original='method2,method3'"
echo ""

# Test PHPUnitSpyCommand (phpunit:spy)
echo "🔍 Testing phpunit:spy command..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:spy 'MyClass' --track-calls\""
$PROJECT_ROOT/bin/psysh -c "phpunit:spy 'MyClass' --track-calls"
echo ""

# Test mock with expectations
echo "🔍 Testing mock with expectations..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:mock 'MyInterface' --expects='once' --method='getValue' --will-return='mocked_value'\""
$PROJECT_ROOT/bin/psysh -c "phpunit:mock 'MyInterface' --expects='once' --method='getValue' --will-return='mocked_value'"
echo ""

# Test spy with method verification
echo "🔍 Testing spy with method verification..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:spy 'Logger' --verify-calls --method='log' --times=2\""
$PROJECT_ROOT/bin/psysh -c "phpunit:spy 'Logger' --verify-calls --method='log' --times=2"
echo ""

# Test partial mock with original behavior
echo "🔍 Testing partial mock with original behavior..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:partial-mock 'Calculator' --mock-methods='add' --original-methods='subtract,multiply'\""
$PROJECT_ROOT/bin/psysh -c "phpunit:partial-mock 'Calculator' --mock-methods='add' --original-methods='subtract,multiply'"
echo ""

# Test combined mock operations
echo "🔍 Testing combined mock operations..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:mock 'Service'; phpunit:spy 'Logger'; phpunit:partial-mock 'Helper'\""
$PROJECT_ROOT/bin/psysh -c "phpunit:mock 'Service'; phpunit:spy 'Logger'; phpunit:partial-mock 'Helper'"
echo ""

# Test mock with complex configuration
echo "🔍 Testing mock with complex configuration..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:mock 'HttpClient' --methods='get,post' --returns='response1,response2' --expects='exactly,2'\""
$PROJECT_ROOT/bin/psysh -c "phpunit:mock 'HttpClient' --methods='get,post' --returns='response1,response2' --expects='exactly,2'"
echo ""

test_summary
