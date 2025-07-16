#!/bin/bash

# Test script simple pour Assert commands - Version de base
# Utilise uniquement les fonctions de base qui marchent bien

# Obtenir le répertoire du script et charger l'exécuteur unifié
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"
source "$SCRIPT_DIR/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "Assert Commands - Tests de Base"

# =============================================================================
# TESTS DE BASE - Fonctions qui marchent
# =============================================================================

# Test 1: Assert avec condition simple
    --step "phpunit:assert '2 + 2 == 4'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Assert condition simple" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Assertion réussie" \
    --context phpunit --output-check contains

# Test 2: Assert booléen true
    --step "phpunit:assert 'true'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Assert booléen true" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Assertion réussie" \
    --context phpunit

# Test 3: Assert booléen false (erreur attendue)
    --step "phpunit:assert 'false'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Assert booléen false" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Assertion échouée" \
    --context phpunit --output-check error

# Test 4: Test phpunit simple
    --step "phpunit:assert '3 * 3 == 9'" --context phpunit --expect "Assertion réussie" --output-check contains --tag "phpunit_session"
test_session_sync "Test phpunit simple" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test 5: Test avec retry
   --step '$result = 42' --context 'psysh' --expect '42' \
test_session_sync "Assert avec retry" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
   --step "phpunit:assert '$result === 42'" --context 'phpunit' --expect "Assertion réussie" \ --output-check contains --tag "phpunit_session"
   --retry 2 --timeout 10

# Test 6: Test avec debug
    --step "phpunit:assert 'false'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Assert avec debug" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Assertion échouée" \
    --context phpunit --debug --output-check error

# Test 7: Test avec timeout
    --step "phpunit:assert 'true'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Assert avec timeout" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Assertion réussie" \
    --context phpunit --timeout 5

# Test 8: Test monitor expression simple
    --step "echo 'Hello World'" \ --context psysh --output-check contains --tag "default_session"
test_session_sync "Test monitor expression simple" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"
    --expect "Hello World" \
    --context monitor

# Test 9: Test d'erreur monitor
    --step "invalid_php_function()" \ --context psysh --output-check contains --tag "default_session"
test_session_sync "Test erreur monitor" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"
    --expect "Call to undefined function" \
    --context monitor --output-check error

# Test 10: Test shell responsiveness
    --step "echo 'test'" \ --context psysh --output-check contains --tag "default_session"
test_session_sync "Test shell responsiveness" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context shell \
    --output-check contains \
    --shell \
    --tag "shell_session"
    --expect "test" \
    --context shell

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
