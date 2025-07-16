#!/bin/bash

# Test 17: Générateurs
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 17: Générateurs"

# Étape 1: Générateur simple
'function numbers($max) {
test_session_sync "Générateur nombres" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    for ($i = 1; $i <= $max; $i++) {
        yield $i;
    }
}
$gen = numbers(3);
$result = [];
foreach ($gen as $num) {
    $result[] = $num;
}
echo implode(", ", $result);' \
'1, 2, 3'

# Étape 2: Générateur Fibonacci
'function fibonacci($max) { $a = 0; $b = 1; while ($a < $max) { yield $a; $temp = $a + $b; $a = $b; $b = $temp; } } $fib = fibonacci(10); echo iterator_to_array($fib)[2]' \
test_session_sync "Générateur Fibonacci" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'1'

# Étape 3: Générateur avec clés
'function keyValue() {
test_session_sync "Générateur avec clés" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    yield "first" => 1;
    yield "second" => 2;
    yield "third" => 3;
}
$result = [];
foreach (keyValue() as $key => $value) {
    $result[] = "$key=$value";
}
echo implode(", ", $result);' \
'first=1, second=2, third=3'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
