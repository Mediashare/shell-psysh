#!/bin/bash

# Test 24: Synchronisation bidirectionnelle et cas avancés
# Test automatisé avec gestion d'erreurs et edge cases

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 24: Synchronisation bidirectionnelle et cas avancés"

# === TESTS DE SYNCHRONISATION BIDIRECTIONNELLE ===

# Étape 1: Variables globales persistantes
'$GLOBALS["test_var"] = "persistent_value";' \
test_session_sync "Variables globales persistantes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'echo $GLOBALS["test_var"];' \
'persistent_value'

# Étape 2: Modifications dans monitor affectent le shell
'$shared_counter = 100; $shared_counter += 50;' \
test_session_sync "Modification dans monitor -> shell" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context shell \
    --output-check contains \
    --shell \
    --tag "shell_session"
'echo $shared_counter;' \
'150'

# Étape 3: Variables de shell accessibles dans monitor
'$shell_var = "from_shell";' \
test_session_sync "Variables shell -> monitor" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context shell \
    --output-check contains \
    --shell \
    --tag "shell_session"
'echo $shell_var;' \
'from_shell'

# Étape 4: Synchronisation complexe avec objets
'$obj = new stdClass(); $obj->value = 42;' \
test_session_sync "Synchronisation avec objets" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "sync_session"
'$obj->value *= 2; echo $obj->value;' \
'84'

# === TESTS D'ERREURS AVANCÉES ===

# Étape 5: Erreur de parsing complexe
'function broken() { if ($x { echo "broken"; }' \
test_session_sync "Erreur parsing complexe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(Parse error|syntax error|Error:.*syntax)'

# Étape 6: Erreur de type avec opérateur
'"string" + []' \
test_session_sync "Erreur de type" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(Unsupported operand types|Error:.*operand|TypeError)'

# Étape 7: Erreur mémoire simulée (array très grand)
'$big = range(1, 10000); echo count($big);' \
test_session_sync "Test grande allocation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'10000'

# Étape 8: Erreur de récursion infinie
'function infinite() { return infinite(); } infinite()' \
test_session_sync "Récursion infinie" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(Maximum function nesting level|recursion|infinite loop|stack depth)'

# === TESTS DE CAS LIMITES ===

# Étape 9: Chaînes avec caractères spéciaux
'echo "Héllo Wørld! 🌍 ";' \
test_session_sync "Caractères spéciaux" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'Héllo Wørld! 🌍'

# Étape 10: Nombres à virgule flottante extrêmes
'echo 1.7976931348623157E+308' \
test_session_sync "Float extrême" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'1.7976931348623E+308'

# Étape 11: Array multidimensionnel complexe
'$matrix = [
test_session_sync "Array multidimensionnel" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    [1, 2, [3, 4]],
    ["a" => "b", "c" => ["d", "e"]],
    [null, true, false]
];
echo count($matrix) . "x" . count($matrix[0]);' \
'3x3'

# Étape 12: Closure avec capture multiple
'$x = 10; $y = 20; $z = 30;
test_session_sync "Closure capture complexe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
$fn = function($a) use ($x, &$y, $z) {
    $y += $a + $x + $z;
    return $y;
};
echo $fn(5);' \
'65'

# === TESTS DE PERFORMANCE ET LIMITES ===

# Étape 13: Performance - grande boucle
'$sum = 0; for($i = 0; $i < 50000; $i++) { $sum += $i; } echo ($sum > 1000000 ? "true" : "false")' \
test_session_sync "Grande boucle" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'3'

# Étape 14: Performance - manipulation string intensive
'$str = ""; for($i = 0; $i < 1000; $i++) { $str .= "x"; } echo strlen($str)' \
test_session_sync "String manipulation intensive" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'2'

# === TESTS D'INTÉGRATION PSYSH ===

# Étape 15: Test avec commandes PsySH natives
'$reflection = new ReflectionClass("stdClass");
test_session_sync "Intégration PsySH" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
echo "Class: " . $reflection->getName();' \
'Class: stdClass'

# Étape 16: Test avec évaluation dynamique
'echo eval("return 2 + 3;")' \
test_session_sync "Évaluation dynamique" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'5'

# === TESTS DE GESTION D'ÉTAT ===

# Étape 17: État persistant entre multiples monitors
'if (!isset($persistent_state)) { $persistent_state = []; } $persistent_state["count"] = 1;' \
test_session_sync "État persistant multi-monitor" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"
'echo ++$persistent_state["count"];' \
'2'

# Étape 18: Nettoyage et isolation
'unset($global_var, $shared_counter, $shell_var); echo "cleaned"' \
test_session_sync "Isolation des variables" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'cleaned'

# === TESTS DE ROBUSTESSE ===

# Étape 19: Caractères de contrôle dans le code
'echo "\x00\x01\x02"' \
test_session_sync "Caractères de contrôle" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(null byte|control character|invalid|[^[:print:]])'

# Étape 20: Test avec timeout implicite
'sleep(1); echo "done"' \
test_session_sync "Timeout implicite" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'5'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
