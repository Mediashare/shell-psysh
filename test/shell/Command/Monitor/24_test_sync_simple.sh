#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 24 Simple: Synchronisation rapide Shell <-> Monitor"

# Test 1: Fonction fonctionne (pour confirmer que les fonctions SONT synchronisées)
test_session_sync "Fonction Shell -> Monitor (devrait marcher)" \
'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); }' \
'echo factorial(5);' \
'' \
'120' \
'function'

# Test 2: Bug principal - Variable créée dans Monitor non accessible dans Shell
test_session_sync "Bug principal: Variable Monitor -> Shell" \
'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); }' \
'$result = factorial(5);' \
'echo "Résultat dans shell: $result";' \
'Résultat dans shell: 120' \
'variable'

# Test 3: Classe Shell -> Monitor  
test_session_sync "Classe Shell -> Monitor" \
'class Calculator { public function add($a, $b) { return $a + $b; } }' \
'$calc = new Calculator(); $result = $calc->add(15, 25);' \
'echo "Résultat: $result";' \
'40' \
'class'

# Test 4: Variable globale
test_session_sync "Variable globale" \
'$GLOBALS["config"] = ["version" => "1.0"];' \
'$version = $GLOBALS["config"]["version"];' \
'echo "Version: $version";' \
'1.0' \
'global'

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
