#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 21: Résultats des expressions simples"

# Étape 1: Expression simple
test_session_sync "Expression simple" \
'42' \
'42'

# Étape 2: Calcul
test_session_sync "Calcul basique" \
'5 + 3' \
'8'

# Étape 3: String
test_session_sync "String" \
'echo "Hello World"' \
'Hello World'

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
