#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "Fonctions définies dans le shell"

# Test des fonctions mathématiques basiques
test_session_sync "Fonctions mathématiques" \
    --step 'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); } echo factorial(5);' \
    --context psysh \
    --psysh \
    --tag "default_session" \
    --expect '120' \
    --output-check exact \
    --step 'echo factorial(4);' \
    --expect '24'

# Test des fonctions Fibonacci
test_session_sync "Fonctions Fibonacci" \
    --step 'function fibonacci($n) { if ($n <= 1) return $n; return fibonacci($n - 1) + fibonacci($n - 2); } echo fibonacci(7);' \
    --context psysh \
    --psysh \
    --tag "default_session" \
    --expect '13' \
    --output-check exact \
    --step 'function fibonacciIter($n) { $a = 0; $b = 1; for ($i = 0; $i < $n; $i++) { $temp = $a; $a = $b; $b = $temp + $b; } return $a; } echo fibonacciIter(10);' \
    --expect '55'

# Test des fonctions avec arrays
test_session_sync "Fonctions avec arrays" \
    --step 'function squares($arr) { return array_map(function($x) { return $x * $x; }, $arr); } echo implode(", ", squares([1, 2, 3, 4]));' \
    --context psysh \
    --psysh \
    --tag "default_session" \
    --expect '1, 4, 9, 16' \
    --output-check exact \
    --step 'function sum($arr) { return array_reduce($arr, function($carry, $item) { return $carry + $item; }, 0); } echo sum([10, 20, 30, 40]);' \
    --expect '100'

# Test des fonctions avec closures
test_session_sync "Fonctions avec closures" \
    --step 'echo (function() { $multiplier = 3; $multiplyBy = function($x) use ($multiplier) { return $x * $multiplier; }; return $multiplyBy(7); })()' \
    --context psysh \
    --psysh \
    --tag "default_session" \
    --expect '21' \
    --output-check exact \
    --step 'function sumRecursive($arr) { if (empty($arr)) return 0; return array_shift($arr) + sumRecursive($arr); } echo sumRecursive([1, 2, 3, 4, 5]);' \
    --expect '15'

# Test de synchronisation - fonctions persistantes
test_session_sync "Synchronisation des fonctions" \
    --step 'function globalFunc() { return 42; }' \
    --context psysh \
    --psysh \
    --tag "sync_session" \
    --step 'echo globalFunc();' \
    --expect '42' \
    --output-check exact

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
