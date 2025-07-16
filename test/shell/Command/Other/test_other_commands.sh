#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "Other Commands"
echo ""

# Test PHPUnitAddCommand (phpunit:add)
test_session_sync "phpunit:add help" \
    "test_session_sync "Test command" --step \"phpunit:add --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitCallOriginalCommand (phpunit:call-original)
test_session_sync "phpunit:call-original help" \
    "test_session_sync "Test command" --step \"phpunit:call-original --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitEvalCommand (phpunit:eval)
test_session_sync "phpunit:eval help" \
    "test_session_sync "Test command" --step \"phpunit:eval --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitExpectCommand (phpunit:expect)
test_session_sync "phpunit:expect help" \
    "test_session_sync "Test command" --step \"phpunit:expect --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitVerifyCommand (phpunit:verify)
test_session_sync "phpunit:verify help" \
    "test_session_sync "Test command" --step \"phpunit:verify --help\"" \
    "Usage:" \
    "check_contains"

# Test phpunit:add with simple value
test_session_sync "Add simple value" \
    "test_session_sync "Test command" --step \"phpunit:add --value='Hello World' --key='test_key'\"" \
    "added" \
    "check_contains"

# Test phpunit:eval with simple expression
test_session_sync "Eval simple expression" \
    "test_session_sync "Test command" --step \"phpunit:eval --code='2 + 2'\"" \
    "4" \
    "check_contains"

# Test phpunit:eval with variable assignment
test_session_sync "Eval variable assignment" \
    "test_session_sync "Test command" --step \"phpunit:eval --code='\$result = 5 * 10; return \$result;'\"" \
    "50" \
    "check_contains"

# Test phpunit:expect with simple expectation
test_session_sync "Expect simple value" \
    "test_session_sync "Test command" --step \"phpunit:expect --value='test' --equals='test'\"" \
    "✅" \
    "check_contains"

# Test phpunit:expect with array expectation
test_session_sync "Expect array value" \
    "test_session_sync "Test command" --step \"phpunit:expect --value='[1,2,3]' --contains='2'\"" \
    "✅" \
    "check_contains"

# Test phpunit:verify with condition
test_session_sync "Verify condition" \
    "test_session_sync "Test command" --step \"phpunit:verify --condition='true' --message='This should pass'\"" \
    "✅" \
    "check_contains"

# Test phpunit:call-original with method
test_session_sync "Call original method" \
    "test_session_sync "Test command" --step \"phpunit:call-original --class='DateTime' --method='format' --args='Y-m-d'\"" \
    "original" \
    "check_contains"

# Test combined other operations
test_session_sync "Combined other operations" \
    "test_session_sync "Test command" --step \"phpunit:add --value='test'; phpunit:eval --code='2+2'; phpunit:expect --value='4' --equals='4'\"" \
    "✅" \
    "check_contains"

# Test complex eval with function definition
test_session_sync "Eval function definition" \
    "test_session_sync "Test command" --step \"phpunit:eval --code='function test() { return "Hello"; } return test();'\"" \
    "Hello" \
    "check_contains"

# Test verify with false condition
test_session_sync "Verify false condition (should fail)" \
    "test_session_sync "Test command" --step \"phpunit:verify --condition='false' --message='This should fail'\"" \
    "❌" \
    "check_contains"

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
