#!/bin/bash

# Test phpunit:eval command
# Tests all options and scenarios for evaluating expressions with detailed analysis

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
PSYSH_CMD="$PROJECT_ROOT/vendor/bin/psysh --config $PROJECT_ROOT/config/config.php"

echo "🧪 Testing phpunit:eval command..."

# Test 1: Basic expression evaluation
echo "📝 Test 1: Basic expression evaluation"
{
    echo 'phpunit:create TestService'
    echo '$result = 42'
    echo "phpunit:eval '\$result === 42'"
} | $PSYSH_CMD --no-interactive > /tmp/psysh_eval_1.out 2>&1 || true
if grep -q "Expression évaluée avec succès" /tmp/psysh_eval_1.out; then
    echo "✅ Basic expression evaluation works"
else
    echo "❌ Basic expression evaluation failed"
    cat /tmp/psysh_eval_1.out
fi

# Test 2: String comparison evaluation
echo "📝 Test 2: String comparison evaluation"
{
    echo 'phpunit:create UserService'
    echo '$user = new stdClass(); $user->name = "John"'
    echo "phpunit:eval '\$user->name == \"John\"'"
} | $PSYSH_CMD --no-interactive > /tmp/psysh_eval_2.out 2>&1 || true
if grep -q "Expression évaluée avec succès" /tmp/psysh_eval_2.out; then
    echo "✅ String comparison evaluation works"
else
    echo "❌ String comparison evaluation failed"
    cat /tmp/psysh_eval_2.out
fi

# Test 3: Array count evaluation
echo "📝 Test 3: Array count evaluation"
{
    echo 'phpunit:create DataService'
    echo '$items = [1, 2, 3]'
    echo "phpunit:eval 'count(\$items) > 0'"
} | $PSYSH_CMD --no-interactive > /tmp/psysh_eval_3.out 2>&1 || true
if grep -q "Expression évaluée avec succès" /tmp/psysh_eval_3.out; then
    echo "✅ Array count evaluation works"
else
    echo "❌ Array count evaluation failed"
    cat /tmp/psysh_eval_3.out
fi

# Test 4: instanceof evaluation
echo "📝 Test 4: instanceof evaluation"
{
    echo 'phpunit:create ObjectService'
    echo '$obj = new stdClass()'
    echo "phpunit:eval '\$obj instanceof stdClass'"
} | $PSYSH_CMD --no-interactive > /tmp/psysh_eval_4.out 2>&1 || true
if grep -q "Expression évaluée avec succès" /tmp/psysh_eval_4.out; then
    echo "✅ instanceof evaluation works"
else
    echo "❌ instanceof evaluation failed"
    cat /tmp/psysh_eval_4.out
fi

# Test 5: Boolean evaluation
echo "📝 Test 5: Boolean evaluation"
{
    echo 'phpunit:create BooleanService'
    echo '$active = true'
    echo "phpunit:eval '\$active === true'"
} | $PSYSH_CMD --no-interactive > /tmp/psysh_eval_5.out 2>&1 || true
if grep -q "Expression évaluée avec succès" /tmp/psysh_eval_5.out; then
    echo "✅ Boolean evaluation works"
else
    echo "❌ Boolean evaluation failed"
    cat /tmp/psysh_eval_5.out
fi

# Test 6: Failed expression evaluation
echo "📝 Test 6: Failed expression evaluation"
{
    echo 'phpunit:create FailService'
    echo '$value = 10'
    echo "phpunit:eval '\$value > 20'"
} | $PSYSH_CMD --no-interactive > /tmp/psysh_eval_6.out 2>&1 || true
if grep -q "Expression évaluée à false" /tmp/psysh_eval_6.out; then
    echo "✅ Failed expression evaluation works"
else
    echo "❌ Failed expression evaluation failed"
    cat /tmp/psysh_eval_6.out
fi

# Test 7: Complex expression evaluation
echo "📝 Test 7: Complex expression evaluation"
{
    echo 'phpunit:create ComplexService'
    echo '$config = ["debug" => true, "env" => "test"]'
    echo "phpunit:eval 'isset(\$config[\"debug\"]) && \$config[\"debug\"] === true'"
} | $PSYSH_CMD --no-interactive > /tmp/psysh_eval_7.out 2>&1 || true
if grep -q "Expression évaluée avec succès" /tmp/psysh_eval_7.out; then
    echo "✅ Complex expression evaluation works"
else
    echo "❌ Complex expression evaluation failed"
    cat /tmp/psysh_eval_7.out
fi

# Test 8: Error handling - invalid expression
echo "📝 Test 8: Error handling - invalid expression"
{
    echo 'phpunit:create ErrorService'
    echo "phpunit:eval '\$undefinedVar->method()'"
} | $PSYSH_CMD --no-interactive > /tmp/psysh_eval_8.out 2>&1 || true
if grep -q -E "(Erreur|error)" /tmp/psysh_eval_8.out; then
    echo "✅ Error handling for invalid expression works"
else
    echo "❌ Error handling for invalid expression failed"
    cat /tmp/psysh_eval_8.out
fi

# Test 9: Error handling - no expression provided
echo "📝 Test 9: Error handling - no expression provided"
{
    echo 'phpunit:create TestService'
    echo 'phpunit:eval'
} | $PSYSH_CMD --no-interactive > /tmp/psysh_eval_9.out 2>&1 || true
if grep -q -E "(Aucune expression|required|error)" /tmp/psysh_eval_9.out; then
    echo "✅ Missing expression handling works"
else
    echo "❌ Missing expression handling failed"
    cat /tmp/psysh_eval_9.out
fi

# Test 10: Numeric comparison with details
echo "📝 Test 10: Numeric comparison with details"
{
    echo 'phpunit:create NumericService'
    echo '$price = 15.50'
    echo "phpunit:eval '\$price >= 10.0'"
} | $PSYSH_CMD --no-interactive > /tmp/psysh_eval_10.out 2>&1 || true
if grep -q "Expression évaluée avec succès" /tmp/psysh_eval_10.out; then
    echo "✅ Numeric comparison with details works"
else
    echo "❌ Numeric comparison with details failed"
    cat /tmp/psysh_eval_10.out
fi

# Test 11: Expression with method call
echo "📝 Test 11: Expression with method call"
{
    echo 'phpunit:create MethodService'
    echo '$arr = [1, 2, 3, 4, 5]'
    echo "phpunit:eval 'array_sum(\$arr) === 15'"
} | $PSYSH_CMD --no-interactive > /tmp/psysh_eval_11.out 2>&1 || true
if grep -q "Expression évaluée avec succès" /tmp/psysh_eval_11.out; then
    echo "✅ Expression with method call works"
else
    echo "❌ Expression with method call failed"
    cat /tmp/psysh_eval_11.out
fi

# Test 12: Empty check evaluation
echo "📝 Test 12: Empty check evaluation"
{
    echo 'phpunit:create EmptyService'
    echo '$errors = []'
    echo "phpunit:eval 'empty(\$errors)'"
} | $PSYSH_CMD --no-interactive > /tmp/psysh_eval_12.out 2>&1 || true
if grep -q "Expression évaluée avec succès" /tmp/psysh_eval_12.out; then
    echo "✅ Empty check evaluation works"
else
    echo "❌ Empty check evaluation failed"
    cat /tmp/psysh_eval_12.out
fi

# Clean up
rm -f /tmp/psysh_eval_*.out

echo "✨ phpunit:eval tests completed"
