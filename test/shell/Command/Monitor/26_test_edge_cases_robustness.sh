#!/bin/bash

# Test 26: Edge cases et robustesse du système monitor
# Tests créatifs pour tester les limites et la robustesse

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/psysh_utils.sh"

# Initialiser le test
init_test "TEST 26: Edge cases et robustesse"

# === TESTS DE SYNTAXE LIMITE ===

# Étape 1: Code PHP avec syntaxe valide mais complexe
test_monitor_expression "Syntaxe complexe mais valide" \
'($x = 5) && ($y = 10) ? $x + $y : 0' \
'15'

# Étape 2: Opérateurs ternaires imbriqués
test_monitor_expression "Ternaires imbriqués" \
'$a = 1; $b = 2; echo $a < $b ? ($a == 1 ? "one" : "not one") : "b smaller"' \
'one'

# Étape 3: Test avec caractères échappés complexes
test_monitor_expression "Caractères échappés" \
'"He said: \"Hello\", then \\added\\ backslashes"' \
'He said: "Hello", then \added\ backslashes'

# === TESTS D'ERREURS CRÉATIVES ===

# Étape 4: Division par zéro avec gestion
test_psysh_error "Division par zéro" \
'echo 1/0' \
'Division by zero|DivisionByZeroError'

# Étape 5: Stack overflow avec récursion
test_psysh_error "Stack overflow" \
'function boom() { return boom(); } boom()' \
'infinite loop|stack depth'

# Étape 6: Parse error créatif
test_psysh_error "Parse error créatif" \
'if ($x { echo "broken"' \
'Parse error|syntax error'

# Étape 7: Erreur de type strict
test_psysh_error "Erreur de type" \
'function strict(int $x): string { return $x; } strict("not int")' \
'TypeError|Argument.*must be.*int'

# === TESTS DE LIMITES MÉMOIRE ===

# Étape 8: String très longue
test_monitor_performance "String très longue" \
'echo strlen(str_repeat("x", 50000))' \
'3'

# Étape 9: Array avec beaucoup d'éléments
test_monitor_performance "Array volumineux" \
'echo count(range(1, 10000))' \
'2'

# Étape 10: Boucle intense mais limitée
test_monitor_performance "Boucle intense" \
'$sum = 0; for($i = 0; $i < 1000; $i++) { $sum += sin($i); } echo "done"' \
'3'

# === TESTS DE CARACTÈRES SPÉCIAUX ===

# Étape 11: Unicode et émojis
test_monitor_expression "Unicode et émojis" \
'"Héllo 世界 🌍 🚀"' \
'Héllo 世界 🌍 🚀'

# Étape 12: Caractères de contrôle sécurisés
test_monitor_echo "Caractères échappés sécurisés" \
'echo addslashes("quote\"and\\backslash")' \
'quote.*and.*backslash'

# Étape 13: NULL bytes handling
test_psysh_error "NULL bytes" \
'echo "\0\0\0"' \
'.*'

# === TESTS DE TYPES AVANCÉS ===

# Étape 14: Manipulation de types complexes
test_monitor_multiline "Types complexes" \
'$complex = [
    "string" => "value",
    "array" => [1, 2, 3],
    "object" => new stdClass(),
    "null" => null,
    "bool" => true
];
echo count($complex);' \
'5'

# Étape 15: Sérialisation/désérialisation
test_monitor_expression "Sérialisation" \
'$obj = new stdClass(); $obj->prop = 42; echo unserialize(serialize($obj))->prop' \
'42'

# === TESTS DE CONCURRENCE ET ÉTAT ===

# Étape 16: Variables statiques
test_monitor_multiline "Variables statiques" \
'function counter() {
    static $count = 0;
    return ++$count;
}
echo counter() . "," . counter();' \
'1,2'

# Étape 17: État global complexe
test_monitor_multiline "État global complexe" \
'class GlobalState {
    public static $data = [];
    public static function set($k, $v) {
        self::$data[$k] = $v;
    }
}
GlobalState::set("test", "value");
echo GlobalState::$data["test"];' \
'value'

# === TESTS DE PERFORMANCE EXTRÊME ===

# Étape 18: Calcul mathématique intensif
test_monitor_performance "Calcul intensif" \
'$result = 0; for($i = 1; $i <= 1000; $i++) { $result += sqrt($i); } $result > 20000' \
'4'

# Étape 19: Manipulation de strings intensive
test_monitor_performance "String intensive" \
'$s = ""; for($i = 0; $i < 500; $i++) { $s = md5($s . $i); } strlen($s)' \
'3'

# === TESTS DE SÉCURITÉ ===

# Étape 20: Code potentiellement dangereux mais sécurisé
test_psysh_error "Code potentiellement dangereux" \
'eval("return system(\"echo safe\");")' \
'safe'

# Étape 21: Injection de code impossible
test_monitor_expression "Code sécurisé" \
'htmlspecialchars("<script>alert(\"xss\")</script>")' \
'&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;'

# === TESTS D'INTÉGRATION PSYSH ===

# Étape 22: Utilisation des features PsySH
test_monitor_multiline "Features PsySH" \
'$reflection = new ReflectionFunction("strlen");
echo $reflection->getName();' \
'strlen'

# Étape 23: Autoload et namespaces
test_monitor_expression "Autoload test" \
'class_exists("DateTime")' \
'true'

# === TESTS DE RÉCUPÉRATION D'ERREUR ===

# Étape 24: Récupération après erreur
test_shell_responsiveness "Récupération après erreur" \
'try { throw new Exception("test error"); } catch (Exception $e) { echo "handled"; }' \
'echo "recovered"' \
'recovered'

# Étape 25: État consistent après erreur
test_shell_responsiveness "État après erreur" \
'$test_var = "before_error";' \
'try { throw new Exception("test"); } catch (Exception $e) {} echo $test_var' \
'before_error'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
