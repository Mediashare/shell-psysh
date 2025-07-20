#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "assert commands"


# =============================================================================
# TESTS DE BASE SIMPLIFIES
# =============================================================================

# Test 1: Assert avec condition simple
test_session_sync "Assert condition simple" \
    --step 'phpunit:assert "2 + 2 == 4"' \
    --context psysh \
    --expect '✅' \
    --timeout 10 \
    --retry 1

# Test 2: Assert avec condition fausse (test d'erreur)
test_session_sync "Assert condition fausse" \
    --step 'phpunit:assert "1 == 2"' --context psysh --expect "Assertion échouée" --output-check error --timeout 5

# Test 3: Assert avec booleens
test_session_sync "Assert booleen true" \
    --step "phpunit:assert 'true'" --context phpunit --expect "Assertion réussie"

test_session_sync "Assert booleen false" \
    --step "phpunit:assert 'false'" --context phpunit --expect "Assertion échouée" --output-check error

# =============================================================================
# TESTS AVEC DONNEES SIMPLES  
# =============================================================================

# Test 4: Psysh avec expression simple (correction: 5 + 5 = 10)
test_session_sync "Test psysh expression" \
    --step "5 + 5" --context psysh --expect "10" --output-check result --debug

# Test 5: Psysh avec variable
test_session_sync "Test psysh variable" \
    --step 'echo "test"' --context psysh --expect "test"

# Test 6: Psysh avec calcul
test_session_sync "Test psysh calcul" \
    --step '$result = 2 * 3; echo $result' --context psysh --expect "6" --output-check result

# Test 6b: Psysh avec calcul séparé en plusieurs étapes
test_session_sync "Test psysh calcul multi-étapes" \
    --step '$result = 2 * 3' --context psysh --expect "6" --output-check result \
    --step 'echo $result' --context psysh --expect "6"

# Test 6c: Test avec variables partagées et sync-test
test_session_sync "Test variables partagées avec sync" \
    --step '$var1 = "Hello"' --context psysh --expect "Hello" --output-check result --sync-test \
    --step '$var2 = "World"' --context psysh --expect "World" --output-check result --sync-test \
    --step 'echo $var1 . " " . $var2' --context psysh --expect "Hello World" --sync-test

# =============================================================================
# TESTS AVANCES
# =============================================================================

# Test 7: Assert avec retry
test_session_sync "Assert avec retry" \
    --step "phpunit:assert 'true'" --context phpunit --expect "Assertion réussie" --retry 2 --timeout 10

# Test 8: Assert avec debug (multiples expectations et output-check)
test_session_sync "Assert avec debug" \
    --step "phpunit:assert 'false'" --context phpunit \
    --expect "Assertion échouée" --output-check error \
    --expect "Expected: false" --output-check debug \
    --expect "Actual: true" --output-check debug \
    --debug

# Test 9: Test avec fonction simple
test_session_sync "Test avec fonction" \
    --step '$string = "test"; strlen($string)' --context psysh --expect "4" --output-check result

# Test 10: Test persistance de variable
test_session_sync "Mixed context test" \
    --step '$testVar = "Hello"' --context psysh --expect "Hello" --output-check result \
    --step 'echo $testVar' --context psysh --expect "Hello"

# =============================================================================
# TESTS COMPLEXES AVEC SETUP/CLEANUP
# =============================================================================

# Test 11: Test complexe avec setup et cleanup
test_session_sync "Test complexe avec héritage" \
    --setup "echo 'Initialisation...'" --setup-context shell \
    --step 'phpunit:assert "true"' --context phpunit --expect "Assertion réussie" --retry 3 \
    --cleanup "echo 'Nettoyage...'" --cleanup-context shell

# Test 12: Test avec mock
test_session_sync "Test avec mock" \
    --step 'send_email("test@example.com")' --context psysh \
    --mock "send_email=echo 'Email simulé:'" \
    --expect "Email simulé:" \
    --output-check contains

# =============================================================================
# TESTS D'ERREURS
# =============================================================================

# Test 13: Gestion d'erreur variable indefinie
test_session_sync "Gestion erreur variable indefinie" \
    --step "phpunit:assert 'undefined_variable'" --context phpunit --expect "Undefined variable" --output-check error

# Test 14: Fonction inexistante
test_session_sync "Test fonction inexistante" \
    --step 'invalid_php_function()' --context psysh --expect "Call to undefined function" --output-check error

# =============================================================================
# TESTS DE RESPONSIVENESS ET SYNCHRONISATION
# =============================================================================

# Test 15: Test shell responsiveness avec session sync
test_session_sync "Test shell responsiveness avec sync" \
    --step '$setup = "active"' --context psysh --expect "active" --output-check result \
    --step 'echo $setup' --context psysh --expect "active"

# Test 16: Test benchmark et performance
test_session_sync "Test benchmark" --metrics --performance \
    --step 'for($i=0; $i<1000; $i++){ $sum += $i; }' --context psysh --benchmark --memory-check \
    --expect "499500" --output-check result --timeout 30

# Test 17: Test avec conditions
test_session_sync "Test avec conditions" \
    --step 'touch /tmp/test_condition' --context shell \
    --step 'echo "Condition remplie"' --context shell --condition "[ -f /tmp/test_condition ]" --expect "Condition remplie" \
    --cleanup "rm -f /tmp/test_condition" --cleanup-context shell

# Test 18: Test asynchrone avancé
test_session_sync "Test asynchrone" \
    --step 'sleep 2 && echo "Tâche 1 terminée"' --context shell --async --step-id "task1" \
    --step 'sleep 1 && echo "Tâche 2 terminée"' --context shell --async --step-id "task2" \
    --step 'echo "Attente des tâches..."' --context shell --wait-for "task1" --wait-for "task2" --expect "Attente des tâches..."

# Test 19: Test avec fail-fast
test_session_sync "Test fail-fast" \
    --step 'phpunit:assert "true"' --context phpunit --expect "Assertion réussie" \
    --step 'phpunit:assert "false"' --context phpunit --expect "Assertion échouée" --fail-fast --output-check error \
    --step 'echo "Ne devrait pas run"' --context shell --expect "Ne devrait pas s'exécuter"

# Test 20: Test avec répétition et délai
test_session_sync "Test répétition et délai" \
    --step 'echo "Répétition"' --context shell --repeat 3 --delay 1 --expect "Répétition"

# =============================================================================
# TESTS AVANCES AVEC MULTIPLES OUTPUT-CHECK
# =============================================================================

# Test 21: Test avec multiples expectations et output-check correspondants
test_session_sync "Test multiples expectations" \
    --step 'phpunit:assert "false"' --context phpunit --debug \
    --expect "Assertion échouée" --output-check error \
    --expect "Expected: false" --output-check debug \
    --expect "Got: true" --output-check debug \
    --expect "File:" --output-check debug

# Test 22: Test avec result output-check automatique
test_session_sync "Test result output-check" \
    --step '$x = 42; $y = 8; $x + $y' --context psysh --expect "50" --output-check result

# Test 23: Test sync-test avec variables entre contextes
test_session_sync "Test sync variables entre contextes" \
    --step '$globalVar = "shared_value"' --context psysh --expect "shared_value" --output-check result --sync-test \
    --step 'echo $globalVar' --context psysh --expect "shared_value" --sync-test \
    --step 'phpunit:assert "$globalVar == \"shared_value\""' --context phpunit --expect "Assertion réussie" --sync-test

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
