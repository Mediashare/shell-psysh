#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 23: Réactivité du shell"

# Étape 1: Test de réactivité
test_session_sync "Shell responsive" \
'$result = 42;' \
'echo "Test OK"' \
'Test OK'

# Étape 2: Test multiple
test_session_sync "Multiple commands" \
'$result = 1+1;' \
'$x = 10; echo $x' \
'10'
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
