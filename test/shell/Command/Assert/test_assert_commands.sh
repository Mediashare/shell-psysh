#!/bin/bash

# Test script for Assert commands - Version enhanced avec test_session_sync
# Utilisation de la fonction test_session_sync améliorée

# Obtenir le repertoire du script et charger l'executeur unifie
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "Assert Commands - Version Enhanced"

# =============================================================================
# TESTS DE BASE SIMPLIFIES
# =============================================================================

# Importer la fonction test_session_sync
source "$SCRIPT_DIR/../../lib/func/test_session_sync_enhanced.sh"

# Test 1: Assert avec condition simple
    --step "phpunit:assert '2 + 2 == 4'" --context phpunit --expect "Assertion réussie" --output-check contains --tag "phpunit_session"
test_session_sync "Assert condition simple" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test 2: Assert avec condition fausse (test d'erreur)
    --step "phpunit:assert '1 == 2'" --context phpunit --expect "Assertion échouée" --output-check error --tag "phpunit_session"
test_session_sync "Assert condition fausse" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test 3: Assert avec booleens
    --step "phpunit:assert 'true'" --context phpunit --expect "Assertion réussie" --output-check contains --tag "phpunit_session"
test_session_sync "Assert booleen true" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

    --step "phpunit:assert 'false'" --context phpunit --expect "Assertion échouée" --output-check error --tag "phpunit_session"
test_session_sync "Assert booleen false" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# =============================================================================
# TESTS AVEC DONNEES SIMPLES  
# =============================================================================

# Test 4: Monitor avec expression simple (correction: 5 + 5 = 10)
    --step "5 + 5" --context monitor --expect "10" --output-check result --tag "monitor_session"
test_session_sync "Test monitor expression" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"

# Test 5: Monitor avec variable
    --step 'echo "test"' --context monitor --expect "test"
test_session_sync "Test monitor variable" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"

# Test 6: Monitor avec calcul
    --step '$result = 2 * 3; echo $result' --context monitor --expect "6" --output-check result
test_session_sync "Test monitor calcul" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"

# Test 6b: Monitor avec calcul séparé en plusieurs étapes
    --step '$result = 2 * 3' --context monitor --expect "6" --output-check result \
test_session_sync "Test monitor calcul multi-étapes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"
    --step 'echo $result' --context monitor --expect "6"

# Test 6c: Test avec variables partagées et sync-test
    --step '$var1 = "Hello"' --context monitor --expect "Hello" --output-check result --sync-test \
test_session_sync "Test variables partagées avec sync" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "sync_session"
    --step '$var2 = "World"' --context monitor --expect "World" --output-check result --sync-test \
    --step 'echo $var1 . " " . $var2' --context monitor --expect "Hello World" --sync-test

# =============================================================================
# TESTS AVANCES
# =============================================================================

# Test 7: Assert avec retry
    --step "phpunit:assert 'true'" --context phpunit --expect "Assertion réussie" --retry 2 --timeout 10 --output-check contains --tag "phpunit_session"
test_session_sync "Assert avec retry" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test 8: Assert avec debug (multiples expectations et output-check)
    --step "phpunit:assert 'false'" --context phpunit \ --output-check contains --tag "phpunit_session"
test_session_sync "Assert avec debug" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Assertion échouée" --output-check error \
    --expect "Expected: false" --output-check debug \
    --expect "Actual: true" --output-check debug \
    --debug

# Test 9: Test avec fonction simple
    --step '$string = "test"; strlen($string)' --context monitor --expect "4" --output-check result
test_session_sync "Test avec fonction" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test 10: Test persistance de variable
    --step '$testVar = "Hello"' --context monitor --expect "Hello" --output-check result \
test_session_sync "Mixed context test" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --step 'echo $testVar' --context psysh --expect "Hello"

# =============================================================================
# TESTS COMPLEXES AVEC SETUP/CLEANUP
# =============================================================================

# Test 11: Test complexe avec setup et cleanup
    --setup "echo 'Initialisation...'" --setup-context shell \
test_session_sync "Test complexe avec héritage" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --step 'phpunit:assert "true"' --context phpunit --expect "Assertion réussie" --retry 3 \
    --cleanup "echo 'Nettoyage...'" --cleanup-context shell

# Test 12: Test avec mock
    --step 'send_email("test@example.com")' --context monitor \
test_session_sync "Test avec mock" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --mock "send_email=echo 'Email simulé:'" \
    --expect "Email simulé:" \
    --output-check contains

# =============================================================================
# TESTS D'ERREURS
# =============================================================================

# Test 13: Gestion d'erreur variable indefinie
    --step "phpunit:assert 'undefined_variable'" --context phpunit --expect "Undefined variable" --output-check error --tag "phpunit_session"
test_session_sync "Gestion erreur variable indefinie" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test 14: Fonction inexistante
    --step 'invalid_php_function()' --context monitor --expect "Call to undefined function" --output-check error
test_session_sync "Test fonction inexistante" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# =============================================================================
# TESTS DE RESPONSIVENESS ET SYNCHRONISATION
# =============================================================================

# Test 15: Test shell responsiveness avec session sync
    --step '$setup = "active"' --context monitor --expect "active" --output-check result \
test_session_sync "Test shell responsiveness avec sync" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context shell \
    --output-check contains \
    --shell \
    --tag "shell_session"
    --step 'echo $setup' --context monitor --expect "active"

# Test 16: Test benchmark et performance
    --step 'for($i=0; $i<1000; $i++){ $sum += $i; }' --context monitor --benchmark --memory-check \
test_session_sync "Test benchmark" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --expect "--metrics" \
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "499500" --output-check result --timeout 30

# Test 17: Test avec conditions
    --step 'touch /tmp/test_condition' --context shell \
test_session_sync "Test avec conditions" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --step 'echo "Condition remplie"' --context shell --condition "[ -f /tmp/test_condition ]" --expect "Condition remplie" \
    --cleanup "rm -f /tmp/test_condition" --cleanup-context shell

# Test 18: Test asynchrone avancé
    --step 'sleep 2 && echo "Tâche 1 terminée"' --context shell --async --step-id "task1" \
test_session_sync "Test asynchrone" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "sync_session"
    --step 'sleep 1 && echo "Tâche 2 terminée"' --context shell --async --step-id "task2" \
    --step 'echo "Attente des tâches..."' --context shell --wait-for "task1" --wait-for "task2" --expect "Attente des tâches..."

# Test 19: Test avec fail-fast
    --step 'phpunit:assert "true"' --context phpunit --expect "Assertion réussie" \
test_session_sync "Test fail-fast" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --step 'phpunit:assert "false"' --context phpunit --expect "Assertion échouée" --fail-fast --output-check error \
    --step 'echo "Ne devrait pas s\'exécuter"' --context shell --expect "Ne devrait pas s'exécuter"

# Test 20: Test avec répétition et délai
    --step 'echo "Répétition"' --context shell --repeat 3 --delay 1 --expect "Répétition"
test_session_sync "Test répétition et délai" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# =============================================================================
# TESTS AVANCES AVEC MULTIPLES OUTPUT-CHECK
# =============================================================================

# Test 21: Test avec multiples expectations et output-check correspondants
    --step 'phpunit:assert "false"' --context phpunit --debug \
test_session_sync "Test multiples expectations" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Assertion échouée" --output-check error \
    --expect "Expected: false" --output-check debug \
    --expect "Got: true" --output-check debug \
    --expect "File:" --output-check debug

# Test 22: Test avec result output-check automatique
    --step '$x = 42; $y = 8; $x + $y' --context monitor --expect "50" --output-check result
test_session_sync "Test result output-check" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test 23: Test sync-test avec variables entre contextes
    --step '$globalVar = "shared_value"' --context monitor --expect "shared_value" --output-check result --sync-test \
test_session_sync "Test sync variables entre contextes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "sync_session"
    --step 'echo $globalVar' --context psysh --expect "shared_value" --sync-test \
    --step 'phpunit:assert "$globalVar == \"shared_value\""' --context phpunit --expect "Assertion réussie" --sync-test

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
