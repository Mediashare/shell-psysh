#!/bin/bash

# Test 32: Commande phpunit:code - Mode code interactif
# Tests d'intégration pour le mode code interactif et la synchronisation

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/test_utils.sh"

# Initialiser le test
init_test "TEST 32: Commande phpunit:code"

# Étape 1: Créer un test pour le mode code
test_monitor_multiline "Créer un test pour code interactif" \
'phpunit:create InteractiveTest' \
'✅ Test créé : InteractiveTest'

# Étape 2: Ajouter du code via phpunit:code avec snippet
test_monitor_multiline "Ajouter code via snippet" \
'phpunit:code --snippet "$user = new stdClass(); $user->name = \"John\";"' \
'✅ Code ajouté au test'

# Étape 3: Test avec du code PHP valide
test_monitor_multiline "Code PHP complexe" \
'phpunit:code --snippet "$array = [1, 2, 3]; $sum = array_sum($array); echo $sum;"' \
'Code ajouté'

# Étape 4: Test avec code invalide (erreur de syntaxe)
test_monitor_error "Code PHP invalide" \
'phpunit:code --snippet "echo \"unclosed string"' \
'❌ Erreur de syntaxe PHP'

# Étape 5: Ajouter plusieurs snippets consécutifs
test_monitor_multiline "Plusieurs snippets" \
'phpunit:code --snippet "$first = true;"
phpunit:code --snippet "$second = \"hello\";"' \
'Code ajouté'

# Étape 6: Test sans test actuel
test_monitor_multiline "Test sans contexte de test" \
'unset($GLOBALS["phpunit_current_test"])
phpunit:code --snippet "$noTest = true;"' \
'❌ Aucun test actuel'

# Étape 7: Synchronisation entre shells - Test bidirectionnel
test_sync_bidirectional "Synchronisation code inter-shell" \
'phpunit:create SyncTest' \
'phpunit:code --snippet "$syncVar = 123;"' \
'echo isset($syncVar) ? "Variable synchronisée" : "Variable non trouvée"' \
'Variable synchronisée' \
'variable'

# Étape 8: Test de persistence des variables entre commandes
test_shell_responsiveness "Persistence des variables" \
'phpunit:create PersistTest
phpunit:code --snippet "$persistent = \"value\";"' \
'echo $persistent' \
'value'

# Étape 9: Test avec des objets complexes
test_monitor_multiline "Code avec objets" \
'phpunit:create ObjectTest
phpunit:code --snippet "class TestClass { public $prop = \"test\"; } $obj = new TestClass();"' \
'Code ajouté'

# Étape 10: Test de synchronisation avec --sync option
test_monitor_multiline "Option de synchronisation" \
'phpunit:create SyncOptionTest
phpunit:code --sync' \
'✅ Synchronisation réussie'

# Étape 11: Test avec code multi-lignes complexe
test_monitor_multiline "Code multi-lignes" \
'phpunit:code --snippet "
function testFunction($param) {
    return $param * 2;
}
$result = testFunction(5);
"' \
'Code ajouté'

# Étape 12: Test de récupération de code depuis le service
test_monitor_multiline "Vérification code dans service" \
'phpunit:create VerifyTest
phpunit:code --snippet "$verify = \"testing\";"
phpunit:code --verify' \
'Code présent'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
