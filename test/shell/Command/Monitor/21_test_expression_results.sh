#!/bin/bash

# Test 21: Résultats des expressions simples (régression)
# Test automatisé pour vérifier que les expressions simples retournent le bon résultat
# Ce test vérifie la correction du bug où monitor retournait NULL au lieu du résultat

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 21: Résultats des expressions simples"

# Étape 1: Expression simple
'42' \
test_session_sync "Expression simple" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'42'

# Étape 2: Calcul
'5 + 3' \
test_session_sync "Calcul basique" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'8'

# Étape 3: String
'echo "Hello World"' \
test_session_sync "String" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'Hello World'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi

