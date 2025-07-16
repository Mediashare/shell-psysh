#!/bin/bash

# Test 35: Synchronisation Shell/PHPUnit - Tests avancés de synchronisation
# Tests complets de synchronisation entre les shells PsySH et les commandes phpunit:*

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/test_utils.sh"

# Initialiser le test
init_test "TEST 35: Synchronisation Shell/PHPUnit"

# Étape 1: Test synchronisation basique - variables
test_sync_bidirectional "Synchronisation variable simple" \
'$globalVar = "test_value"' \
'phpunit:create SyncTest' \
'echo $globalVar' \
'test_value' \
'variable'

# Étape 2: Test synchronisation avec phpunit:code
test_sync_bidirectional "Synchronisation via phpunit:code" \
'phpunit:create CodeSyncTest' \
'phpunit:code --snippet "$codeVar = 123;"' \
'echo $codeVar' \
'123' \
'variable'

# Étape 3: Test synchronisation objet complexe
test_sync_bidirectional "Synchronisation objet" \
'$user = new stdClass(); $user->name = "John"; $user->age = 30' \
'phpunit:create ObjectSyncTest' \
'echo $user->name' \
'John' \
'object'

# Étape 4: Test synchronisation array
test_sync_bidirectional "Synchronisation array" \
'$testArray = [1, 2, 3, "test"]' \
'phpunit:create ArraySyncTest' \
'echo count($testArray)' \
'4' \
'array'

# Étape 5: Test synchronisation fonction
test_sync_bidirectional "Synchronisation fonction" \
'function testFunction($param) { return $param * 2; }' \
'phpunit:create FunctionSyncTest' \
'echo testFunction(5)' \
'10' \
'function'

# Étape 6: Test workflow complet avec synchronisation
test_sync_bidirectional "Workflow complet synchronisé" \
'$repository = "MockRepository"; $service = "MockService"' \
'phpunit:create WorkflowTest
phpunit:mock App\\Repository\\UserRepository --variable $repository
phpunit:code --snippet "$result = $service . \"_processed\";"' \
'echo $result' \
'MockService_processed' \
'workflow'

# Étape 7: Test synchronisation avec assertions
test_sync_bidirectional "Synchronisation avec assertions" \
'$testValue = 42' \
'phpunit:create AssertSyncTest
phpunit:assert "$this->assertEquals(42, $testValue)"' \
'echo "Assertion with value: " . $testValue' \
'Assertion with value: 42' \
'assertion'

# Étape 8: Test modification de variable après création de test
test_sync_bidirectional "Modification après création test" \
'$counter = 1' \
'phpunit:create CounterTest
$counter = $counter + 5' \
'echo $counter' \
'6' \
'modification'

# Étape 9: Test synchronisation avec multiples shells simulés
test_monitor_multiline "Simulation multiples shells" \
'$shell1Var = "shell1"
phpunit:create MultiShellTest
$shell2Var = "shell2"
phpunit:code --snippet "$combinedVar = $shell1Var . \"_\" . $shell2Var;"
echo $combinedVar' \
'shell1_shell2'

# Étape 10: Test persistance des mocks entre shells
test_sync_bidirectional "Persistance mocks" \
'phpunit:create MockPersistTest
phpunit:mock App\\Service\\TestService --variable $mockService' \
'phpunit:expect $mockService->process()->willReturn("mocked")' \
'echo "Mock configured"' \
'Mock configured' \
'mock'

# Étape 11: Test synchronisation avec classes
test_sync_bidirectional "Synchronisation classes" \
'class TestSyncClass { public $prop = "sync_test"; }' \
'phpunit:create ClassSyncTest
$obj = new TestSyncClass()' \
'echo $obj->prop' \
'sync_test' \
'class'

# Étape 12: Test erreur de synchronisation - variable non définie
test_monitor_error "Variable non synchronisée" \
'phpunit:create ErrorSyncTest
echo $undefinedVariable' \
'Undefined variable'

# Étape 13: Test synchronisation avec traits
test_sync_bidirectional "Synchronisation traits" \
'trait TestTrait { public function traitMethod() { return "trait_result"; } }' \
'phpunit:create TraitSyncTest
class TraitUser { use TestTrait; }
$traitObj = new TraitUser()' \
'echo $traitObj->traitMethod()' \
'trait_result' \
'trait'

# Étape 14: Test synchronisation globales
test_sync_bidirectional "Synchronisation variables globales" \
'$GLOBALS["test_global"] = "global_value"' \
'phpunit:create GlobalSyncTest' \
'echo $GLOBALS["test_global"]' \
'global_value' \
'global'

# Étape 15: Test sauvegarde/restauration état
test_monitor_multiline "Sauvegarde état synchronisation" \
'$persistentVar = "persistent"
phpunit:create PersistentTest
// Simuler sauvegarde état
$savedState = ["persistentVar" => $persistentVar]
// Simuler restoration
$restoredVar = $savedState["persistentVar"]
echo $restoredVar' \
'persistent'

# Étape 16: Test synchronisation avec gros volumes de données
test_sync_bidirectional "Synchronisation gros volumes" \
'$largeArray = range(1, 100); $largeString = str_repeat("A", 1000)' \
'phpunit:create LargeDataTest' \
'echo count($largeArray) . ":" . strlen($largeString)' \
'100:1000' \
'largedata'

# Étape 17: Test concurrence simulation
test_monitor_multiline "Simulation modifications concurrentes" \
'$counter = 0
phpunit:create ConcurrentTest
// Shell 1
$counter++
// Shell 2  
$counter = $counter + 5
// Shell 3
$counter = $counter * 2
echo $counter' \
'12'

# Étape 18: Test récupération après erreur
test_monitor_multiline "Récupération après erreur sync" \
'$validVar = "valid"
phpunit:create ErrorRecoveryTest
// Simuler erreur puis récupération
try {
    echo $invalidVar;
} catch (Error $e) {
    echo "Error handled, valid var: " . $validVar;
}' \
'Error handled, valid var: valid'

# Étape 19: Test workflow créatif complet
test_sync_bidirectional "Workflow créatif complet" \
'$user = new stdClass(); $user->id = 1; $user->name = "John"' \
'phpunit:create CreativeWorkflow
phpunit:mock App\\Repository\\UserRepository
phpunit:expect $userRepository->findById($user->id)->willReturn($user)
phpunit:code --snippet "$foundUser = $userRepository->findById($user->id);"
phpunit:assert "$this->assertEquals($user->name, $foundUser->name)"' \
'echo "Workflow completed for: " . $user->name' \
'Workflow completed for: John' \
'creative'

# Étape 20: Test métriques de synchronisation
test_monitor_multiline "Métriques synchronisation" \
'$syncStart = microtime(true)
phpunit:create MetricsTest
$var1 = "test1"; $var2 = "test2"; $var3 = "test3"
phpunit:code --snippet "$processed = count([$var1, $var2, $var3]);"
$syncEnd = microtime(true)
$syncDuration = $syncEnd - $syncStart
echo "Synced " . $processed . " variables"' \
'Synced 3 variables'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
