#!/bin/bash

# Test refactorisé avec test_session_sync_enhanced
# Variables et expressions basiques

# Obtenir le répertoire du script et charger les fonctions
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"
source "$SCRIPT_DIR/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "Variables et expressions basiques"

# Test complet des variables de base avec plusieurs étapes dans la même session
    --context monitor \
test_session_sync "Variables et expressions basiques" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
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
    --context monitor \
test_session_sync "Chaînes de caractères" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
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
    --context monitor \
test_session_sync "Calculs mathématiques" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
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
    --context monitor \
test_session_sync "Gestion des erreurs" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
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
    --context monitor \
test_session_sync "Synchronisation entre commandes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "sync_session"
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
