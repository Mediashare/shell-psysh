#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "Runner Commands"
echo ""

# Test PHPUnitRunCommand (phpunit:run)
test_session_sync "phpunit:run basic execution" \
    --step "phpunit:run --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitRunAllCommand (phpunit:run-all)
test_session_sync "phpunit:run-all help" \
    --step "phpunit:run-all --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitRunProjectCommand (phpunit:run-project)
test_session_sync "phpunit:run-project help" \
    --step "phpunit:run-project --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitDebugCommand (phpunit:debug)
test_session_sync "phpunit:debug help" \
    --step "phpunit:debug --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitMonitorCommand (phpunit:monitor)
test_session_sync "phpunit:monitor help" \
    --step "phpunit:monitor --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitProfileCommand (phpunit:profile)
test_session_sync "phpunit:profile help" \
    --step "phpunit:profile --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitTraceCommand (phpunit:trace)
test_session_sync "phpunit:trace help" \
    --step "phpunit:trace --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitWatchCommand (phpunit:watch)
test_session_sync "phpunit:watch help" \
    --step "phpunit:watch --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitExplainCommand (phpunit:explain)
test_session_sync "phpunit:explain help" \
    --step "phpunit:explain --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PsyshMonitorCommand (psysh:monitor)
test_session_sync "psysh:monitor help" \
    --step "psysh:monitor --help" \
    --expect "Usage:" \
    --context monitor \
    --output-check contains \
    --tag "monitor_session"

# Test TabCommand (tab)
test_session_sync "tab command help" \
    --step "tab --help" \
    --expect "Usage:" \
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test TestParamsCommand (test:params)
test_session_sync "test:params help" \
    --step "test:params --help" \
    --expect "Usage:" \
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test combined runner operations
test_session_sync "Combined runner operations" \
    --step "phpunit:run --dry-run; phpunit:debug --list-tests" \
    --expect "dry-run" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"


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
