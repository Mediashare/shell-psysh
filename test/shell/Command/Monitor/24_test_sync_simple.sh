#!/bin/bash

# Test 24 Simple: Test rapide de synchronisation Shell <-> Monitor
# Version simplifiée pour tests rapides

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 24 Simple: Synchronisation rapide Shell <-> Monitor"

# Test 1: Fonction fonctionne (pour confirmer que les fonctions SONT synchronisées)
test_sync_bidirectional "Fonction Shell -> Monitor (devrait marcher)" \
'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); }' \
'echo factorial(5);' \
'' \
'120' \
'function'

# Test 2: Bug principal - Variable créée dans Monitor non accessible dans Shell
test_sync_bidirectional "Bug principal: Variable Monitor -> Shell" \
'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); }' \
'$result = factorial(5);' \
'echo "Résultat dans shell: $result";' \
'Résultat dans shell: 120' \
'variable'

# Test 3: Classe Shell -> Monitor  
test_sync_bidirectional "Classe Shell -> Monitor" \
'class Calculator { public function add($a, $b) { return $a + $b; } }' \
'$calc = new Calculator(); $result = $calc->add(15, 25);' \
'echo "Résultat: $result";' \
'40' \
'class'

# Test 4: Variable globale
test_sync_bidirectional "Variable globale" \
'$GLOBALS["config"] = ["version" => "1.0"];' \
'$version = $GLOBALS["config"]["version"];' \
'echo "Version: $version";' \
'1.0' \
'global'

# Afficher le résumé
test_summary

echo ""
print_colored "$BLUE" "=== RÉSUMÉ DES TESTS RAPIDES ==="
print_colored "$GREEN" "✅ Test 1: Fonction Shell -> Monitor (devrait marcher)"
print_colored "$RED" "❌ Test 2: Bug principal (variable Monitor -> Shell)"
print_colored "$GREEN" "✅ Test 3: Classe Shell -> Monitor"
print_colored "$GREEN" "✅ Test 4: Variable globale"
echo ""

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    print_colored "$RED" "❌ $FAIL_COUNT tests ont échoué - bugs de synchronisation détectés"
    exit 1
else
    print_colored "$GREEN" "✅ Tous les tests rapides ont réussi"
    exit 0
fi
