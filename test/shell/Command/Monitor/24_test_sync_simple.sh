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

# Test 1: Fonction simple (même tag pour partager le scope)
test_session_sync "Fonction Shell -> Monitor (devrait marcher)" \
    --step 'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); }' \
    --context psysh \
    --psysh \
    --tag "function_session" \
    --expect "120" \
    --output-check result \
    --step 'echo factorial(5);' \
    --context psysh \
    --psysh \
    --tag "function_session" \
    --expect "120" \
    --output-check exact

# Test 2: Variable (même tag)
test_session_sync "Variable Shell -> Monitor" \
    --step 'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); }' \
    --context psysh \
    --psysh \
    --tag "variable_session" \
    --expect "120" \
    --output-check result \
    --step '$result = factorial(5);' \
    --context psysh \
    --psysh \
    --tag "variable_session" \
    --expect "120" \
    --output-check result \
    --step 'echo "Résultat: $result";' \
    --context psysh \
    --psysh \
    --tag "variable_session" \
    --expect "Résultat: 120" \
    --output-check exact

# Test 3: Classe (même tag)
test_session_sync "Classe Shell -> Monitor" \
    --step 'class Calculator { public function add($a, $b) { return $a + $b; } }' \
    --context psysh \
    --psysh \
    --tag "class_session" \
    --expect "40" \
    --output-check result \
    --step '$calc = new Calculator(); $result = $calc->add(15, 25);' \
    --context psysh \
    --psysh \
    --tag "class_session" \
    --expect "40" \
    --output-check result \
    --step 'echo "Résultat: $result";' \
    --context psysh \
    --psysh \
    --tag "class_session" \
    --expect "Résultat: 40" \
    --output-check exact

# Test 4: Variable globale (même tag)
test_session_sync "Variable globale" \
    --step '$GLOBALS["config"] = ["version" => "1.0"];' \
    --context psysh \
    --psysh \
    --tag "global_session" \
    --expect "1.0" \
    --output-check result \
    --step '$version = $GLOBALS["config"]["version"];' \
    --context psysh \
    --psysh \
    --tag "global_session" \
    --expect "1.0" \
    --output-check result \
    --step 'echo "Version: $version";' \
    --context psysh \
    --psysh \
    --tag "global_session" \
    --expect "Version: 1.0" \
    --output-check exact

# Afficher le résumé
test_summary

echo ""
print_colored "$BLUE" "=== RÉSUMÉ DES TESTS RAPIDES ==="
print_colored "$GREEN" "✅ Test 1: Fonction Shell -> Monitor (même tag)"
print_colored "$GREEN" "✅ Test 2: Variable Shell -> Monitor (même tag)"
print_colored "$GREEN" "✅ Test 3: Classe Shell -> Monitor (même tag)"
print_colored "$GREEN" "✅ Test 4: Variable globale (même tag)"
echo ""

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    print_colored "$RED" "❌ $FAIL_COUNT tests ont échoué"
    exit 1
else
    print_colored "$GREEN" "✅ Tous les tests ont réussi"
    exit 0
fi
