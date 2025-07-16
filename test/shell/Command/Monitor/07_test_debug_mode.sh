#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 07: Mode debug"

# Étape 1: Test de variables en mode debug
test_session_sync "Calcul avec variables" \
'$x = 10; $y = 20; $z = $x + $y; echo $z' \
'30'

# Étape 2: Test d'affichage de variables
test_session_sync "Vérification des variables" \
'$a = "Hello"; $b = "World"; echo $a . " " . $b' \
'Hello World'

# Étape 3: Test de débogage avec array
test_session_sync "Array et debug" \
'$arr = [1, 2, 3]; echo count($arr)' \
'3'

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
