#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "Variables et expressions basiques"

# Test complet des variables de base avec plusieurs étapes dans la même session
test_session_sync "Variables et expressions basiques" \
    --step '$x = 42; echo $x;' \
    --context psysh \
    --psysh \
    --tag "default_session" \
    --expect '42' \
    --output-check exact \
    --step '$a = 10; $b = 20; $c = $a + $b; echo $c;' \
    --expect '30' \
    --step 'echo array_sum(range(1, 10))' \
    --expect '55' \
    --step 'echo array_sum(range(1, 100))' \
    --expect '5050'

# Test des chaînes de caractères
test_session_sync "Chaînes de caractères" \
    --step '"Hello" . " " . "World"' \
    --context psysh \
    --psysh \
    --tag "default_session" \
    --expect 'Hello World' \
    --output-check exact \
    --step 'echo strlen("Hello World")' \
    --expect '11' \
    --step '$str = "Hello"; $str .= " World"; echo $str;' \
    --expect 'Hello World'

# Test des calculs mathématiques
test_session_sync "Calculs mathématiques" \
    --step '(5 + 3) * 2 - 1' \
    --context psysh \
    --psysh \
    --tag "default_session" \
    --expect '15' \
    --output-check exact \
    --step 'echo count([1, 2, 3, 4, 5])' \
    --expect '5' \
    --step 'pow(2, 10)' \
    --expect '1024'

# Test de synchronisation bidirectionnelle
test_session_sync "Synchronisation entre commandes" \
    --step '$global_var = 123;' \
    --context psysh \
    --psysh \
    --tag "sync_session" \
    --step 'echo $global_var;' \
    --expect '123' \
    --output-check exact \
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
