#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "PHPUnit: Command Create"

# Test création basique
test_session_sync "Créer un test simple" \
    "$PROJECT_ROtest_session_sync "Test command" --step \"phpunit:create 'App\Service\TestService'\"" \
    "✅" \
    check_contains

# Test création avec une classe simple
test_session_sync "Créer un test pour une classe utilitaire" \
    "$PROJECT_ROtest_session_sync "Test command" --step \"phpunit:create 'App\Util\Calculator'\"" \
    "✅" \
    check_contains

# Test avec namespace simple
test_session_sync "Créer un test avec namespace simple" \
    "$PROJECT_ROtest_session_sync "Test command" --step \"phpunit:create 'MyClass'\"" \
    "✅" \
    check_contains

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
