#!/bin/bash

# Test 12: Simulation traitement d'images
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/psysh_utils.sh"

# Initialiser le test
init_test "TEST 12: Simulation traitement d'images"

# Étape 1: Création matrice de pixels
test_monitor_expression "Création matrice 100x100" \
'$pixels = array_fill(0, 100, array_fill(0, 100, 0)); echo count($pixels) * count($pixels[0])' \
'10000'

# Étape 2: Simulation de filtre
test_monitor_multiline "Application filtre blur" \
'$image = array_fill(0, 10, array_fill(0, 10, 255));
$filtered = array_map(function($row) {
    return array_map(function($pixel) {
        return intval($pixel * 0.8);
    }, $row);
}, $image);
echo "Filtre appliqué sur " . count($filtered) . "x" . count($filtered[0]) . " pixels";' \
'Filtre appliqué sur 10x10 pixels'

# Étape 3: Test performance traitement
test_monitor_performance "Performance traitement pixels" \
'$size = 50; $matrix = array_fill(0, $size, array_fill(0, $size, rand(0, 255))); echo count(array_map("array_sum", $matrix))' \
'2'

# Étape 4: Calcul histogramme
test_monitor_expression "Calcul histogramme" \
'$data = [255, 128, 64, 255, 128]; $hist = array_count_values($data); echo count($hist)' \
'3'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
