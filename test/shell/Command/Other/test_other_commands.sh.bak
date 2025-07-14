#!/bin/bash

# Test script for Other commands
# Tests PHPUnitAddCommand, PHPUnitCallOriginalCommand, PHPUnitEvalCommand, etc.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/test_utils.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Other Commands"
echo ""

# Test PHPUnitAddCommand (phpunit:add)
run_test_step "phpunit:add help" \
    "../bin/psysh -c \"phpunit:add --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitCallOriginalCommand (phpunit:call-original)
run_test_step "phpunit:call-original help" \
    "../bin/psysh -c \"phpunit:call-original --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitEvalCommand (phpunit:eval)
run_test_step "phpunit:eval help" \
    "../bin/psysh -c \"phpunit:eval --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitExpectCommand (phpunit:expect)
run_test_step "phpunit:expect help" \
    "../bin/psysh -c \"phpunit:expect --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitVerifyCommand (phpunit:verify)
run_test_step "phpunit:verify help" \
    "../bin/psysh -c \"phpunit:verify --help\"" \
    "Usage:" \
    "check_contains"

# Test phpunit:add with simple value
run_test_step "Add simple value" \
    "../bin/psysh -c \"phpunit:add --value='Hello World' --key='test_key'\"" \
    "added" \
    "check_contains"

# Test phpunit:eval with simple expression
run_test_step "Eval simple expression" \
    "../bin/psysh -c \"phpunit:eval --code='2 + 2'\"" \
    "4" \
    "check_contains"

# Test phpunit:eval with variable assignment
run_test_step "Eval variable assignment" \
    "../bin/psysh -c \"phpunit:eval --code='\$result = 5 * 10; return \$result;'\"" \
    "50" \
    "check_contains"

# Test phpunit:expect with simple expectation
run_test_step "Expect simple value" \
    "../bin/psysh -c \"phpunit:expect --value='test' --equals='test'\"" \
    "✅" \
    "check_contains"

# Test phpunit:expect with array expectation
run_test_step "Expect array value" \
    "../bin/psysh -c \"phpunit:expect --value='[1,2,3]' --contains='2'\"" \
    "✅" \
    "check_contains"

# Test phpunit:verify with condition
run_test_step "Verify condition" \
    "../bin/psysh -c \"phpunit:verify --condition='true' --message='This should pass'\"" \
    "✅" \
    "check_contains"

# Test phpunit:call-original with method
run_test_step "Call original method" \
    "../bin/psysh -c \"phpunit:call-original --class='DateTime' --method='format' --args='Y-m-d'\"" \
    "original" \
    "check_contains"

# Test combined other operations
run_test_step "Combined other operations" \
    "../bin/psysh -c \"phpunit:add --value='test'; phpunit:eval --code='2+2'; phpunit:expect --value='4' --equals='4'\"" \
    "✅" \
    "check_contains"

# Test complex eval with function definition
run_test_step "Eval function definition" \
    "../bin/psysh -c \"phpunit:eval --code='function test() { return \\\"Hello\\\"; } return test();'\"" \
    "Hello" \
    "check_contains"

# Test verify with false condition
run_test_step "Verify false condition (should fail)" \
    "../bin/psysh -c \"phpunit:verify --condition='false' --message='This should fail'\"" \
    "❌" \
    "check_contains"

test_summary
