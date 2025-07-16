#!/bin/bash

# Test script for Config commands
# Tests des commandes de configuration

# Obtenir le répertoire du script et charger les fonctions
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"
source "$SCRIPT_DIR/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "Config Commands Tests"

# Test 1: Configuration basique
    --step "echo 'Configuration test'" \ --context psysh --output-check contains --tag "default_session"
test_session_sync "Test configuration basique" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Configuration test" \
    --context shell

# Test 2: Test de variable de configuration
    --step '$config = --expect "test_value"; echo $config' \
test_session_sync "Test variable configuration" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect --expect "test_value" \
    --context monitor --output-check result

# Test 3: Test configuration avec retry
    --step "echo 'Config retry test'" \ --context psysh --output-check contains --tag "default_session"
test_session_sync "Test configuration avec retry" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Config retry test" \
    --context shell --retry 2

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
