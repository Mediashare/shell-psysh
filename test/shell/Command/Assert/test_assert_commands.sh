#!/bin/bash

# Test script for Assert commands - Version corrigee
# Utilisation des fonctions de base sans problemes de quotes

# Obtenir le repertoire du script et charger l'executeur unifie
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "Assert Commands - Version Corrigee"

# =============================================================================
# TESTS DE BASE SIMPLIFIES
# =============================================================================

# Test 1: Assert avec condition simple
test_execute "Assert condition simple" \
    "phpunit:assert '2 + 2 == 4'" \
    "Assertion réussie" \
    --context=phpunit --output-check=contains

# Test 2: Assert avec condition fausse (test d'erreur)
test_execute "Assert condition fausse" \
    "phpunit:assert '1 == 2'" \
    "Assertion échouée" \
    --context=phpunit --output-check=error

# Test 3: Assert avec booleens
test_execute "Assert booleen true" \
    "phpunit:assert 'true'" \
    "Assertion réussie" \
    --context=phpunit

test_execute "Assert booleen false" \
    "phpunit:assert 'false'" \
    "Assertion échouée" \
    --context=phpunit --output-check=error

# =============================================================================
# TESTS AVEC DONNEES SIMPLES
# =============================================================================

# Test 4: Monitor avec expression simple
test_execute "Test monitor expression" \
    'echo 5 + 5' \
    "5 + 5" \
    --context=monitor

# Test 5: Monitor avec variable
test_execute "Test monitor variable" \
    'echo "test"' \
    "test" \
    --context=monitor

# Test 6: Monitor avec calcul
test_execute "Test monitor calcul" \
    '$result = 2 * 3; echo $result' \
    "6" \
    --context=monitor

# =============================================================================
# TESTS AVANCES
# =============================================================================

# Test 7: Assert avec retry
test_execute "Assert avec retry" \
    "phpunit:assert 'true'" \
    "Assertion réussie" \
    --context=phpunit --retry=2 --timeout=10

# Test 8: Assert avec debug
test_execute "Assert avec debug" \
    "phpunit:assert 'false'" \
    "Assertion échouée" \
    --context=phpunit --debug --output-check=error

# Test 9: Test avec fonction simple
test_execute "Test avec fonction" \
    '$string = \"test\";echo strlen($string)' \
    "4" \
    --context=monitor

# Test 10: Test persistance de variable
test_session_sync "Mixed context test" \
        --step '$testVar = "Hello"' --context monitor --expect "Hello" \
        --step 'echo $testVar' --context psysh --expect "Hello"

# =============================================================================
# TESTS D'ERREURS
# =============================================================================

# Test 11: Gestion d'erreur variable indefinie
test_execute "Gestion erreur variable indefinie" \
    "phpunit:assert 'undefined_variable'" \
    "Undefined variable" \
    --context=phpunit --output-check=error

# Test 12: Fonction inexistante
test_execute "Test fonction inexistante" \
    'invalid_php_function()' \
    "Call to undefined function" \
    --context=monitor --output-check=error

# =============================================================================
# TESTS DE RESPONSIVENESS
# =============================================================================

# Test 13: Test shell responsiveness
test_execute "Test shell responsiveness setup" \
    '$setup = "active"' \
    "" \
    --context=monitor

test_execute "Test shell responsiveness verify" \
    'echo $setup' \
    "active" \
    --context=monitor

# Afficher le resume
test_summary

# Nettoyer l'environnement de test
cleanup_test_environment

# Sortir avec le code approprie
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
