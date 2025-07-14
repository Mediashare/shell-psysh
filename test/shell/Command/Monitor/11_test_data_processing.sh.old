#!/bin/bash

# Test 11: Traitement de données
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/psysh_utils.sh"

# Initialiser le test
init_test "TEST 11: Traitement de données"

# Étape 1: Filtrage de nombres pairs
test_monitor_expression "Filtrage nombres pairs 1-100" \
'$data = range(1, 100); $filtered = array_filter($data, function($x) { return $x % 2 == 0; }); echo count($filtered)' \
'50'

# Étape 2: Calcul de somme avec array_reduce
test_monitor_expression "Somme avec array_reduce" \
'$numbers = range(1, 10); echo array_reduce($numbers, function($carry, $item) { return $carry + $item; }, 0)' \
'55'

# Étape 3: Transformation avec array_map
test_monitor_expression "Transformation carrés" \
'$base = [1, 2, 3, 4]; $squares = array_map(function($x) { return $x * $x; }, $base); echo implode(", ", $squares)' \
'1, 4, 9, 16'

# Étape 4: Traitement complexe avec chaînage
test_monitor_multiline "Chaînage de traitements" \
'$data = range(1, 20);
$result = array_map(function($x) { return $x * 2; },
    array_filter($data, function($x) { return $x % 3 == 0; })
);
echo "Multiples de 3 doublés: " . implode(", ", $result);' \
'Multiples de 3 doublés: 6, 12, 18, 24, 30, 36'

# Étape 5: Test de performance avec gros dataset
test_monitor_performance "Performance gros dataset" \
'$big_data = range(1, 10000); echo count(array_filter($big_data, function($x) { return $x % 7 == 0; }))' \
'3'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
