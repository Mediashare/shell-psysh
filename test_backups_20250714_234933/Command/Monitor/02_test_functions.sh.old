#!/bin/bash

# Test 02: Définition et utilisation de fonctions
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/psysh_utils.sh"

# Initialiser le test
init_test "TEST 02: Fonctions définies dans le shell"

# Étape 1: Test d'une fonction factorielle simple
test_monitor_multiline "Fonction factorielle" \
'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); }
echo factorial(5);' \
'120'

# Étape 2: Test factorielle avec différentes valeurs
test_monitor_multiline "Factorielle 4!" \
'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); }
echo factorial(4);' \
'24'

# Étape 3: Test fonction Fibonacci
test_monitor_multiline "Fonction Fibonacci" \
'function fibonacci($n) { if ($n <= 1) return $n; return fibonacci($n - 1) + fibonacci($n - 2); }
echo fibonacci(7);' \
'13'

# Étape 4: Fibonacci itérative (plus efficace)
test_monitor_multiline "Fibonacci itérative" \
'function fibonacciIter($n) { $a = 0; $b = 1; for ($i = 0; $i < $n; $i++) { $temp = $a; $a = $b; $b = $temp + $b; } return $a; }
echo fibonacciIter(10);' \
'55'

# Étape 5: Fonction avec array_map pour calculer les carrés
test_monitor_multiline "Array map carrés" \
'function squares($arr) { return array_map(function($x) { return $x * $x; }, $arr); }
echo implode(", ", squares([1, 2, 3, 4]));' \
'1, 4, 9, 16'

# Étape 6: Fonction de somme avec array_reduce
test_monitor_multiline "Array reduce somme" \
'function sum($arr) { return array_reduce($arr, function($carry, $item) { return $carry + $item; }, 0); }
echo sum([10, 20, 30, 40]);' \
'100'

# Étape 7: Test fonction avec closure
test_monitor_expression "Fonction avec closure" \
'echo (function() { $multiplier = 3; $multiplyBy = function($x) use ($multiplier) { return $x * $multiplier; }; return $multiplyBy(7); })()' \
'21'

# Étape 8: Fonction récursive pour somme
test_monitor_multiline "Somme récursive" \
'function sumRecursive($arr) { if (empty($arr)) return 0; return array_shift($arr) + sumRecursive($arr); }
echo sumRecursive([1, 2, 3, 4, 5]);' \
'15'

# Étape 9: Test d'erreur - fonction inexistante
test_monitor_error "Fonction inexistante" \
'nonExistentFunction()' \
'Call to undefined function'

# Étape 10: Test d'erreur - mauvais nombre d'arguments
test_monitor_error "Mauvais nombre d'arguments" \
'function needsTwo($a, $b) { return $a + $b; } needsTwo(1)' \
'Too few arguments|Missing argument'

# Étape 11: Test sync - fonctions persistantes
test_shell_responsiveness "Fonctions persistantes" \
'function globalFunc() { return 42; }' \
'echo globalFunc();' \
'42'

# Étape 12: Test edge case - récursion profonde
test_monitor_error "Récursion trop profonde" \
'function deep($n) { return $n > 1000 ? $n : deep($n + 1); } deep(1)' \
'infinite loop|stack depth|Maximum function nesting level'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
