#!/bin/bash

# Test 05: Performance et boucles
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 05: Performance et boucles"

# Étape 1: Test somme avec boucle for (formule: n*(n+1)/2)
# test_session_sync "Boucle for somme 1-100" \
#     --step '$sum = 0; for ($i = 1; $i <= 100; $i++) { $sum += $i; } echo $sum;' \
#     --context psysh \
#     --psysh \
#     --tag "performance_session" \
#     --expect '5050' \
#     --output-check exact

# Étape 2: Test somme avec boucle for plus grande
test_session_sync "Boucle for somme 1-1000" \
    --step '$sum = 0; for ($i = 1; $i <= 1000; $i++) { $sum += $i; } echo $sum;' \
    --context psysh \
    --psysh \
    --tag "performance_session" \
    --expect '500500' \
    --output-check exact

# Étape 3: Comparaison array_sum vs boucle foreach
test_session_sync "Array sum vs foreach" \
    --step '$array = range(1, 100); $sum1 = array_sum($array); $sum2 = 0; foreach ($array as $num) { $sum2 += $num; } echo ($sum1 === $sum2) ? "identical" : "different";' \
    --context psysh \
    --psysh \
    --tag "performance_session" \
    --expect 'identical' \
    --output-check exact

# Étape 4: Test performance array_sum optimisé
# test_session_sync "Array sum optimisé" \
#     --step 'echo array_sum(range(1, 100));' \
#     --context psysh \
#     --psysh \
#     --tag "performance_session" \
#     --expect '5050' \
#     --output-check exact

# Étape 5: Test génération et comptage de nombres premiers
test_session_sync "Nombres premiers jusqu'à 30" \
    --step 'function isPrime($n) { if ($n <= 1) return false; if ($n <= 3) return true; if ($n % 2 == 0 || $n % 3 == 0) return false; for ($i = 5; $i * $i <= $n; $i += 6) { if ($n % $i == 0 || $n % ($i + 2) == 0) return false; } return true; } $primes = []; for ($i = 2; $i <= 30; $i++) { if (isPrime($i)) $primes[] = $i; } echo count($primes);' \
    --context psysh \
    --psysh \
    --tag "performance_session" \
    --expect '10' \
    --output-check exact

# Étape 6: Test factorielle avec boucle
test_session_sync "Factorielle avec boucle" \
    --step '$result = 1; for ($i = 1; $i <= 6; $i++) { $result *= $i; } echo $result;' \
    --context psysh \
    --psysh \
    --tag "performance_session" \
    --expect '720' \
    --output-check exact

# Étape 7: Test performance sur array_filter
test_session_sync "Array filter nombres pairs" \
    --step '$numbers = range(1, 20); $evens = array_filter($numbers, function($n) { return $n % 2 == 0; }); echo count($evens);' \
    --context psysh \
    --psysh \
    --tag "performance_session" \
    --expect '10' \
    --output-check exact

# Étape 8: Test performance avec mesure de temps (max 5 secondes)
test_session_sync "Performance boucle 1-10000" \
    --step '$sum = 0; for ($i = 1; $i <= 10000; $i++) { $sum += $i; } echo $sum;' \
    --context psysh \
    --psysh \
    --tag "performance_session" \
    --expect '50005000' \
    --output-check exact

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
