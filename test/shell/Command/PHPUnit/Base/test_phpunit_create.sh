#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "PHPUnit Create Command Tests"

# Test 1: Basic class creation
test_session_sync "Basic class creation" \
    --step "phpunit:create TestService" \
    --expect "Test créé" \
    --context phpunit

# Test 2: Namespace class creation
test_session_sync "Namespace class creation" \
    --step "phpunit:create App\\Service\\UserService" \
    --expect "Test créé" \
    --context phpunit

# Test 3: Controller class creation
test_session_sync "Controller class creation" \
    --step "phpunit:create App\\Controller\\ApiController" \
    --expect "Test créé" \
    --context phpunit

# Test 4: Repository class creation
test_session_sync "Repository class creation" \
    --step "phpunit:create App\\Repository\\UserRepository" \
    --expect "Test créé" \
    --context phpunit

# Test 5: Error handling - no class name
test_session_sync "Error handling - no class name" \
    --step "phpunit:create" \
    --expect "required" \
    --context phpunit --output-check error

# Test 6: Complex namespace
test_session_sync "Complex namespace" \
    --step "phpunit:create My\\Domain\\User\\Service\\EmailService" \
    --expect "Test créé" \
    --context phpunit

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
