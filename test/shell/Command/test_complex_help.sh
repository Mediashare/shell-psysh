#!/bin/bash

# Test script for Complex Help System
# Tests that all phpunit:* commands have getComplexHelp() method and help system works

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Complex Help System"
echo ""

# Test phpunit:help command itself
    --step "phpunit:help DateTime" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:help command exists" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "DateTime" \
    --output-check contains

# Test complex help for Assert commands
    --step "help phpunit:assert" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:assert complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "Système d'assertions PHPUnit" \
    --output-check contains

    --step "help phpunit:assert-equals" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:assert-equals complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "Vérification" \
    --output-check contains

    --step "help phpunit:assert-type" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:assert-type complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "Vérification du type" \
    --output-check contains

    --step "help phpunit:assert-instance" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:assert-instance complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "instance" \
    --output-check contains

    --step "help phpunit:assert-count" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:assert-count complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "éléments" \
    --output-check contains

    --step "help phpunit:assert-empty" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:assert-empty complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "vide" \
    --output-check contains

    --step "help phpunit:assert-not-empty" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:assert-not-empty complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "pas vide" \
    --output-check contains

    --step "help phpunit:assert-true" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:assert-true complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "true" \
    --output-check contains

    --step "help phpunit:assert-false" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:assert-false complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "false" \
    --output-check contains

    --step "help phpunit:assert-null" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:assert-null complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "null" \
    --output-check contains

    --step "help phpunit:assert-not-null" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:assert-not-null complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "pas null" \
    --output-check contains

# Test complex help for Exception commands
    --step "help phpunit:expect-exception" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:expect-exception complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "✅" --context phpunit
    "exception" \
    --output-check contains

    --step "help phpunit:expect-no-exception" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:expect-no-exception complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "✅" --context phpunit
    "exception" \
    --output-check contains

    --step "help phpunit:assert-exception" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:assert-exception complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "✅" --context phpunit
    "exception" \
    --output-check contains

    --step "help phpunit:assert-no-exception" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:assert-no-exception complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "✅" --context phpunit
    "exception" \
    --output-check contains

# Test complex help for Config commands
    --step "help phpunit:config" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:config complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "config" \
    --output-check contains

    --step "help phpunit:create" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:create complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "create" \
    --output-check contains

    --step "help phpunit:export" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:export complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "export" \
    --output-check contains

    --step "help phpunit:list" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:list complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "list" \
    --output-check contains

    --step "help phpunit:help" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:help complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "aide" \
    --output-check contains

# Test complex help for Mock commands  
    --step "help phpunit:mock" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:mock complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "mock" \
    --output-check contains

    --step "help phpunit:partial-mock" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:partial-mock complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "partial" \
    --output-check contains

    --step "help phpunit:spy" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:spy complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "spy" \
    --output-check contains

# Test complex help for Runner commands
    --step "help phpunit:run" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:run complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "run" \
    --output-check contains

    --step "help phpunit:debug" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:debug complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "debug" \
    --output-check contains

    --step "help phpunit:monitor" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:monitor complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "monitor" \
    --output-check contains

    --step "help phpunit:profile" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:profile complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "profile" \
    --output-check contains

    --step "help phpunit:trace" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:trace complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "trace" \
    --output-check contains

    --step "help phpunit:watch" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:watch complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "watch" \
    --output-check contains

# Test complex help for Performance commands
    --step "help phpunit:benchmark" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:benchmark complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "benchmark" \
    --output-check contains

    --step "help phpunit:compare" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:compare complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "compare" \
    --output-check contains

    --step "help phpunit:compare-performance" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:compare-performance complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "performance" \
    --output-check contains

# Test complex help for Snapshot commands
    --step "help phpunit:snapshot" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:snapshot complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "snapshot" \
    --output-check contains

    --step "help phpunit:save-snapshot" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:save-snapshot complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "save" \
    --output-check contains

# Test complex help for Other commands
    --step "help phpunit:add" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:add complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "add" \
    --output-check contains

    --step "help phpunit:eval" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:eval complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "eval" \
    --output-check contains

    --step "help phpunit:expect" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:expect complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "expect" \
    --output-check contains

    --step "help phpunit:verify" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:verify complex help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    "verify" \
    --output-check contains

# Test that help system works with examples
    --step "help phpunit:assert-equals" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Help with examples section" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "examples" \
    --output-check contains

    --step "help phpunit:assert-type" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Help with tips section" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "tips" \
    --output-check contains

    --step "help phpunit:assert" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Help with related commands" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "related" \
    --output-check contains

test_summary
