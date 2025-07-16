#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 17: Générateurs"

# Étape 1: Générateur simple
test_session_sync "Générateur nombres" \
'function numbers($max) {
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
test_session_sync "Générateur Fibonacci" \
'function fibonacci($max) { $a = 0; $b = 1; while ($a < $max) { yield $a; $temp = $a + $b; $a = $b; $b = $temp; } } $fib = fibonacci(10); echo iterator_to_array($fib)[2]' \
'1'

# Étape 3: Générateur avec clés
test_session_sync "Générateur avec clés" \
'function keyValue() {
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

# Nettoyer l'environnement de test
cleanup_test_environment

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
