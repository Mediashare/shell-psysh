#!/bin/bash

# Test script for Complex Help System
# Tests that all phpunit:* commands have getComplexHelp() method and help system works

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/test_utils.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Complex Help System"
echo ""

# Test phpunit:help command itself
run_test_step "phpunit:help command exists" \
    "../bin/psysh -c \"phpunit:help DateTime\"" \
    "DateTime" \
    "check_contains"

# Test complex help for Assert commands
run_test_step "phpunit:assert complex help" \
    "../bin/psysh -c \"help phpunit:assert\"" \
    "Système d'assertions PHPUnit" \
    "check_contains"

run_test_step "phpunit:assert-equals complex help" \
    "../bin/psysh -c \"help phpunit:assert-equals\"" \
    "Vérification" \
    "check_contains"

run_test_step "phpunit:assert-type complex help" \
    "../bin/psysh -c \"help phpunit:assert-type\"" \
    "Vérification du type" \
    "check_contains"

run_test_step "phpunit:assert-instance complex help" \
    "../bin/psysh -c \"help phpunit:assert-instance\"" \
    "instance" \
    "check_contains"

run_test_step "phpunit:assert-count complex help" \
    "../bin/psysh -c \"help phpunit:assert-count\"" \
    "éléments" \
    "check_contains"

run_test_step "phpunit:assert-empty complex help" \
    "../bin/psysh -c \"help phpunit:assert-empty\"" \
    "vide" \
    "check_contains"

run_test_step "phpunit:assert-not-empty complex help" \
    "../bin/psysh -c \"help phpunit:assert-not-empty\"" \
    "pas vide" \
    "check_contains"

run_test_step "phpunit:assert-true complex help" \
    "../bin/psysh -c \"help phpunit:assert-true\"" \
    "true" \
    "check_contains"

run_test_step "phpunit:assert-false complex help" \
    "../bin/psysh -c \"help phpunit:assert-false\"" \
    "false" \
    "check_contains"

run_test_step "phpunit:assert-null complex help" \
    "../bin/psysh -c \"help phpunit:assert-null\"" \
    "null" \
    "check_contains"

run_test_step "phpunit:assert-not-null complex help" \
    "../bin/psysh -c \"help phpunit:assert-not-null\"" \
    "pas null" \
    "check_contains"

# Test complex help for Exception commands
run_test_step "phpunit:expect-exception complex help" \
    "../bin/psysh -c \"help phpunit:expect-exception\"" \
    "exception" \
    "check_contains"

run_test_step "phpunit:expect-no-exception complex help" \
    "../bin/psysh -c \"help phpunit:expect-no-exception\"" \
    "exception" \
    "check_contains"

run_test_step "phpunit:assert-exception complex help" \
    "../bin/psysh -c \"help phpunit:assert-exception\"" \
    "exception" \
    "check_contains"

run_test_step "phpunit:assert-no-exception complex help" \
    "../bin/psysh -c \"help phpunit:assert-no-exception\"" \
    "exception" \
    "check_contains"

# Test complex help for Config commands
run_test_step "phpunit:config complex help" \
    "../bin/psysh -c \"help phpunit:config\"" \
    "config" \
    "check_contains"

run_test_step "phpunit:create complex help" \
    "../bin/psysh -c \"help phpunit:create\"" \
    "create" \
    "check_contains"

run_test_step "phpunit:export complex help" \
    "../bin/psysh -c \"help phpunit:export\"" \
    "export" \
    "check_contains"

run_test_step "phpunit:list complex help" \
    "../bin/psysh -c \"help phpunit:list\"" \
    "list" \
    "check_contains"

run_test_step "phpunit:help complex help" \
    "../bin/psysh -c \"help phpunit:help\"" \
    "aide" \
    "check_contains"

# Test complex help for Mock commands  
run_test_step "phpunit:mock complex help" \
    "../bin/psysh -c \"help phpunit:mock\"" \
    "mock" \
    "check_contains"

run_test_step "phpunit:partial-mock complex help" \
    "../bin/psysh -c \"help phpunit:partial-mock\"" \
    "partial" \
    "check_contains"

run_test_step "phpunit:spy complex help" \
    "../bin/psysh -c \"help phpunit:spy\"" \
    "spy" \
    "check_contains"

# Test complex help for Runner commands
run_test_step "phpunit:run complex help" \
    "../bin/psysh -c \"help phpunit:run\"" \
    "run" \
    "check_contains"

run_test_step "phpunit:debug complex help" \
    "../bin/psysh -c \"help phpunit:debug\"" \
    "debug" \
    "check_contains"

run_test_step "phpunit:monitor complex help" \
    "../bin/psysh -c \"help phpunit:monitor\"" \
    "monitor" \
    "check_contains"

run_test_step "phpunit:profile complex help" \
    "../bin/psysh -c \"help phpunit:profile\"" \
    "profile" \
    "check_contains"

run_test_step "phpunit:trace complex help" \
    "../bin/psysh -c \"help phpunit:trace\"" \
    "trace" \
    "check_contains"

run_test_step "phpunit:watch complex help" \
    "../bin/psysh -c \"help phpunit:watch\"" \
    "watch" \
    "check_contains"

# Test complex help for Performance commands
run_test_step "phpunit:benchmark complex help" \
    "../bin/psysh -c \"help phpunit:benchmark\"" \
    "benchmark" \
    "check_contains"

run_test_step "phpunit:compare complex help" \
    "../bin/psysh -c \"help phpunit:compare\"" \
    "compare" \
    "check_contains"

run_test_step "phpunit:compare-performance complex help" \
    "../bin/psysh -c \"help phpunit:compare-performance\"" \
    "performance" \
    "check_contains"

# Test complex help for Snapshot commands
run_test_step "phpunit:snapshot complex help" \
    "../bin/psysh -c \"help phpunit:snapshot\"" \
    "snapshot" \
    "check_contains"

run_test_step "phpunit:save-snapshot complex help" \
    "../bin/psysh -c \"help phpunit:save-snapshot\"" \
    "save" \
    "check_contains"

# Test complex help for Other commands
run_test_step "phpunit:add complex help" \
    "../bin/psysh -c \"help phpunit:add\"" \
    "add" \
    "check_contains"

run_test_step "phpunit:eval complex help" \
    "../bin/psysh -c \"help phpunit:eval\"" \
    "eval" \
    "check_contains"

run_test_step "phpunit:expect complex help" \
    "../bin/psysh -c \"help phpunit:expect\"" \
    "expect" \
    "check_contains"

run_test_step "phpunit:verify complex help" \
    "../bin/psysh -c \"help phpunit:verify\"" \
    "verify" \
    "check_contains"

# Test that help system works with examples
run_test_step "Help with examples section" \
    "../bin/psysh -c \"help phpunit:assert-equals\"" \
    "examples" \
    "check_contains"

run_test_step "Help with tips section" \
    "../bin/psysh -c \"help phpunit:assert-type\"" \
    "tips" \
    "check_contains"

run_test_step "Help with related commands" \
    "../bin/psysh -c \"help phpunit:assert\"" \
    "related" \
    "check_contains"

test_summary
