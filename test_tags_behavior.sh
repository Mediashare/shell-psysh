#!/bin/bash

# Test pour vérifier le comportement des tags dans test_session_sync

# Charger les bibliothèques nécessaires
source "./test/shell/lib/func/loader.sh"
source "./test/shell/lib/func/test_session_sync_enhanced.sh"

init_test "Test comportement des tags"

# Test 1: Utilisation de tags différents (devrait échouer)
echo "=== Test 1: Tags différents (devrait échouer) ==="
test_session_sync "Test avec tags différents" \
    --step '$globalVar = "test_value"' --context psysh --psysh --tag "sync_session" --expect "test_value" --output-check result \
    --step 'echo $globalVar' --context psysh --psysh --tag "other_session" --expect 'test_value' --output-check exact

echo ""

# Test 2: Utilisation du même tag (devrait réussir)
echo "=== Test 2: Même tag (devrait réussir) ==="
test_session_sync "Test avec même tag" \
    --step '$globalVar = "test_value"' --context psysh --psysh --tag "same_session" --expect "test_value" --output-check result \
    --step 'echo $globalVar' --context psysh --psysh --tag "same_session" --expect 'test_value' --output-check exact

echo ""

# Test 3: Test de synchronisation réelle entre psysh et phpunit
echo "=== Test 3: Synchronisation psysh -> phpunit (même tag) ==="
test_session_sync "Test synchronisation même tag" \
    --step '$globalVar = "test_value"' --context psysh --psysh --tag "shared_session" --expect "test_value" --output-check result \
    --step 'phpunit:create SyncTest' --context phpunit --tag "shared_session" --expect "✅ Test créé :" --output-check contains \
    --step 'echo $globalVar' --context phpunit --tag "shared_session" --expect 'test_value' --output-check exact

test_summary
