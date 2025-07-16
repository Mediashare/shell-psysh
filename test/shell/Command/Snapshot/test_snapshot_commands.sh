#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "Snapshot Commands"
echo ""

# Test PHPUnitSnapshotCommand (phpunit:snapshot)
test_session_sync "phpunit:snapshot help" \
    "test_session_sync "Test command" --step \"phpunit:snapshot --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitSaveSnapshotCommand (phpunit:save-snapshot)
test_session_sync "phpunit:save-snapshot help" \
    "test_session_sync "Test command" --step \"phpunit:save-snapshot --help\"" \
    "Usage:" \
    "check_contains"

# Test snapshot creation with basic data
test_session_sync "Create snapshot with basic data" \
    "test_session_sync "Test command" --step \"phpunit:save-snapshot --name='test_snapshot' --data='test data'\"" \
    "Snapshot saved" \
    "check_contains"

# Test snapshot listing
test_session_sync "List snapshots" \
    "test_session_sync "Test command" --step \"phpunit:snapshot --list\"" \
    "snapshots" \
    "check_contains"

# Test snapshot comparison
test_session_sync "Compare snapshots" \
    "test_session_sync "Test command" --step \"phpunit:snapshot --compare='snapshot1,snapshot2'\"" \
    "comparison" \
    "check_contains"

# Test snapshot with array data
test_session_sync "Create snapshot with array data" \
    "test_session_sync "Test command" --step \"phpunit:save-snapshot --name='array_snapshot' --data='[1,2,3,4,5]'\"" \
    "Snapshot saved" \
    "check_contains"

# Test snapshot with object data
test_session_sync "Create snapshot with object data" \
    "test_session_sync "Test command" --step \"phpunit:save-snapshot --name='object_snapshot' --data='new stdClass()'\"" \
    "Snapshot saved" \
    "check_contains"

# Test snapshot restore
test_session_sync "Restore snapshot" \
    "test_session_sync "Test command" --step \"phpunit:snapshot --restore='test_snapshot'\"" \
    "restored" \
    "check_contains"

# Test snapshot deletion
test_session_sync "Delete snapshot" \
    "test_session_sync "Test command" --step \"phpunit:snapshot --delete='test_snapshot'\"" \
    "deleted" \
    "check_contains"

# Test combined snapshot operations
test_session_sync "Combined snapshot operations" \
    "test_session_sync "Test command" --step \"phpunit:save-snapshot --name='combined_test' --data='test'; phpunit:snapshot --list\"" \
    "Snapshot saved" \
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
