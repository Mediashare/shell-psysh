#!/bin/bash

# Test 07: Mode debug
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 07: Mode debug"

# Étape 1: Test de variables en mode debug
'$x = 10; $y = 20; $z = $x + $y; echo $z' \
test_session_sync "Calcul avec variables" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'30'

# Étape 2: Test d'affichage de variables
'$a = "Hello"; $b = "World"; echo $a . " " . $b' \
test_session_sync "Vérification des variables" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'Hello World'

# Étape 3: Test de débogage avec array
'$arr = [1, 2, 3]; echo count($arr)' \
test_session_sync "Array et debug" \
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
