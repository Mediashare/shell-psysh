#!/bin/bash

# Test 09: Utilisation mémoire
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 09: Utilisation mémoire"

# Étape 1: Test allocation simple d'array
'$arr = range(1, 100); echo count($arr);' \
test_session_sync "Array simple" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'100'

# Étape 2: Test allocation progressive
'$arr = [];
test_session_sync "Allocation progressive" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
for($i = 0; $i < 1000; $i++) {
    $arr[] = $i;
}
echo count($arr);' \
'1000'

# Étape 3: Test allocation de chaînes
'$strings = [];
test_session_sync "Allocation chaînes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
for($i = 0; $i < 500; $i++) {
    $strings[] = str_repeat("x", 10);
}
echo count($strings);' \
'500'

# Étape 4: Test libération mémoire avec unset
'$big_array = range(1, 5000);
test_session_sync "Libération mémoire" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
$size_before = count($big_array);
unset($big_array);
$big_array = [];
echo $size_before;' \
'5000'

# Étape 5: Test avec objets
'class SimpleObject {
test_session_sync "Allocation objets" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    public $data;
    public function __construct($value) {
        $this->data = $value;
    }
}
$objects = [];
for($i = 0; $i < 100; $i++) {
    $objects[] = new SimpleObject($i);
}
echo count($objects);' \
'100'

# Étape 6: Test mémoire avec array multidimensionnel
'$matrix = [];
test_session_sync "Array multidimensionnel" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
for($i = 0; $i < 10; $i++) {
    $matrix[$i] = [];
    for($j = 0; $j < 10; $j++) {
        $matrix[$i][$j] = $i * $j;
    }
}
echo count($matrix) * count($matrix[0]);' \
'100'

# Étape 7: Test performance avec gros volume (max 10 secondes)
'$arr = []; for($i = 0; $i < 50000; $i++) { $arr[] = $i; } echo count($arr);' \
test_session_sync "Gros volume mémoire" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
10

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
