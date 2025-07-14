#!/bin/bash

# Test 31: Commande phpunit:add - Ajout de méthodes de test
# Tests d'intégration pour ajouter des méthodes aux tests PHPUnit

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/test_utils.sh"

# Initialiser le test
init_test "TEST 31: Commande phpunit:add"

# Étape 1: Créer un test pour ajouter des méthodes
test_monitor_multiline "Créer un test de base" \
'phpunit:create TestMethodAdd' \
'✅ Test créé : TestMethodAdd'

# Étape 2: Ajouter une méthode simple
test_monitor_multiline "Ajouter une méthode simple" \
'phpunit:add testUserCreation' \
'✅ Méthode ajoutée : testUserCreation'

# Étape 3: Ajouter une méthode avec description
test_monitor_multiline "Ajouter méthode avec description" \
'phpunit:add testEmailValidation --description "Test email validation functionality"' \
'📄 Description : Test email validation functionality'

# Étape 4: Ajouter méthode avec data provider
test_monitor_multiline "Ajouter méthode avec data provider" \
'phpunit:add testPasswordStrength --data-provider passwordDataProvider' \
'🔗 Data provider : passwordDataProvider'

# Étape 5: Ajouter méthode avec exception attendue
test_monitor_multiline "Ajouter méthode avec exception" \
'phpunit:add testInvalidInput --expects-exception InvalidArgumentException' \
'⚠️ Exception attendue : InvalidArgumentException'

# Étape 6: Ajouter méthode avec dépendance
test_monitor_multiline "Ajouter méthode avec dépendance" \
'phpunit:add testDependentMethod --depends testUserCreation' \
'🔗 Dépend de : testUserCreation'

# Étape 7: Ajouter méthode avec toutes les options
test_monitor_multiline "Ajouter méthode complète" \
'phpunit:add testCompleteScenario --description "Complete test scenario" --data-provider scenarioData --expects-exception RuntimeException --depends testUserCreation' \
'🔗 Data provider : scenarioData'

# Étape 8: Tenter d'ajouter sans test actuel (test d'erreur)
test_monitor_multiline "Réinitialiser contexte et test erreur" \
'unset($GLOBALS["phpunit_current_test"])
phpunit:add testWithoutCurrentTest' \
'❌ Aucun test actuel'

# Étape 9: Recharger test et ajouter méthode avec nom invalide
test_monitor_multiline "Rétablir contexte" \
'phpunit:create TestMethodAdd' \
'✅ Test créé : TestMethodAdd'

test_monitor_error "Nom de méthode invalide" \
'phpunit:add 123invalidMethod' \
'❌'

# Étape 10: Ajouter plusieurs méthodes et vérifier la génération
test_monitor_multiline "Ajouter plusieurs méthodes" \
'phpunit:add testFirstMethod
phpunit:add testSecondMethod
phpunit:add testThirdMethod' \
'✅ Méthode ajoutée : testThirdMethod'

# Étape 11: Remplacer une méthode existante
test_monitor_multiline "Remplacer méthode existante" \
'phpunit:add testFirstMethod --description "Updated description"' \
'✅ Méthode ajoutée : testFirstMethod'

# Étape 12: Test avec setup et teardown
test_monitor_multiline "Méthode avec setup et teardown" \
'phpunit:add testWithSetupTeardown --setup --teardown' \
'✅ Méthode ajoutée : testWithSetupTeardown'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
