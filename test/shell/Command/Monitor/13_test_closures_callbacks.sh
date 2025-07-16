#!/bin/bash

# Test 13: Closures et callbacks
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 13: Closures et callbacks"

# Étape 1: Closure basique avec capture
'$multiplier = function($factor) {
test_session_sync "Closure multiplier" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    return function($x) use ($factor) {
        return $x * $factor;
    };
};
$double = $multiplier(2);
echo $double(5);' \
'10'

# Étape 2: Array_map avec closure
'$multiplier = function($factor) {
test_session_sync "Array_map avec closure" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    return function($x) use ($factor) {
        return $x * $factor;
    };
};
$triple = $multiplier(3);
$result = array_map($triple, [1, 2, 3]);
echo implode(", ", $result);' \
'3, 6, 9'

# Étape 3: Callback avec array_filter
'$numbers = [1, 2, 3, 4, 5, 6]; $evens = array_filter($numbers, function($x) { return $x % 2 == 0; }); echo implode(", ", $evens)' \
test_session_sync "Filter avec callback" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'2, 4, 6'

# Étape 4: Closure avec multiple captures
'$base = 10;
test_session_sync "Closure multiple captures" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
$offset = 5;
$calculator = function($x) use ($base, $offset) {
    return ($x + $offset) * $base;
};
echo $calculator(3);' \
'80'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
