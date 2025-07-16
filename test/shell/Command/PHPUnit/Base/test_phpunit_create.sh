#!/bin/bash

# Test phpunit:create command
# Tests all options and scenarios for creating PHPUnit tests

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/func/loader.sh"
source "$SCRIPT_DIR/../../../lib/func/test_session_sync_enhanced.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "PHPUnit Create Command Tests"

# Test 1: Basic class creation
    --step "phpunit:create TestService" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Basic class creation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Test créé" \
    --context phpunit

# Test 2: Namespace class creation
    --step "phpunit:create App\\Service\\UserService" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Namespace class creation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Test créé" \
    --context phpunit

# Test 3: Controller class creation
    --step "phpunit:create App\\Controller\\ApiController" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Controller class creation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Test créé" \
    --context phpunit

# Test 4: Repository class creation
    --step "phpunit:create App\\Repository\\UserRepository" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Repository class creation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Test créé" \
    --context phpunit

# Test 5: Error handling - no class name
    --step "phpunit:create" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Error handling - no class name" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "required" \
    --context phpunit --output-check error

# Test 6: Complex namespace
    --step "phpunit:create My\\Domain\\User\\Service\\EmailService" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Complex namespace" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
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

