#!/bin/bash

# Test phpunit:eval command
# Tests all options and scenarios for evaluating expressions with detailed analysis

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"


echo "🧪 Testing phpunit:eval command..."

# Test 1: Basic expression evaluation
echo "📝 Test 1: Basic expression evaluation"

    --step "phpunit:create TestService; $result = 42; phpunit:eval '\$result === 42'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Basic expression evaluation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 2: String comparison evaluation
echo "📝 Test 2: String comparison evaluation"

    --step "phpunit:create UserService; $user = new stdClass(); $user->name = "John"; phpunit:eval '\$user->name == \"John\"'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "String comparison evaluation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 3: Array count evaluation
echo "📝 Test 3: Array count evaluation"

    --step "phpunit:create DataService; $items = [1, 2, 3]; phpunit:eval 'count(\$items) > 0'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Array count evaluation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 4: instanceof evaluation
echo "📝 Test 4: instanceof evaluation"

    --step "phpunit:create ObjectService; $obj = new stdClass(); phpunit:eval '\$obj instanceof stdClass'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "instanceof evaluation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 5: Boolean evaluation
echo "📝 Test 5: Boolean evaluation"

    --step "phpunit:create BooleanService; $active = true; phpunit:eval '\$active === true'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Boolean evaluation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 6: Failed expression evaluation
echo "📝 Test 6: Failed expression evaluation"

    --step "phpunit:create FailService; $value = 10; phpunit:eval '\$value > 20'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Failed expression evaluation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 7: Complex expression evaluation
echo "📝 Test 7: Complex expression evaluation"

    --step "phpunit:create ComplexService; $config = ["debug" => true, "env" => "test"]; phpunit:eval 'isset(\$config[\"debug\"]) && \$config[\"debug\"] === true'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Complex expression evaluation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 8: Error handling - invalid expression
echo "📝 Test 8: Error handling - invalid expression"

    --step "phpunit:create ErrorService; phpunit:eval '\$undefinedVar->method()'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Error handling - invalid expression" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 9: Error handling - no expression provided
echo "📝 Test 9: Error handling - no expression provided"

    --step "phpunit:create TestService; phpunit:eval" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Error handling - no expression provided" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 10: Numeric comparison with details
echo "📝 Test 10: Numeric comparison with details"

    --step "phpunit:create NumericService; $price = 15.50; phpunit:eval '\$price >= 10.0'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Numeric comparison with details" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 11: Expression with method call
echo "📝 Test 11: Expression with method call"

    --step "phpunit:create MethodService; $arr = [1, 2, 3, 4, 5]; phpunit:eval 'array_sum(\$arr) === 15'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Expression with method call" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Test 12: Empty check evaluation
echo "📝 Test 12: Empty check evaluation"

    --step "phpunit:create EmptyService; $errors = []; phpunit:eval 'empty(\$errors)'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Empty check evaluation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "✅" \
    --context phpunit


# Clean up
rm -f /tmp/psysh_eval_*.out

echo "✨ phpunit:eval tests completed"
