#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 11: Traitement de données"

# Étape 1: Filtrage de nombres pairs
test_session_sync "Filtrage nombres pairs 1-100" \
'$data = range(1, 100); $filtered = array_filter($data, function($x) { return $x % 2 == 0; }); echo count($filtered)' \
'50'

# Étape 2: Calcul de somme avec array_reduce
test_session_sync "Somme avec array_reduce" \
'$numbers = range(1, 10); echo array_reduce($numbers, function($carry, $item) { return $carry + $item; }, 0)' \
'55'

# Étape 3: Transformation avec array_map
test_session_sync "Transformation carrés" \
'$base = [1, 2, 3, 4]; $squares = array_map(function($x) { return $x * $x; }, $base); echo implode(", ", $squares)' \
'1, 4, 9, 16'

# Étape 4: Traitement complexe avec chaînage
test_session_sync "Chaînage de traitements" \
'$data = range(1, 20);
$result = array_map(function($x) { return $x * 2; },
    array_filter($data, function($x) { return $x % 3 == 0; })
);
echo "Multiples de 3 doublés: " . implode(", ", $result);' \
'Multiples de 3 doublés: 6, 12, 18, 24, 30, 36'

# Étape 5: Test de performance avec gros dataset
test_session_sync "Performance gros dataset" \
'$big_data = range(1, 10000); echo count(array_filter($big_data, function($x) { return $x % 7 == 0; }))' \
'1428'

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
