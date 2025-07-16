#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "multiline complex"

init_test "TEST 10: Code multi-lignes complexe"

# Étape 1: Test avec array d'utilisateurs et calcul de moyenne
test_session_sync "Calcul âge moyen des utilisateurs" \
'$users = [
    ["name" => "Alice", "age" => 25],
    ["name" => "Bob", "age" => 30],
    ["name" => "Charlie", "age" => 35]
];

$averageAge = array_reduce($users, function($carry, $user) {
    return $carry + $user["age"];
}, 0) / count($users);

echo "Age moyen: $averageAge";' \
'Age moyen: 30'

# Étape 2: Test de filtrage complexe
test_session_sync "Filtrage et transformation" \
'$numbers = range(1, 10);
$evenSquares = array_map(function($x) {
    return $x * $x;
}, array_filter($numbers, function($x) {
    return $x % 2 == 0;
}));
echo "Carrés pairs: " . implode(", ", $evenSquares);' \
'Carrés pairs: 4, 16, 36, 64, 100'

# Étape 3: Test closure avec capture de variable
test_session_sync "Closure avec capture" \
'$multiplier = 3;
$transform = function($arr) use ($multiplier) {
    return array_map(function($x) use ($multiplier) {
        return $x * $multiplier;
    }, $arr);
};
$result = $transform([1, 2, 3]);
echo implode(", ", $result);' \
'3, 6, 9'
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
