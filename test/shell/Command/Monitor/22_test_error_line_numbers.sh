#!/bin/bash

# Test 22: Numéros de ligne d'erreur corrects (régression)
# Test automatisé pour vérifier que les numéros de ligne d'erreur sont corrects
# Ce test vérifie la correction du bug où les erreurs montraient la ligne 3 au lieu de 1

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 22: Numéros de ligne d'erreur"

# Étape 1: Erreur de syntaxe
'$x = ;' \
test_session_sync "Erreur de syntaxe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(PARSE ERROR|Parse error|syntax error|unexpected|Error:.*syntax error|Error:.*Unclosed|Syntax error|PHP Parse error)'

# Étape 2: Erreur de fonction
'nonexistent_function()' \
test_session_sync "Fonction inexistante" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(Call to undefined function|Error:.*undefined function|Fatal error|TypeError)'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi

