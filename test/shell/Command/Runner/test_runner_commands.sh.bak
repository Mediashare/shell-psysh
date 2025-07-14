#!/bin/bash

# Test script for Runner commands
# Tests PHPUnitRunCommand, PHPUnitDebugCommand, PHPUnitMonitorCommand, etc.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/test_utils.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Runner Commands"
echo ""

# Test PHPUnitRunCommand (phpunit:run)
run_test_step "phpunit:run basic execution" \
    "../bin/psysh -c \"phpunit:run --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitRunAllCommand (phpunit:run-all)
run_test_step "phpunit:run-all help" \
    "../bin/psysh -c \"phpunit:run-all --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitRunProjectCommand (phpunit:run-project)
run_test_step "phpunit:run-project help" \
    "../bin/psysh -c \"phpunit:run-project --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitDebugCommand (phpunit:debug)
run_test_step "phpunit:debug help" \
    "../bin/psysh -c \"phpunit:debug --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitMonitorCommand (phpunit:monitor)
run_test_step "phpunit:monitor help" \
    "../bin/psysh -c \"phpunit:monitor --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitProfileCommand (phpunit:profile)
run_test_step "phpunit:profile help" \
    "../bin/psysh -c \"phpunit:profile --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitTraceCommand (phpunit:trace)
run_test_step "phpunit:trace help" \
    "../bin/psysh -c \"phpunit:trace --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitWatchCommand (phpunit:watch)
run_test_step "phpunit:watch help" \
    "../bin/psysh -c \"phpunit:watch --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitExplainCommand (phpunit:explain)
run_test_step "phpunit:explain help" \
    "../bin/psysh -c \"phpunit:explain --help\"" \
    "Usage:" \
    "check_contains"

# Test PsyshMonitorCommand (psysh:monitor)
run_test_step "psysh:monitor help" \
    "../bin/psysh -c \"psysh:monitor --help\"" \
    "Usage:" \
    "check_contains"

# Test TabCommand (tab)
run_test_step "tab command help" \
    "../bin/psysh -c \"tab --help\"" \
    "Usage:" \
    "check_contains"

# Test TestParamsCommand (test:params)
run_test_step "test:params help" \
    "../bin/psysh -c \"test:params --help\"" \
    "Usage:" \
    "check_contains"

# Test combined runner operations
run_test_step "Combined runner operations" \
    "../bin/psysh -c \"phpunit:run --dry-run; phpunit:debug --list-tests\"" \
    "dry-run" \
    "check_contains"

test_summary
