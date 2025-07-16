#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 13: Closures et callbacks"

# Étape 1: Closure basique avec capture
test_session_sync "Closure multiplier" \
'$multiplier = function($factor) {
    return function($x) use ($factor) {
        return $x * $factor;
    };
};
$double = $multiplier(2);
echo $double(5);' \
'10'

# Étape 2: Array_map avec closure
test_session_sync "Array_map avec closure" \
'$multiplier = function($factor) {
    return function($x) use ($factor) {
        return $x * $factor;
    };
};
$triple = $multiplier(3);
$result = array_map($triple, [1, 2, 3]);
echo implode(", ", $result);' \
'3, 6, 9'

# Étape 3: Callback avec array_filter
test_session_sync "Filter avec callback" \
'$numbers = [1, 2, 3, 4, 5, 6]; $evens = array_filter($numbers, function($x) { return $x % 2 == 0; }); echo implode(", ", $evens)' \
'2, 4, 6'

# Étape 4: Closure avec multiple captures
test_session_sync "Closure multiple captures" \
'$base = 10;
$offset = 5;
$calculator = function($x) use ($base, $offset) {
    return ($x + $offset) * $base;
};
echo $calculator(3);' \
'80'
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
