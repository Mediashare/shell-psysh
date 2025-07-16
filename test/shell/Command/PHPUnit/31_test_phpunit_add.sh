#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 31: Commande phpunit:add"

# Étape 1: Créer un test pour ajouter des méthodes
test_session_sync "Créer un test de base" \
'phpunit:create TestMethodAdd' \
'✅ Test créé : TestMethodAdd'

# Étape 2: Ajouter une méthode simple
test_session_sync "Ajouter une méthode simple" \
'phpunit:add testUserCreation' \
'✅ Méthode ajoutée : testUserCreation'

# Étape 3: Ajouter une méthode avec description
test_session_sync "Ajouter méthode avec description" \
'phpunit:add testEmailValidation --description "Test email validation functionality"' \
'📄 Description : Test email validation functionality'

# Étape 4: Ajouter méthode avec data provider
test_session_sync "Ajouter méthode avec data provider" \
'phpunit:add testPasswordStrength --data-provider passwordDataProvider' \
'🔗 Data provider : passwordDataProvider'

# Étape 5: Ajouter méthode avec exception attendue
test_session_sync "Ajouter méthode avec exception" \
'phpunit:add testInvalidInput --expects-exception InvalidArgumentException' \
'⚠️ Exception attendue : InvalidArgumentException'

# Étape 6: Ajouter méthode avec dépendance
test_session_sync "Ajouter méthode avec dépendance" \
'phpunit:add testDependentMethod --depends testUserCreation' \
'🔗 Dépend de : testUserCreation'

# Étape 7: Ajouter méthode avec toutes les options
test_session_sync "Ajouter méthode complète" \
'phpunit:add testCompleteScenario --description "Complete test scenario" --data-provider scenarioData --expects-exception RuntimeException --depends testUserCreation' \
'🔗 Data provider : scenarioData'

# Étape 8: Tenter d'ajouter sans test actuel (test d'erreur)
test_session_sync "Réinitialiser contexte et test erreur" \
'unset($GLOBALS["phpunit_current_test"])
phpunit:add testWithoutCurrentTest' \
'❌ Aucun test actuel'

# Étape 9: Recharger test et ajouter méthode avec nom invalide
test_session_sync "Rétablir contexte" \
'phpunit:create TestMethodAdd' \
'✅ Test créé : TestMethodAdd'

test_session_sync "Nom de méthode invalide" \
'phpunit:add 123invalidMethod' \
'❌'

# Étape 10: Ajouter plusieurs méthodes et vérifier la génération
test_session_sync "Ajouter plusieurs méthodes" \
'phpunit:add testFirstMethod
phpunit:add testSecondMethod
phpunit:add testThirdMethod' \
'✅ Méthode ajoutée : testThirdMethod'

# Étape 11: Remplacer une méthode existante
test_session_sync "Remplacer méthode existante" \
'phpunit:add testFirstMethod --description "Updated description"' \
'✅ Méthode ajoutée : testFirstMethod'

# Étape 12: Test avec setup et teardown
test_session_sync "Méthode avec setup et teardown" \
'phpunit:add testWithSetupTeardown --setup --teardown' \
'✅ Méthode ajoutée : testWithSetupTeardown'

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
