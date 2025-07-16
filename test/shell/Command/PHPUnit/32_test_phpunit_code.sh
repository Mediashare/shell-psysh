#!/bin/bash

# Test 32: Commande phpunit:code - Mode code interactif
# Tests d'intégration pour le mode code interactif et la synchronisation

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 32: Commande phpunit:code"

# Étape 1: Créer un test pour le mode code
'phpunit:create InteractiveTest' \
test_session_sync "Créer un test pour code interactif" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Test créé : InteractiveTest'

# Étape 2: Ajouter du code via phpunit:code avec snippet
'phpunit:code --snippet "$user = new stdClass(); $user->name = \"John\";"' \
test_session_sync "Ajouter code via snippet" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Code ajouté au test'

# Étape 3: Test avec du code PHP valide
'phpunit:code --snippet "$array = [1, 2, 3]; $sum = array_sum($array); echo $sum;"' \
test_session_sync "Code PHP complexe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'Code ajouté'

# Étape 4: Test avec code invalide (erreur de syntaxe)
'phpunit:code --snippet "echo \"unclosed string"' \
test_session_sync "Code PHP invalide" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'❌ Erreur de syntaxe PHP'

# Étape 5: Ajouter plusieurs snippets consécutifs
'phpunit:code --snippet "$first = true;"
test_session_sync "Plusieurs snippets" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
phpunit:code --snippet "$second = \"hello\";"' \
'Code ajouté'

# Étape 6: Test sans test actuel
'unset($GLOBALS["phpunit_current_test"])
test_session_sync "Test sans contexte de test" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
phpunit:code --snippet "$noTest = true;"' \
'❌ Aucun test actuel'

# Étape 7: Synchronisation entre shells - Test bidirectionnel
'phpunit:create SyncTest' \
test_session_sync "Synchronisation code inter-shell" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context shell \
    --output-check contains \
    --shell \
    --tag "shell_session"
'phpunit:code --snippet "$syncVar = 123;"' \
'echo isset($syncVar) ? "Variable synchronisée" : "Variable non trouvée"' \
'Variable synchronisée' \
'variable'

# Étape 8: Test de persistence des variables entre commandes
'phpunit:create PersistTest
test_session_sync "Persistence des variables" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
phpunit:code --snippet "$persistent = \"value\";"' \
'echo $persistent' \
'value'

# Étape 9: Test avec des objets complexes
'phpunit:create ObjectTest
test_session_sync "Code avec objets" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
phpunit:code --snippet "class TestClass { public $prop = \"test\"; } $obj = new TestClass();"' \
'Code ajouté'

# Étape 10: Test de synchronisation avec --sync option
'phpunit:create SyncOptionTest
test_session_sync "Option de synchronisation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "sync_session"
phpunit:code --sync' \
'✅ Synchronisation réussie'

# Étape 11: Test avec code multi-lignes complexe
'phpunit:code --snippet "
test_session_sync "Code multi-lignes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
function testFunction($param) {
    return $param * 2;
}
$result = testFunction(5);
"' \
'Code ajouté'

# Étape 12: Test de récupération de code depuis le service
'phpunit:create VerifyTest
test_session_sync "Vérification code dans service" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
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
