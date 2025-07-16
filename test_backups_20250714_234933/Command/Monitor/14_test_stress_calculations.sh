#!/bin/bash

# Test 14: Calculs intensifs
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser le test
init_test "TEST 14: Calculs intensifs"

# Étape 1: Calcul intensif plus modéré
test_monitor_performance "Somme des carrés 1-1000" \
'$sum = 0; for($i = 1; $i <= 1000; $i++) { $sum += $i * $i; } echo $sum' \
'5'

# Étape 2: Calcul de primes
test_monitor_performance "Nombres premiers" \
'$count = 0; for($i = 2; $i <= 100; $i++) { $isPrime = true; for($j = 2; $j < $i; $j++) { if($i % $j == 0) { $isPrime = false; break; } } if($isPrime) $count++; } echo $count' \
'3'

# Étape 3: Factorielle
test_monitor_expression "Factorielle 20" \
'function factorial($n) { return $n <= 1 ? 1 : $n * factorial($n - 1); } echo factorial(20)' \
'2432902008176640000'

# Étape 4: Suite de Fibonacci
test_monitor_performance "Fibonacci 30" \
'function fib($n) { return $n <= 1 ? $n : fib($n-1) + fib($n-2); } echo fib(30)' \
'10'

# Étape 5: Calcul matriciel simple
test_monitor_expression "Multiplication matrice" \
'$a = [[1,2],[3,4]]; $b = [[2,0],[1,3]]; $c = [[$a[0][0]*$b[0][0]+$a[0][1]*$b[1][0], $a[0][0]*$b[0][1]+$a[0][1]*$b[1][1]], [$a[1][0]*$b[0][0]+$a[1][1]*$b[1][0], $a[1][0]*$b[0][1]+$a[1][1]*$b[1][1]]]; echo $c[0][0]' \
'4'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
