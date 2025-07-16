#!/bin/bash

# Test 11: Traitement de données
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 11: Traitement de données"

# Étape 1: Filtrage de nombres pairs
'$data = range(1, 100); $filtered = array_filter($data, function($x) { return $x % 2 == 0; }); echo count($filtered)' \
test_session_sync "Filtrage nombres pairs 1-100" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'50'

# Étape 2: Calcul de somme avec array_reduce
'$numbers = range(1, 10); echo array_reduce($numbers, function($carry, $item) { return $carry + $item; }, 0)' \
test_session_sync "Somme avec array_reduce" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'55'

# Étape 3: Transformation avec array_map
'$base = [1, 2, 3, 4]; $squares = array_map(function($x) { return $x * $x; }, $base); echo implode(", ", $squares)' \
test_session_sync "Transformation carrés" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'1, 4, 9, 16'

# Étape 4: Traitement complexe avec chaînage
'$data = range(1, 20);
test_session_sync "Chaînage de traitements" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
$result = array_map(function($x) { return $x * 2; },
    array_filter($data, function($x) { return $x % 3 == 0; })
);
echo "Multiples de 3 doublés: " . implode(", ", $result);' \
'Multiples de 3 doublés: 6, 12, 18, 24, 30, 36'

# Étape 5: Test de performance avec gros dataset
'$big_data = range(1, 10000); echo count(array_filter($big_data, function($x) { return $x % 7 == 0; }))' \
test_session_sync "Performance gros dataset" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'3'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
