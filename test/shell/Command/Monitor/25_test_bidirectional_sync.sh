#!/bin/bash

# Test 25: Tests de synchronisation bidirectionnelle approfondie
# Focus sur la persistance des données entre monitor et shell PsySH

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 25: Synchronisation bidirectionnelle approfondie"

# === TESTS FONDAMENTAUX DE SYNCHRONISATION ===

# Étape 1: Variable simple monitor -> shell
'$sync_test = "from_monitor";' \
test_session_sync "Variable monitor -> shell" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context shell \
    --output-check contains \
    --shell \
    --tag "shell_session"
'echo $sync_test' \
'from_monitor'

# Étape 2: Variable shell -> monitor
'$shell_var = "from_shell";' \
test_session_sync "Variable shell -> monitor" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context shell \
    --output-check contains \
    --shell \
    --tag "shell_session"
'echo $shell_var' \
'from_shell'

# Étape 3: Modification bidirectionnelle
'$counter = 10;' \
test_session_sync "Modification bidirectionnelle" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'$counter += 5; echo $counter' \
'15'

# === TESTS AVEC TYPES COMPLEXES ===

# Étape 4: Arrays persistants
'$shared_array = [1, 2, 3];' \
test_session_sync "Arrays persistants" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'$shared_array[] = 4; echo count($shared_array)' \
'4'

# Étape 5: Objets persistants
'$obj = new stdClass(); $obj->prop = "initial";' \
test_session_sync "Objets persistants" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'$obj->prop = "modified"; echo $obj->prop' \
'modified'

# Étape 6: Closures et fonctions
'function persistent_func($x) { return $x * 2; }' \
test_session_sync "Fonctions persistantes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'echo persistent_func(21)' \
'42'

# === TESTS DE PORTÉE ET ISOLATION ===

# Étape 7: Variables globales vs locales
'$GLOBALS["global_var"] = "global_value";' \
test_session_sync "Variables globales" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'echo $GLOBALS["global_var"]' \
'global_value'

# Étape 8: Superglobales
'$_SESSION["test"] = "session_value";' \
test_session_sync "Superglobales personnalisées" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'echo $_SESSION["test"]' \
'session_value'

# === TESTS DE PERSISTANCE AVANCÉE ===

# Étape 9: État entre plusieurs monitors consécutifs
'if (!isset($state)) { $state = 0; } $state++;' \
test_session_sync "État multi-monitor" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"
'echo ++$state' \
'2'

# Étape 10: Accumulation de données
'if (!isset($accumulator)) { $accumulator = []; } $accumulator[] = "first";' \
test_session_sync "Accumulation de données" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'$accumulator[] = "second"; echo implode(",", $accumulator)' \
'first,second'

# === TESTS DE CAS LIMITES ===

# Étape 11: Variables avec noms spéciaux
'$_special_var = "special";' \
test_session_sync "Variables noms spéciaux" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'echo $_special_var' \
'special'

# Étape 12: Références et pointeurs
'$a = 5; $b = &$a; $b = 10;' \
test_session_sync "Références PHP" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'echo $a' \
'10'

# === TESTS DE NETTOYAGE ET ISOLATION ===

# Étape 13: Suppression de variables
'$temp_var = "temporary";' \
test_session_sync "Suppression de variables" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'unset($temp_var); echo isset($temp_var) ? "exists" : "deleted"' \
'deleted'

# Étape 14: Isolation des espaces de noms
'namespace TestSpace {
test_session_sync "Espaces de noms" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    function test() {
        return "namespaced";
    }
}
namespace {
    echo \TestSpace\test();
}' \
'namespaced'

# === TESTS DE ROBUSTESSE ===

# Étape 15: Variables avec caractères Unicode
'$emoji1 = "🚀"; $emoji2 = "test";' \
test_session_sync "Variables Unicode" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'echo $emoji1 . $emoji2' \
'🚀test'

# Étape 16: Variables avec contenu binaire
'$binary = pack("H*", "48656c6c6f");' \
test_session_sync "Contenu binaire" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'echo $binary' \
'Hello'

# === TESTS DE PERFORMANCE ET LIMITES ===

# Étape 17: Grande quantité de variables
'for ($i = 0; $i < 100; $i++) { ${"var_$i"} = $i; } echo $var_99' \
test_session_sync "Nombreuses variables" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'2'

# Étape 18: Variables avec contenu volumineux
'$large_string = str_repeat("x", 10000); strlen($large_string)' \
test_session_sync "Variables volumineuses" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'3'

# === TESTS DE SYNCHRONISATION TEMPS RÉEL ===

# Étape 19: Modifications simultanées
'$shared = 1;' \
test_session_sync "Modifications simultanées" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'$shared *= 2; $shared += 3; echo $shared' \
'5'

# Étape 20: État complexe persistant
'class StateManager {
test_session_sync "État complexe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    public static $data = [];
    public static function add($key, $val) {
        self::$data[$key] = $val;
    }
}
StateManager::add("key1", "value1");
StateManager::add("key2", "value2");
echo implode(",", StateManager::$data);' \
'value1,value2'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
