#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "config commands"

# Test 1: Configuration basique
test_session_sync "Test configuration basique" \
    --step "echo 'Configuration test'" \
    --expect "Configuration test" \
    --context shell

# Test 2: Test de variable de configuration
test_session_sync "Test variable configuration" \
    --step '$config = "test_value"; echo $config' \
    --expect "test_value" \
    --context monitor --output-check result

# Test 3: Test configuration avec retry
test_session_sync "Test configuration avec retry" \
    --step "echo 'Config retry test'" \
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
