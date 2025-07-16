#!/bin/bash

# Test script for Assert commands
# Tests PHPUnitAssertCommand, PHPUnitAssertEqualsCommand, PHPUnitTypedAssertCommand

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/test_utils.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Assert Commands"
echo ""

# Test PHPUnitAssertCommand (phpunit:assert)
run_test_step "phpunit:assert with valid condition" \
    "$PROJECT_ROOT/bin/psysh -c \"phpunit:assert '1 == 1' --message='This should pass'\"" \
    "✅" \
    "check_contains"

run_test_step "phpunit:assert with false condition (should fail)" \
    "$PROJECT_ROOT/bin/psysh -c \"phpunit:assert '1 == 2' --message='This should fail'\"" \
    "❌" \
    "check_contains"

# Test PHPUnitAssertEqualsCommand (phpunit:assert-equals)
run_test_step "phpunit:assert-equals with equal strings" \
    "$PROJECT_ROOT/bin/psysh -c \"phpunit:assert-equals 'Hello' 'Hello' 'Strings should be equal'\"" \
    "✅" \
    "check_contains"

run_test_step "phpunit:assert-equals with different values (should fail)" \
    "$PROJECT_ROOT/bin/psysh -c \"phpunit:assert-equals 'Hello' 'World' 'Different strings'\"" \
    "❌" \
    "check_contains"

# Test PHPUnitTypedAssertCommand (phpunit:assert-type)
run_test_step "phpunit:assert-type with correct type" \
    "$PROJECT_ROOT/bin/psysh -c \"phpunit:assert-type 'string' '\\\"Hello World\\\"'\"" \
    "✅" \
    "check_contains"

run_test_step "phpunit:assert-type with wrong type (should fail)" \
    "$PROJECT_ROOT/bin/psysh -c \"phpunit:assert-type 'integer' '\\\"Hello World\\\"'\"" \
    "❌" \
    "check_contains"

# Test simple scenario instead of combined
run_test_step "Simple assert numeric" \
    "$PROJECT_ROOT/bin/psysh -c \"phpunit:assert 'is_numeric(5)'\"" \
    "✅" \
    "check_contains"

test_summary
