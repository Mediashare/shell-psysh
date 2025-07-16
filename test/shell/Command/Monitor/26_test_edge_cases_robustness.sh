#!/bin/bash

# Test 26: Edge cases et robustesse du système monitor
# Tests créatifs pour tester les limites et la robustesse

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 26: Edge cases et robustesse"

# === TESTS DE SYNTAXE LIMITE ===

# Étape 1: Code PHP avec syntaxe valide mais complexe
'($x = 5) && ($y = 10) ? $x + $y : 0' \
test_session_sync "Syntaxe complexe mais valide" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'15'

# Étape 2: Opérateurs ternaires imbriqués
'$a = 1; $b = 2; echo $a < $b ? ($a == 1 ? "one" : "not one") : "b smaller"' \
test_session_sync "Ternaires imbriqués" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'one'

# Étape 3: Test avec caractères échappés complexes
'"He said: \"Hello\", then \\added\\ backslashes"' \
test_session_sync "Caractères échappés" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'He said: "Hello", then \added\ backslashes'

# === TESTS D'ERREURS CRÉATIVES ===

# Étape 4: Division par zéro avec gestion
'echo 1/0' \
test_session_sync "Division par zéro" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'Division by zero|DivisionByZeroError'

# Étape 5: Stack overflow avec récursion
'function boom() { return boom(); } boom()' \
test_session_sync "Stack overflow" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'infinite loop|stack depth'

# Étape 6: Parse error créatif
'if ($x { echo "broken"' \
test_session_sync "Parse error créatif" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'Parse error|syntax error'

# Étape 7: Erreur de type strict
'function strict(int $x): string { return $x; } strict("not int")' \
test_session_sync "Erreur de type" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'TypeError|Argument.*must be.*int'

# === TESTS DE LIMITES MÉMOIRE ===

# Étape 8: String très longue
'echo strlen(str_repeat("x", 50000))' \
test_session_sync "String très longue" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'3'

# Étape 9: Array avec beaucoup d'éléments
'echo count(range(1, 10000))' \
test_session_sync "Array volumineux" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'2'

# Étape 10: Boucle intense mais limitée
'$sum = 0; for($i = 0; $i < 1000; $i++) { $sum += sin($i); } echo "done"' \
test_session_sync "Boucle intense" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'3'

# === TESTS DE CARACTÈRES SPÉCIAUX ===

# Étape 11: Unicode et émojis
'"Héllo 世界 🌍 🚀"' \
test_session_sync "Unicode et émojis" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'Héllo 世界 🌍 🚀'

# Étape 12: Caractères de contrôle sécurisés
'echo addslashes("quote\"and\\backslash")' \
test_session_sync "Caractères échappés sécurisés" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'quote.*and.*backslash'

# Étape 13: NULL bytes handling
'echo "\0\0\0"' \
test_session_sync "NULL bytes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'.*'

# === TESTS DE TYPES AVANCÉS ===

# Étape 14: Manipulation de types complexes
'$complex = [
test_session_sync "Types complexes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "string" => "value",
    --output-check result => [1, 2, 3],
    --output-check result => new stdClass(),
    "null" => null,
    "bool" => true
];
echo count($complex);' \
'5'

# Étape 15: Sérialisation/désérialisation
'$obj = new stdClass(); $obj->prop = 42; echo unserialize(serialize($obj))->prop' \
test_session_sync "Sérialisation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'42'

# === TESTS DE CONCURRENCE ET ÉTAT ===

# Étape 16: Variables statiques
'function counter() {
test_session_sync "Variables statiques" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    static $count = 0;
    return ++$count;
}
echo counter() . "," . counter();' \
'1,2'

# Étape 17: État global complexe
'class GlobalState {
test_session_sync "État global complexe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
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
'$result = 0; for($i = 1; $i <= 1000; $i++) { $result += sqrt($i); } $result > 20000' \
test_session_sync "Calcul intensif" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'4'

# Étape 19: Manipulation de strings intensive
'$s = ""; for($i = 0; $i < 500; $i++) { $s = md5($s . $i); } strlen($s)' \
test_session_sync "String intensive" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'3'

# === TESTS DE SÉCURITÉ ===

# Étape 20: Code potentiellement dangereux mais sécurisé
'eval("return system(\"echo safe\");")' \
test_session_sync "Code potentiellement dangereux" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'safe'

# Étape 21: Injection de code impossible
'htmlspecialchars("<script>alert(\"xss\")</script>")' \
test_session_sync "Code sécurisé" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;'

# === TESTS D'INTÉGRATION PSYSH ===

# Étape 22: Utilisation des features PsySH
'$reflection = new ReflectionFunction("strlen");
test_session_sync "Features PsySH" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
echo $reflection->getName();' \
'strlen'

# Étape 23: Autoload et namespaces
'class_exists("DateTime")' \
test_session_sync "Autoload test" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'true'

# === TESTS DE RÉCUPÉRATION D'ERREUR ===

# Étape 24: Récupération après erreur
'try { throw new Exception("test error"); } catch (Exception $e) { echo "handled"; }' \
test_session_sync "Récupération après erreur" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'echo "recovered"' \
'recovered'

# Étape 25: État consistent après erreur
'$test_var = "before_error";' \
test_session_sync "État après erreur" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
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
