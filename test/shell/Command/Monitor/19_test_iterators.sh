#!/bin/bash

# Test 19: Iterators
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 19: Iterators"

# Étape 1: Iterator simple
'$arr = [1, 2, 3]; $it = new ArrayIterator($arr); $it->rewind(); echo $it->current()' \
test_session_sync "ArrayIterator" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'1'

# Étape 2: Foreach avec iterator
'$data = ["a" => 1, "b" => 2, "c" => 3];
test_session_sync "Foreach avec iterator" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
$it = new ArrayIterator($data);
$result = [];
foreach ($it as $key => $value) {
    $result[] = "$key=$value";
}
echo implode(", ", $result);' \
'a=1, b=2, c=3'

# Étape 3: Iterator SPL
'$it = new ArrayIterator(["file1.txt", "file2.txt"]); echo count(iterator_to_array($it))' \
test_session_sync "Iterator SPL" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'2'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
