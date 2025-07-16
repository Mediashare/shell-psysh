#!/bin/bash

# Test 31: Commande phpunit:add - Ajout de méthodes de test
# Tests d'intégration pour ajouter des méthodes aux tests PHPUnit

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 31: Commande phpunit:add"

# Étape 1: Créer un test pour ajouter des méthodes
'phpunit:create TestMethodAdd' \
test_session_sync "Créer un test de base" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Test créé : TestMethodAdd'

# Étape 2: Ajouter une méthode simple
'phpunit:add testUserCreation' \
test_session_sync "Ajouter une méthode simple" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Méthode ajoutée : testUserCreation'

# Étape 3: Ajouter une méthode avec description
'phpunit:add testEmailValidation --description "Test email validation functionality"' \
test_session_sync "Ajouter méthode avec description" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'📄 Description : Test email validation functionality'

# Étape 4: Ajouter méthode avec data provider
'phpunit:add testPasswordStrength --data-provider passwordDataProvider' \
test_session_sync "Ajouter méthode avec data provider" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'🔗 Data provider : passwordDataProvider'

# Étape 5: Ajouter méthode avec exception attendue
'phpunit:add testInvalidInput --expects-exception InvalidArgumentException' \
test_session_sync "Ajouter méthode avec exception" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'⚠️ Exception attendue : InvalidArgumentException'

# Étape 6: Ajouter méthode avec dépendance
'phpunit:add testDependentMethod --depends testUserCreation' \
test_session_sync "Ajouter méthode avec dépendance" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'🔗 Dépend de : testUserCreation'

# Étape 7: Ajouter méthode avec toutes les options
'phpunit:add testCompleteScenario --description "Complete test scenario" --data-provider scenarioData --expects-exception RuntimeException --depends testUserCreation' \
test_session_sync "Ajouter méthode complète" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'🔗 Data provider : scenarioData'

# Étape 8: Tenter d'ajouter sans test actuel (test d'erreur)
'unset($GLOBALS["phpunit_current_test"])
test_session_sync "Réinitialiser contexte et test erreur" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
phpunit:add testWithoutCurrentTest' \
'❌ Aucun test actuel'

# Étape 9: Recharger test et ajouter méthode avec nom invalide
'phpunit:create TestMethodAdd' \
test_session_sync "Rétablir contexte" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Test créé : TestMethodAdd'

'phpunit:add 123invalidMethod' \
test_session_sync "Nom de méthode invalide" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'❌'

# Étape 10: Ajouter plusieurs méthodes et vérifier la génération
'phpunit:add testFirstMethod
test_session_sync "Ajouter plusieurs méthodes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
phpunit:add testSecondMethod
phpunit:add testThirdMethod' \
'✅ Méthode ajoutée : testThirdMethod'

# Étape 11: Remplacer une méthode existante
'phpunit:add testFirstMethod --description "Updated description"' \
test_session_sync "Remplacer méthode existante" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Méthode ajoutée : testFirstMethod'

# Étape 12: Test avec setup et teardown
'phpunit:add testWithSetupTeardown --setup --teardown' \
test_session_sync "Méthode avec setup et teardown" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Méthode ajoutée : testWithSetupTeardown'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
