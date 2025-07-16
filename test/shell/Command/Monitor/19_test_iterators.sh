#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 19: Iterators"

# Étape 1: Iterator simple
test_session_sync "ArrayIterator" \
'$arr = [1, 2, 3]; $it = new ArrayIterator($arr); $it->rewind(); echo $it->current()' \
'1'

# Étape 2: Foreach avec iterator
test_session_sync "Foreach avec iterator" \
'$data = ["a" => 1, "b" => 2, "c" => 3];
$it = new ArrayIterator($data);
$result = [];
foreach ($it as $key => $value) {
    $result[] = "$key=$value";
}
echo implode(", ", $result);' \
'a=1, b=2, c=3'

# Étape 3: Iterator SPL
test_session_sync "Iterator SPL" \
'$it = new ArrayIterator(["file1.txt", "file2.txt"]); echo count(iterator_to_array($it))' \
'2'

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
