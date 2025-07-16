#!/bin/bash

# Test 12: Simulation traitement d'images
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 12: Simulation traitement d'images"

# Étape 1: Création matrice de pixels
'$pixels = array_fill(0, 100, array_fill(0, 100, 0)); echo count($pixels) * count($pixels[0])' \
test_session_sync "Création matrice 100x100" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'10000'

# Étape 2: Simulation de filtre
'$image = array_fill(0, 10, array_fill(0, 10, 255));
test_session_sync "Application filtre blur" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
$filtered = array_map(function($row) {
    return array_map(function($pixel) {
        return intval($pixel * 0.8);
    }, $row);
}, $image);
echo "Filtre appliqué sur " . count($filtered) . "x" . count($filtered[0]) . " pixels";' \
'Filtre appliqué sur 10x10 pixels'

# Étape 3: Test performance traitement
'$size = 50; $matrix = array_fill(0, $size, array_fill(0, $size, rand(0, 255))); echo count(array_map("array_sum", $matrix))' \
test_session_sync "Performance traitement pixels" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'2'

# Étape 4: Calcul histogramme
'$data = [255, 128, 64, 255, 128]; $hist = array_count_values($data); echo count($hist)' \
test_session_sync "Calcul histogramme" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'3'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
