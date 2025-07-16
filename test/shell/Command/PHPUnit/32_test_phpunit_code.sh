#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 32: Commande phpunit:code"

# Étape 1: Créer un test pour le mode code
test_session_sync "Créer un test pour code interactif" \
'phpunit:create InteractiveTest' \
'✅ Test créé : InteractiveTest'

# Étape 2: Ajouter du code via phpunit:code avec snippet
test_session_sync "Ajouter code via snippet" \
'phpunit:code --snippet "$user = new stdClass(); $user->name = \"John\";"' \
'✅ Code ajouté au test'

# Étape 3: Test avec du code PHP valide
test_session_sync "Code PHP complexe" \
'phpunit:code --snippet "$array = [1, 2, 3]; $sum = array_sum($array); echo $sum;"' \
'Code ajouté'

# Étape 4: Test avec code invalide (erreur de syntaxe)
test_session_sync "Code PHP invalide" \
'phpunit:code --snippet "echo \"unclosed string"' \
'❌ Erreur de syntaxe PHP'

# Étape 5: Ajouter plusieurs snippets consécutifs
test_session_sync "Plusieurs snippets" \
'phpunit:code --snippet "$first = true;"
phpunit:code --snippet "$second = \"hello\";"' \
'Code ajouté'

# Étape 6: Test sans test actuel
test_session_sync "Test sans contexte de test" \
'unset($GLOBALS["phpunit_current_test"])
phpunit:code --snippet "$noTest = true;"' \
'❌ Aucun test actuel'

# Étape 7: Synchronisation entre shells - Test bidirectionnel
test_session_sync "Synchronisation code inter-shell" \
'phpunit:create SyncTest' \
'phpunit:code --snippet "$syncVar = 123;"' \
'echo isset($syncVar) ? "Variable synchronisée" : "Variable non trouvée"' \
'Variable synchronisée' \
'variable'

# Étape 8: Test de persistence des variables entre commandes
test_session_sync "Persistence des variables" \
'phpunit:create PersistTest
phpunit:code --snippet "$persistent = \"value\";"' \
'echo $persistent' \
'value'

# Étape 9: Test avec des objets complexes
test_session_sync "Code avec objets" \
'phpunit:create ObjectTest
phpunit:code --snippet "class TestClass { public $prop = \"test\"; } $obj = new TestClass();"' \
'Code ajouté'

# Étape 10: Test de synchronisation avec --sync option
test_session_sync "Option de synchronisation" \
'phpunit:create SyncOptionTest
phpunit:code --sync' \
'✅ Synchronisation réussie'

# Étape 11: Test avec code multi-lignes complexe
test_session_sync "Code multi-lignes" \
'phpunit:code --snippet "
function testFunction($param) {
    return $param * 2;
}
$result = testFunction(5);
"' \
'Code ajouté'

# Étape 12: Test de récupération de code depuis le service
test_session_sync "Vérification code dans service" \
'phpunit:create VerifyTest
phpunit:code --snippet "$verify = \"testing\";"
phpunit:code --verify' \
'Code présent'

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
