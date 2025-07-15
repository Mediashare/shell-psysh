#!/bin/bash

# Test script for Expect commands
# Tests PHPUnitExceptionAssertCommand with aliases

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Expect Commands"
echo ""

# Test original phpunit:expect-exception command
echo "🔍 Testing original phpunit:expect-exception command..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:expect-exception 'InvalidArgumentException' 'throw new InvalidArgumentException();'\""
$PROJECT_ROOT/bin/psysh -c "phpunit:expect-exception 'InvalidArgumentException' 'throw new InvalidArgumentException();'"
echo ""

# Test original phpunit:expect-no-exception command
echo "🔍 Testing original phpunit:expect-no-exception command..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:expect-no-exception 'echo \\\"No exception here\\\";'\""
$PROJECT_ROOT/bin/psysh -c "phpunit:expect-no-exception 'echo \"No exception here\";'"
echo ""

# Test new phpunit:assert-exception alias
echo "🔍 Testing new phpunit:assert-exception alias..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:assert-exception 'RuntimeException' 'throw new RuntimeException(\\\"Test error\\\");'\""
$PROJECT_ROOT/bin/psysh -c "phpunit:assert-exception 'RuntimeException' 'throw new RuntimeException(\"Test error\");'"
echo ""

# Test new phpunit:assert-no-exception alias
echo "🔍 Testing new phpunit:assert-no-exception alias..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:assert-no-exception 'return 42;'\""
$PROJECT_ROOT/bin/psysh -c "phpunit:assert-no-exception 'return 42;'"
echo ""

# Test exception with message validation
echo "🔍 Testing exception with message validation..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:expect-exception 'Exception' 'throw new Exception(\\\"Custom message\\\");' --message='Custom message'\""
$PROJECT_ROOT/bin/psysh -c "phpunit:expect-exception 'Exception' 'throw new Exception(\"Custom message\");' --message='Custom message'"
echo ""

# Test expected failure - no exception when one is expected
echo "🔍 Testing expected failure - no exception when one is expected..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:expect-exception 'Exception' 'echo \\\"No exception here\\\";'\""
$PROJECT_ROOT/bin/psysh -c "phpunit:expect-exception 'Exception' 'echo \"No exception here\";'"
echo ""

# Test expected failure - exception when none is expected
echo "🔍 Testing expected failure - exception when none is expected..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:expect-no-exception 'throw new Exception(\\\"Unexpected exception\\\");'\""
$PROJECT_ROOT/bin/psysh -c "phpunit:expect-no-exception 'throw new Exception(\"Unexpected exception\");'"
echo ""

# Test combined scenarios with other commands
echo "🔍 Testing combined scenarios..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:assert-no-exception 'return 123;'; phpunit:assert-equals 123 123\""
$PROJECT_ROOT/bin/psysh -c "phpunit:assert-no-exception 'return 123;'; phpunit:assert-equals 123 123"
echo ""

test_summary
