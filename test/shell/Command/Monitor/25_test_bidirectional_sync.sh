#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 25: Synchronisation bidirectionnelle approfondie"

# === TESTS FONDAMENTAUX DE SYNCHRONISATION ===

# Étape 1: Variable simple monitor -> shell
test_session_sync "Variable monitor -> shell" \
'$sync_test = "from_monitor";' \
'echo $sync_test' \
'from_monitor'

# Étape 2: Variable shell -> monitor
test_session_sync "Variable shell -> monitor" \
'$shell_var = "from_shell";' \
'echo $shell_var' \
'from_shell'

# Étape 3: Modification bidirectionnelle
test_session_sync "Modification bidirectionnelle" \
'$counter = 10;' \
'$counter += 5; echo $counter' \
'15'

# === TESTS AVEC TYPES COMPLEXES ===

# Étape 4: Arrays persistants
test_session_sync "Arrays persistants" \
'$shared_array = [1, 2, 3];' \
'$shared_array[] = 4; echo count($shared_array)' \
'4'

# Étape 5: Objets persistants
test_session_sync "Objets persistants" \
'$obj = new stdClass(); $obj->prop = "initial";' \
'$obj->prop = "modified"; echo $obj->prop' \
'modified'

# Étape 6: Closures et fonctions
test_session_sync "Fonctions persistantes" \
'function persistent_func($x) { return $x * 2; }' \
'echo persistent_func(21)' \
'42'

# === TESTS DE PORTÉE ET ISOLATION ===

# Étape 7: Variables globales vs locales
test_session_sync "Variables globales" \
'$GLOBALS["global_var"] = "global_value";' \
'echo $GLOBALS["global_var"]' \
'global_value'

# Étape 8: Superglobales
test_session_sync "Superglobales personnalisées" \
'$_SESSION["test"] = "session_value";' \
'echo $_SESSION["test"]' \
'session_value'

# === TESTS DE PERSISTANCE AVANCÉE ===

# Étape 9: État entre plusieurs monitors consécutifs
test_session_sync "État multi-monitor" \
'if (!isset($state)) { $state = 0; } $state++;' \
'echo ++$state' \
'2'

# Étape 10: Accumulation de données
test_session_sync "Accumulation de données" \
'if (!isset($accumulator)) { $accumulator = []; } $accumulator[] = "first";' \
'$accumulator[] = "second"; echo implode(",", $accumulator)' \
'first,second'

# === TESTS DE CAS LIMITES ===

# Étape 11: Variables avec noms spéciaux
test_session_sync "Variables noms spéciaux" \
'$_special_var = "special";' \
'echo $_special_var' \
'special'

# Étape 12: Références et pointeurs
test_session_sync "Références PHP" \
'$a = 5; $b = &$a; $b = 10;' \
'echo $a' \
'10'

# === TESTS DE NETTOYAGE ET ISOLATION ===

# Étape 13: Suppression de variables
test_session_sync "Suppression de variables" \
'$temp_var = "temporary";' \
'unset($temp_var); echo isset($temp_var) ? "exists" : "deleted"' \
'deleted'

# Étape 14: Isolation des espaces de noms
test_session_sync "Espaces de noms" \
'namespace TestSpace {
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
test_session_sync "Variables Unicode" \
'$emoji1 = "🚀"; $emoji2 = "test";' \
'echo $emoji1 . $emoji2' \
'🚀test'

# Étape 16: Variables avec contenu binaire
test_session_sync "Contenu binaire" \
'$binary = pack("H*", "48656c6c6f");' \
'echo $binary' \
'Hello'

# === TESTS DE PERFORMANCE ET LIMITES ===

# Étape 17: Grande quantité de variables
test_session_sync "Nombreuses variables" \
'for ($i = 0; $i < 100; $i++) { ${"var_$i"} = $i; } echo $var_99' \
'2'

# Étape 18: Variables avec contenu volumineux
test_session_sync "Variables volumineuses" \
'$large_string = str_repeat("x", 10000); strlen($large_string)' \
'3'

# === TESTS DE SYNCHRONISATION TEMPS RÉEL ===

# Étape 19: Modifications simultanées
test_session_sync "Modifications simultanées" \
'$shared = 1;' \
'$shared *= 2; $shared += 3; echo $shared' \
'5'

# Étape 20: État complexe persistant
test_session_sync "État complexe" \
'class StateManager {
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

# Nettoyer l'environnement de test
cleanup_test_environment

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
