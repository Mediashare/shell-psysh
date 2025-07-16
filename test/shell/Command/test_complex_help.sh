#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "Complex Help System"
echo ""

# Test phpunit:help command itself
test_session_sync "phpunit:help command exists" \
    "test_session_sync "Test command" --step \"phpunit:help DateTime\"" \
    "DateTime" \
    "check_contains"

# Test complex help for Assert commands
test_session_sync "phpunit:assert complex help" \
    "test_session_sync "Test command" --step \"help phpunit:assert\"" \
    "Système d'assertions PHPUnit" \
    "check_contains"

test_session_sync "phpunit:assert-equals complex help" \
    "test_session_sync "Test command" --step \"help phpunit:assert-equals\"" \
    "Vérification" \
    "check_contains"

test_session_sync "phpunit:assert-type complex help" \
    "test_session_sync "Test command" --step \"help phpunit:assert-type\"" \
    "Vérification du type" \
    "check_contains"

test_session_sync "phpunit:assert-instance complex help" \
    "test_session_sync "Test command" --step \"help phpunit:assert-instance\"" \
    "instance" \
    "check_contains"

test_session_sync "phpunit:assert-count complex help" \
    "test_session_sync "Test command" --step \"help phpunit:assert-count\"" \
    "éléments" \
    "check_contains"

test_session_sync "phpunit:assert-empty complex help" \
    "test_session_sync "Test command" --step \"help phpunit:assert-empty\"" \
    "vide" \
    "check_contains"

test_session_sync "phpunit:assert-not-empty complex help" \
    "test_session_sync "Test command" --step \"help phpunit:assert-not-empty\"" \
    "pas vide" \
    "check_contains"

test_session_sync "phpunit:assert-true complex help" \
    "test_session_sync "Test command" --step \"help phpunit:assert-true\"" \
    "true" \
    "check_contains"

test_session_sync "phpunit:assert-false complex help" \
    "test_session_sync "Test command" --step \"help phpunit:assert-false\"" \
    "false" \
    "check_contains"

test_session_sync "phpunit:assert-null complex help" \
    "test_session_sync "Test command" --step \"help phpunit:assert-null\"" \
    "null" \
    "check_contains"

test_session_sync "phpunit:assert-not-null complex help" \
    "test_session_sync "Test command" --step \"help phpunit:assert-not-null\"" \
    "pas null" \
    "check_contains"

# Test complex help for Exception commands
test_session_sync "phpunit:expect-exception complex help" \
    "test_session_sync "Test command" --step \"help phpunit:expect-exception\"" \
    --expect "✅" --context phpunit
    "exception" \
    "check_contains"

test_session_sync "phpunit:expect-no-exception complex help" \
    "test_session_sync "Test command" --step \"help phpunit:expect-no-exception\"" \
    --expect "✅" --context phpunit
    "exception" \
    "check_contains"

test_session_sync "phpunit:assert-exception complex help" \
    "test_session_sync "Test command" --step \"help phpunit:assert-exception\"" \
    --expect "✅" --context phpunit
    "exception" \
    "check_contains"

test_session_sync "phpunit:assert-no-exception complex help" \
    "test_session_sync "Test command" --step \"help phpunit:assert-no-exception\"" \
    --expect "✅" --context phpunit
    "exception" \
    "check_contains"

# Test complex help for Config commands
test_session_sync "phpunit:config complex help" \
    "test_session_sync "Test command" --step \"help phpunit:config\"" \
    "config" \
    "check_contains"

test_session_sync "phpunit:create complex help" \
    "test_session_sync "Test command" --step \"help phpunit:create\"" \
    "create" \
    "check_contains"

test_session_sync "phpunit:export complex help" \
    "test_session_sync "Test command" --step \"help phpunit:export\"" \
    "export" \
    "check_contains"

test_session_sync "phpunit:list complex help" \
    "test_session_sync "Test command" --step \"help phpunit:list\"" \
    "list" \
    "check_contains"

test_session_sync "phpunit:help complex help" \
    "test_session_sync "Test command" --step \"help phpunit:help\"" \
    "aide" \
    "check_contains"

# Test complex help for Mock commands  
test_session_sync "phpunit:mock complex help" \
    "test_session_sync "Test command" --step \"help phpunit:mock\"" \
    "mock" \
    "check_contains"

test_session_sync "phpunit:partial-mock complex help" \
    "test_session_sync "Test command" --step \"help phpunit:partial-mock\"" \
    "partial" \
    "check_contains"

test_session_sync "phpunit:spy complex help" \
    "test_session_sync "Test command" --step \"help phpunit:spy\"" \
    "spy" \
    "check_contains"

# Test complex help for Runner commands
test_session_sync "phpunit:run complex help" \
    "test_session_sync "Test command" --step \"help phpunit:run\"" \
    "run" \
    "check_contains"

test_session_sync "phpunit:debug complex help" \
    "test_session_sync "Test command" --step \"help phpunit:debug\"" \
    "debug" \
    "check_contains"

test_session_sync "phpunit:monitor complex help" \
    "test_session_sync "Test command" --step \"help phpunit:monitor\"" \
    "monitor" \
    "check_contains"

test_session_sync "phpunit:profile complex help" \
    "test_session_sync "Test command" --step \"help phpunit:profile\"" \
    "profile" \
    "check_contains"

test_session_sync "phpunit:trace complex help" \
    "test_session_sync "Test command" --step \"help phpunit:trace\"" \
    "trace" \
    "check_contains"

test_session_sync "phpunit:watch complex help" \
    "test_session_sync "Test command" --step \"help phpunit:watch\"" \
    "watch" \
    "check_contains"

# Test complex help for Performance commands
test_session_sync "phpunit:benchmark complex help" \
    "test_session_sync "Test command" --step \"help phpunit:benchmark\"" \
    "benchmark" \
    "check_contains"

test_session_sync "phpunit:compare complex help" \
    "test_session_sync "Test command" --step \"help phpunit:compare\"" \
    "compare" \
    "check_contains"

test_session_sync "phpunit:compare-performance complex help" \
    "test_session_sync "Test command" --step \"help phpunit:compare-performance\"" \
    "performance" \
    "check_contains"

# Test complex help for Snapshot commands
test_session_sync "phpunit:snapshot complex help" \
    "test_session_sync "Test command" --step \"help phpunit:snapshot\"" \
    "snapshot" \
    "check_contains"

test_session_sync "phpunit:save-snapshot complex help" \
    "test_session_sync "Test command" --step \"help phpunit:save-snapshot\"" \
    "save" \
    "check_contains"

# Test complex help for Other commands
test_session_sync "phpunit:add complex help" \
    "test_session_sync "Test command" --step \"help phpunit:add\"" \
    "add" \
    "check_contains"

test_session_sync "phpunit:eval complex help" \
    "test_session_sync "Test command" --step \"help phpunit:eval\"" \
    "eval" \
    "check_contains"

test_session_sync "phpunit:expect complex help" \
    "test_session_sync "Test command" --step \"help phpunit:expect\"" \
    "expect" \
    "check_contains"

test_session_sync "phpunit:verify complex help" \
    "test_session_sync "Test command" --step \"help phpunit:verify\"" \
    "verify" \
    "check_contains"

# Test that help system works with examples
test_session_sync "Help with examples section" \
    "test_session_sync "Test command" --step \"help phpunit:assert-equals\"" \
    "examples" \
    "check_contains"

test_session_sync "Help with tips section" \
    "test_session_sync "Test command" --step \"help phpunit:assert-type\"" \
    "tips" \
    "check_contains"

test_session_sync "Help with related commands" \
    "test_session_sync "Test command" --step \"help phpunit:assert\"" \
    "related" \
    "check_contains"


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
