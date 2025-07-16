#!/bin/bash

# Test 35: Synchronisation Shell/PHPUnit - Tests avancés de synchronisation
# Tests complets de synchronisation entre les shells PsySH et les commandes phpunit:*

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 35: Synchronisation Shell/PHPUnit"

# Étape 1: Test synchronisation basique - variables (même tag pour partager le scope)
test_session_sync "Synchronisation variable simple" \
    --step '$globalVar = "test_value"' --context psysh --psysh --tag "sync_session" --expect "test_value" --output-check result \
    --step 'phpunit:create SyncTest' --context phpunit --tag "sync_session" --expect "✅ Test créé :" --output-check contains \
    --step 'echo $globalVar' --context phpunit --tag "sync_session" --expect 'test_value' --output-check exact

# Étape 2: Test synchronisation avec phpunit:code (même tag)
test_session_sync "Synchronisation via phpunit:code" \
    --step 'phpunit:create CodeSyncTest' --context phpunit --tag "code_sync_session" --expect "✅ Test créé :" --output-check contains \
    --step 'phpunit:code --snippet "$codeVar = 123;"' --context phpunit --tag "code_sync_session" --expect "Code ajouté" --output-check contains \
    --step 'echo $codeVar' --context phpunit --tag "code_sync_session" --expect "123" --output-check exact

# Étape 3: Test synchronisation objet complexe (même tag)
test_session_sync "Synchronisation objet" \
    --step '$user = new stdClass(); $user->name = "John"; $user->age = 30' --context psysh --psysh --tag "object_sync_session" --expect "John" --output-check result \
    --step 'phpunit:create ObjectSyncTest' --context phpunit --tag "object_sync_session" --expect "✅ Test créé :" --output-check contains \
    --step 'echo $user->name' --context phpunit --tag "object_sync_session" --expect "John" --output-check exact

# Étape 4: Test synchronisation array (même tag)
test_session_sync "Synchronisation array" \
    --step '$testArray = [1, 2, 3, "test"]' --context psysh --psysh --tag "array_sync_session" --expect "4" --output-check result \
    --step 'phpunit:create ArraySyncTest' --context phpunit --tag "array_sync_session" --expect "✅ Test créé :" --output-check contains \
    --step 'echo count($testArray)' --context phpunit --tag "array_sync_session" --expect "4" --output-check exact

# Étape 5: Test synchronisation fonction (même tag)
test_session_sync "Synchronisation fonction" \
    --step 'function testFunction($param) { return $param * 2; }' --context psysh --psysh --tag "function_sync_session" --expect "10" --output-check result \
    --step 'phpunit:create FunctionSyncTest' --context phpunit --tag "function_sync_session" --expect "✅ Test créé :" --output-check contains \
    --step 'echo testFunction(5)' --context phpunit --tag "function_sync_session" --expect "10" --output-check exact

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
