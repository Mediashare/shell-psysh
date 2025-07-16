#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 24: Synchronisation bidirectionnelle et cas avancés"

# === TESTS DE SYNCHRONISATION BIDIRECTIONNELLE ===

# Étape 1: Variables globales persistantes
test_session_sync "Variables globales persistantes" \
'$GLOBALS["test_var"] = "persistent_value";' \
'echo $GLOBALS["test_var"];' \
'persistent_value'

# Étape 2: Modifications dans monitor affectent le shell
test_session_sync "Modification dans monitor -> shell" \
'$shared_counter = 100; $shared_counter += 50;' \
'echo $shared_counter;' \
'150'

# Étape 3: Variables de shell accessibles dans monitor
test_session_sync "Variables shell -> monitor" \
'$shell_var = "from_shell";' \
'echo $shell_var;' \
'from_shell'

# Étape 4: Synchronisation complexe avec objets
test_session_sync "Synchronisation avec objets" \
'$obj = new stdClass(); $obj->value = 42;' \
'$obj->value *= 2; echo $obj->value;' \
'84'

# === TESTS D'ERREURS AVANCÉES ===

# Étape 5: Erreur de parsing complexe
test_session_sync "Erreur parsing complexe" \
'function broken() { if ($x { echo "broken"; }' \
'(Parse error|syntax error|Error:.*syntax)'

# Étape 6: Erreur de type avec opérateur
test_session_sync "Erreur de type" \
'"string" + []' \
'(Unsupported operand types|Error:.*operand|TypeError)'

# Étape 7: Erreur mémoire simulée (array très grand)
test_session_sync "Test grande allocation" \
'$big = range(1, 10000); echo count($big);' \
'10000'

# Étape 8: Erreur de récursion infinie
test_session_sync "Récursion infinie" \
'function infinite() { return infinite(); } infinite()' \
'(Maximum function nesting level|recursion|infinite loop|stack depth)'

# === TESTS DE CAS LIMITES ===

# Étape 9: Chaînes avec caractères spéciaux
test_session_sync "Caractères spéciaux" \
'echo "Héllo Wørld! 🌍 ";' \
'Héllo Wørld! 🌍'

# Étape 10: Nombres à virgule flottante extrêmes
test_session_sync "Float extrême" \
'echo 1.7976931348623157E+308' \
'1.7976931348623E+308'

# Étape 11: Array multidimensionnel complexe
test_session_sync "Array multidimensionnel" \
'$matrix = [
    [1, 2, [3, 4]],
    ["a" => "b", "c" => ["d", "e"]],
    [null, true, false]
];
echo count($matrix) . "x" . count($matrix[0]);' \
'3x3'

# Étape 12: Closure avec capture multiple
test_session_sync "Closure capture complexe" \
'$x = 10; $y = 20; $z = 30;
$fn = function($a) use ($x, &$y, $z) {
    $y += $a + $x + $z;
    return $y;
};
echo $fn(5);' \
'65'

# === TESTS DE PERFORMANCE ET LIMITES ===

# Étape 13: Performance - grande boucle
test_session_sync "Grande boucle" \
'$sum = 0; for($i = 0; $i < 50000; $i++) { $sum += $i; } echo ($sum > 1000000 ? "true" : "false")' \
'3'

# Étape 14: Performance - manipulation string intensive
test_session_sync "String manipulation intensive" \
'$str = ""; for($i = 0; $i < 1000; $i++) { $str .= "x"; } echo strlen($str)' \
'2'

# === TESTS D'INTÉGRATION PSYSH ===

# Étape 15: Test avec commandes PsySH natives
test_session_sync "Intégration PsySH" \
'$reflection = new ReflectionClass("stdClass");
echo "Class: " . $reflection->getName();' \
'Class: stdClass'

# Étape 16: Test avec évaluation dynamique
test_session_sync "Évaluation dynamique" \
'echo eval("return 2 + 3;")' \
'5'

# === TESTS DE GESTION D'ÉTAT ===

# Étape 17: État persistant entre multiples monitors
test_session_sync "État persistant multi-monitor" \
'if (!isset($persistent_state)) { $persistent_state = []; } $persistent_state["count"] = 1;' \
'echo ++$persistent_state["count"];' \
'2'

# Étape 18: Nettoyage et isolation
test_session_sync "Isolation des variables" \
'unset($global_var, $shared_counter, $shell_var); echo "cleaned"' \
'cleaned'

# === TESTS DE ROBUSTESSE ===

# Étape 19: Caractères de contrôle dans le code
test_session_sync "Caractères de contrôle" \
'echo "\x00\x01\x02"' \
'(null byte|control character|invalid|[^[:print:]])'

# Étape 20: Test avec timeout implicite
test_session_sync "Timeout implicite" \
'sleep(1); echo "done"' \
'5'

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
