#!/bin/bash

# Test refactorisé avec test_session_sync_enhanced
# Variables et expressions basiques

# Obtenir le répertoire du script et charger les fonctions
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "Variables et expressions basiques"

# Test complet des variables de base avec plusieurs étapes dans la même session
test_session_sync "Variables et expressions basiques" \
    --context monitor \
    --input-type multiline \
    --output-check contains \
    --timeout 30 \
    --step '$x = 42; echo $x;' \
    --expect '42' \
    --step '$a = 10; $b = 20; $c = $a + $b; echo $c;' \
    --expect '30' \
    --step 'echo array_sum(range(1, 10))' \
    --expect '55' \
    --step 'echo array_sum(range(1, 100))' \
    --expect '5050'

# Test des chaînes de caractères
test_session_sync "Chaînes de caractères" \
    --context monitor \
    --input-type multiline \
    --output-check contains \
    --timeout 30 \
    --step '"Hello" . " " . "World"' \
    --expect 'Hello World' \
    --step 'echo strlen("Hello World")' \
    --expect '11' \
    --step '$str = "Hello"; $str .= " World"; echo $str;' \
    --expect 'Hello World'

# Test des calculs mathématiques
test_session_sync "Calculs mathématiques" \
    --context monitor \
    --input-type multiline \
    --output-check contains \
    --timeout 30 \
    --step '(5 + 3) * 2 - 1' \
    --expect '15' \
    --step 'echo count([1, 2, 3, 4, 5])' \
    --expect '5' \
    --step 'pow(10, 15)' \
    --expect '1000000000000000'

# Test des erreurs avec gestion d'erreur appropriée
test_session_sync "Gestion des erreurs" \
    --context monitor \
    --input-type multiline \
    --output-check error \
    --timeout 30 \
    --retry 2 \
    --step '$undefined_var' \
    --expect 'Undefined variable' \
    --step '$x = ;' \
    --expect 'Syntax error' \
    --step '1 / 0' \
    --expect 'Division by zero'

# Test de synchronisation bidirectionnelle
test_session_sync "Synchronisation entre commandes" \
    --context monitor \
    --input-type multiline \
    --output-check contains \
    --timeout 60 \
    --sync-test \
    --step '$global_var = 123;' \
    --step 'echo $global_var;' \
    --expect '123' \
    --step '$counter = 5; $counter++;' \
    --step 'echo $counter;' \
    --expect '6'

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
