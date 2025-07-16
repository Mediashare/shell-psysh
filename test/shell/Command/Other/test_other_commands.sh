#!/bin/bash

# Test script for Other commands
# Tests PHPUnitAddCommand, PHPUnitCallOriginalCommand, PHPUnitEvalCommand, etc.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Other Commands"
echo ""

# Test PHPUnitAddCommand (phpunit:add)
    --step "phpunit:add --help" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:add help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "Usage:" \
    --output-check contains

# Test PHPUnitCallOriginalCommand (phpunit:call-original)
    --step "phpunit:call-original --help" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:call-original help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "Usage:" \
    --output-check contains

# Test PHPUnitEvalCommand (phpunit:eval)
    --step "phpunit:eval --help" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:eval help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "Usage:" \
    --output-check contains

# Test PHPUnitExpectCommand (phpunit:expect)
    --step "phpunit:expect --help" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:expect help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "Usage:" \
    --output-check contains

# Test PHPUnitVerifyCommand (phpunit:verify)
    --step "phpunit:verify --help" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:verify help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "Usage:" \
    --output-check contains

# Test phpunit:add with simple value
    --step "phpunit:add --value='Hello World' --key='test_key'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Add simple value" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "added" \
    --output-check contains

# Test phpunit:eval with simple expression
    --step "phpunit:eval --code='2 + 2'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Eval simple expression" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "4" \
    --output-check contains

# Test phpunit:eval with variable assignment
    "test_session_sync "Test command" --step \"phpunit:eval --code='\$result = 5 * 10; return \$result;'\"" \
test_session_sync "Eval variable assignment" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "50" \
    --output-check contains

# Test phpunit:expect with simple expectation
    --step "phpunit:expect --value='test' --equals='test'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Expect simple value" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "✅" \
    --output-check contains

# Test phpunit:expect with array expectation
    --step "phpunit:expect --value='[1,2,3]' --contains='2'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Expect array value" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "✅" \
    --output-check contains

# Test phpunit:verify with condition
    --step "phpunit:verify --condition='true' --message='This should pass'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Verify condition" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "✅" \
    --output-check contains

# Test phpunit:call-original with method
    --step "phpunit:call-original --class='DateTime' --method='format' --args='Y-m-d'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Call original method" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "original" \
    --output-check contains

# Test combined other operations
    --step "phpunit:add --value='test'; phpunit:eval --code='2+2'; phpunit:expect --value='4' --equals='4'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Combined other operations" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "✅" \
    --output-check contains

# Test complex eval with function definition
    "test_session_sync "Test command" --step \"phpunit:eval --code='function test() { return "Hello"; } return test();'\"" \
test_session_sync "Eval function definition" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "Hello" \
    --output-check contains

# Test verify with false condition
    --step "phpunit:verify --condition='false' --message='This should fail'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Verify false condition (should fail)" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "❌" \
    --output-check contains

test_summary
