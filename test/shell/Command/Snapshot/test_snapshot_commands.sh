#!/bin/bash

# Test script for Snapshot commands
# Tests PHPUnitSnapshotCommand, PHPUnitSaveSnapshotCommand

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Snapshot Commands"
echo ""

# Test PHPUnitSnapshotCommand (phpunit:snapshot)
    --step "phpunit:snapshot --help" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:snapshot help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "Usage:" \
    --output-check contains

# Test PHPUnitSaveSnapshotCommand (phpunit:save-snapshot)
    --step "phpunit:save-snapshot --help" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:save-snapshot help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "Usage:" \
    --output-check contains

# Test snapshot creation with basic data
    --step "phpunit:save-snapshot --name='test_snapshot' --data='test data'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Create snapshot with basic data" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "Snapshot saved" \
    --output-check contains

# Test snapshot listing
    --step "phpunit:snapshot --list" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "List snapshots" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "snapshots" \
    --output-check contains

# Test snapshot comparison
    --step "phpunit:snapshot --compare='snapshot1,snapshot2'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Compare snapshots" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "comparison" \
    --output-check contains

# Test snapshot with array data
    --step "phpunit:save-snapshot --name='array_snapshot' --data='[1,2,3,4,5]'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Create snapshot with array data" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "Snapshot saved" \
    --output-check contains

# Test snapshot with object data
    --step "phpunit:save-snapshot --name='object_snapshot' --data='new stdClass()'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Create snapshot with object data" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "Snapshot saved" \
    --output-check contains

# Test snapshot restore
    --step "phpunit:snapshot --restore='test_snapshot'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Restore snapshot" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "restored" \
    --output-check contains

# Test snapshot deletion
    --step "phpunit:snapshot --delete='test_snapshot'" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Delete snapshot" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "deleted" \
    --output-check contains

# Test combined snapshot operations
    --step "phpunit:save-snapshot --name='combined_test' --data='test'; phpunit:snapshot --list" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Combined snapshot operations" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "Snapshot saved" \
    --output-check contains

test_summary
