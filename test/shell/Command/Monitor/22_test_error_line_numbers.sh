#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 22: Numéros de ligne d'erreur"

# Étape 1: Erreur de syntaxe
test_session_sync "Erreur de syntaxe" \
'$x = ;' \
'(PARSE ERROR|Parse error|syntax error|unexpected|Error:.*syntax error|Error:.*Unclosed|Syntax error|PHP Parse error)'

# Étape 2: Erreur de fonction
test_session_sync "Fonction inexistante" \
'nonexistent_function()' \
'(Call to undefined function|Error:.*undefined function|Fatal error|TypeError)'

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
