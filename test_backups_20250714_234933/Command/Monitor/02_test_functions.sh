#!/bin/bash

# Test refactorisé avec test_session_sync_enhanced
# Définition et utilisation de fonctions

# Obtenir le répertoire du script et charger les fonctions
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "Fonctions définies dans le shell"

# Test des fonctions mathématiques basiques
test_session_sync "Fonctions mathématiques" \
    --context monitor \
    --input-type multiline \
    --output-check contains \
    --timeout 30 \
    --step 'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); } echo factorial(5);' \
    --expect '120' \
    --step 'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); } echo factorial(4);' \
    --expect '24'

# Test des fonctions Fibonacci
test_session_sync "Fonctions Fibonacci" \
    --context monitor \
    --input-type multiline \
    --output-check contains \
    --timeout 30 \
    --step 'function fibonacci($n) { if ($n <= 1) return $n; return fibonacci($n - 1) + fibonacci($n - 2); } echo fibonacci(7);' \
    --expect '13' \
    --step 'function fibonacciIter($n) { $a = 0; $b = 1; for ($i = 0; $i < $n; $i++) { $temp = $a; $a = $b; $b = $temp + $b; } return $a; } echo fibonacciIter(10);' \
    --expect '55'

# Test des fonctions avec arrays
test_session_sync "Fonctions avec arrays" \
    --context monitor \
    --input-type multiline \
    --output-check contains \
    --timeout 30 \
    --step 'function squares($arr) { return array_map(function($x) { return $x * $x; }, $arr); } echo implode(", ", squares([1, 2, 3, 4]));' \
    --expect '1, 4, 9, 16' \
    --step 'function sum($arr) { return array_reduce($arr, function($carry, $item) { return $carry + $item; }, 0); } echo sum([10, 20, 30, 40]);' \
    --expect '100'

# Test des fonctions avec closures
test_session_sync "Fonctions avec closures" \
    --context monitor \
    --input-type multiline \
    --output-check contains \
    --timeout 30 \
    --step 'echo (function() { $multiplier = 3; $multiplyBy = function($x) use ($multiplier) { return $x * $multiplier; }; return $multiplyBy(7); })()' \
    --expect '21' \
    --step 'function sumRecursive($arr) { if (empty($arr)) return 0; return array_shift($arr) + sumRecursive($arr); } echo sumRecursive([1, 2, 3, 4, 5]);' \
    --expect '15'

# Test des erreurs de fonctions
test_session_sync "Erreurs de fonctions" \
    --context monitor \
    --input-type multiline \
    --output-check error \
    --timeout 30 \
    --retry 2 \
    --step 'nonExistentFunction()' \
    --expect 'Call to undefined function' \
    --step 'function needsTwo($a, $b) { return $a + $b; } needsTwo(1)' \
    --expect 'Too few arguments|Missing argument' \
    --step 'function deep($n) { return $n > 1000 ? $n : deep($n + 1); } deep(1)' \
    --expect 'infinite loop|stack depth|Maximum function nesting level'

# Test de synchronisation - fonctions persistantes
test_session_sync "Synchronisation des fonctions" \
    --context monitor \
    --input-type multiline \
    --output-check contains \
    --timeout 60 \
    --sync-test \
    --step 'function globalFunc() { return 42; }' \
    --step 'echo globalFunc();' \
    --expect '42'

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
