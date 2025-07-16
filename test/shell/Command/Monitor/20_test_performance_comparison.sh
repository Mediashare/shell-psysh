#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 20: Comparaison de performance"

# Étape 1: Array vs ArrayObject
test_session_sync "Array standard" \
'$arr = []; for($i = 0; $i < 1000; $i++) { $arr[] = $i; } count($arr)' \
'3'

# Étape 2: Différentes méthodes de boucle
test_session_sync "Boucle for vs foreach" \
'$data = range(1, 1000); $sum = 0; foreach($data as $val) { $sum += $val; } $sum' \
'3'

# Étape 3: String concatenation vs array join
test_session_sync "String concat vs implode" \
'$parts = []; for($i = 0; $i < 100; $i++) { $parts[] = "item$i"; } strlen(implode(",", $parts))' \
'2'

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
