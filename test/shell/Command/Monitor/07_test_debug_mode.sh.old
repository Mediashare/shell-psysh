#!/bin/bash

# Test 07: Mode debug
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/psysh_utils.sh"

# Initialiser le test
init_test "TEST 07: Mode debug"

# Étape 1: Test de variables en mode debug
test_monitor_expression "Calcul avec variables" \
'$x = 10; $y = 20; $z = $x + $y; echo $z' \
'30'

# Étape 2: Test d'affichage de variables
test_monitor_expression "Vérification des variables" \
'$a = "Hello"; $b = "World"; echo $a . " " . $b' \
'Hello World'

# Étape 3: Test de débogage avec array
test_monitor_expression "Array et debug" \
'$arr = [1, 2, 3]; echo count($arr)' \
'3'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
