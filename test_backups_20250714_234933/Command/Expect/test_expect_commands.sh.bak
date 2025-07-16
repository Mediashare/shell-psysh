#!/bin/bash

# Test script for Expect commands
# Tests PHPUnitExceptionAssertCommand with aliases

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/test_utils.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Expect Commands"
echo ""

# Test original phpunit:expect-exception command
echo "🔍 Testing original phpunit:expect-exception command..."
echo "../bin/psysh -c \"phpunit:expect-exception 'InvalidArgumentException' 'throw new InvalidArgumentException();'\""
../bin/psysh -c "phpunit:expect-exception 'InvalidArgumentException' 'throw new InvalidArgumentException();'"
echo ""

# Test original phpunit:expect-no-exception command
echo "🔍 Testing original phpunit:expect-no-exception command..."
echo "../bin/psysh -c \"phpunit:expect-no-exception 'echo \\\"No exception here\\\";'\""
../bin/psysh -c "phpunit:expect-no-exception 'echo \"No exception here\";'"
echo ""

# Test new phpunit:assert-exception alias
echo "🔍 Testing new phpunit:assert-exception alias..."
echo "../bin/psysh -c \"phpunit:assert-exception 'RuntimeException' 'throw new RuntimeException(\\\"Test error\\\");'\""
../bin/psysh -c "phpunit:assert-exception 'RuntimeException' 'throw new RuntimeException(\"Test error\");'"
echo ""

# Test new phpunit:assert-no-exception alias
echo "🔍 Testing new phpunit:assert-no-exception alias..."
echo "../bin/psysh -c \"phpunit:assert-no-exception 'return 42;'\""
../bin/psysh -c "phpunit:assert-no-exception 'return 42;'"
echo ""

# Test exception with message validation
echo "🔍 Testing exception with message validation..."
echo "../bin/psysh -c \"phpunit:expect-exception 'Exception' 'throw new Exception(\\\"Custom message\\\");' --message='Custom message'\""
../bin/psysh -c "phpunit:expect-exception 'Exception' 'throw new Exception(\"Custom message\");' --message='Custom message'"
echo ""

# Test expected failure - no exception when one is expected
echo "🔍 Testing expected failure - no exception when one is expected..."
echo "../bin/psysh -c \"phpunit:expect-exception 'Exception' 'echo \\\"No exception here\\\";'\""
../bin/psysh -c "phpunit:expect-exception 'Exception' 'echo \"No exception here\";'"
echo ""

# Test expected failure - exception when none is expected
echo "🔍 Testing expected failure - exception when none is expected..."
echo "../bin/psysh -c \"phpunit:expect-no-exception 'throw new Exception(\\\"Unexpected exception\\\");'\""
../bin/psysh -c "phpunit:expect-no-exception 'throw new Exception(\"Unexpected exception\");'"
echo ""

# Test combined scenarios with other commands
echo "🔍 Testing combined scenarios..."
echo "../bin/psysh -c \"phpunit:assert-no-exception 'return 123;'; phpunit:assert-equals 123 123\""
../bin/psysh -c "phpunit:assert-no-exception 'return 123;'; phpunit:assert-equals 123 123"
echo ""

test_summary
