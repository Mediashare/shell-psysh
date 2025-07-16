#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "phpunit eval"

# Test 1: Basic expression evaluation
echo "📝 Test 1: Basic expression evaluation"

test_session_sync "Basic expression evaluation" \
    --step "phpunit:create TestService; $result = 42; phpunit:eval '\$result === 42'" \
    --expect "✅" \
    --context phpunit


# Test 2: String comparison evaluation
echo "📝 Test 2: String comparison evaluation"

test_session_sync "String comparison evaluation" \
    --step "phpunit:create UserService; $user = new stdClass(); $user->name = "John"; phpunit:eval '\$user->name == \"John\"'" \
    --expect "✅" \
    --context phpunit


# Test 3: Array count evaluation
echo "📝 Test 3: Array count evaluation"

test_session_sync "Array count evaluation" \
    --step "phpunit:create DataService; $items = [1, 2, 3]; phpunit:eval 'count(\$items) > 0'" \
    --expect "✅" \
    --context phpunit


# Test 4: instanceof evaluation
echo "📝 Test 4: instanceof evaluation"

test_session_sync "instanceof evaluation" \
    --step "phpunit:create ObjectService; $obj = new stdClass(); phpunit:eval '\$obj instanceof stdClass'" \
    --expect "✅" \
    --context phpunit


# Test 5: Boolean evaluation
echo "📝 Test 5: Boolean evaluation"

test_session_sync "Boolean evaluation" \
    --step "phpunit:create BooleanService; $active = true; phpunit:eval '\$active === true'" \
    --expect "✅" \
    --context phpunit


# Test 6: Failed expression evaluation
echo "📝 Test 6: Failed expression evaluation"

test_session_sync "Failed expression evaluation" \
    --step "phpunit:create FailService; $value = 10; phpunit:eval '\$value > 20'" \
    --expect "✅" \
    --context phpunit


# Test 7: Complex expression evaluation
echo "📝 Test 7: Complex expression evaluation"

test_session_sync "Complex expression evaluation" \
    --step "phpunit:create ComplexService; $config = ["debug" => true, "env" => "test"]; phpunit:eval 'isset(\$config[\"debug\"]) && \$config[\"debug\"] === true'" \
    --expect "✅" \
    --context phpunit


# Test 8: Error handling - invalid expression
echo "📝 Test 8: Error handling - invalid expression"

test_session_sync "Error handling - invalid expression" \
    --step "phpunit:create ErrorService; phpunit:eval '\$undefinedVar->method()'" \
    --expect "✅" \
    --context phpunit


# Test 9: Error handling - no expression provided
echo "📝 Test 9: Error handling - no expression provided"

test_session_sync "Error handling - no expression provided" \
    --step "phpunit:create TestService; phpunit:eval" \
    --expect "✅" \
    --context phpunit


# Test 10: Numeric comparison with details
echo "📝 Test 10: Numeric comparison with details"

test_session_sync "Numeric comparison with details" \
    --step "phpunit:create NumericService; $price = 15.50; phpunit:eval '\$price >= 10.0'" \
    --expect "✅" \
    --context phpunit


# Test 11: Expression with method call
echo "📝 Test 11: Expression with method call"

test_session_sync "Expression with method call" \
    --step "phpunit:create MethodService; $arr = [1, 2, 3, 4, 5]; phpunit:eval 'array_sum(\$arr) === 15'" \
    --expect "✅" \
    --context phpunit


# Test 12: Empty check evaluation
echo "📝 Test 12: Empty check evaluation"

test_session_sync "Empty check evaluation" \
    --step "phpunit:create EmptyService; $errors = []; phpunit:eval 'empty(\$errors)'" \
    --expect "✅" \
    --context phpunit


# Clean up
rm -f /tmp/psysh_eval_*.out
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
