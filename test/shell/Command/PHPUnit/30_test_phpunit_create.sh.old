#!/bin/bash

# Test 30: Commande phpunit:create - Création de tests PHPUnit
# Tests d'intégration des fonctionnalités de création de tests

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/test_utils.sh"

# Initialiser le test
init_test "TEST 30: Commande phpunit:create"

# Étape 1: Créer un test simple
test_monitor_multiline "Créer un test simple" \
'phpunit:create UserService' \
'✅ Test créé : UserService'

# Étape 2: Créer un test avec classe spécifiée
test_monitor_multiline "Créer un test avec classe" \
'phpunit:create PaymentService --class App\\Service\\PaymentService' \
'📋 Classe testée : App\\Service\\PaymentService'

# Étape 3: Créer un test avec description
test_monitor_multiline "Créer un test avec description" \
'phpunit:create EmailService --description "Tests for email service functionality"' \
'📄 Description : Tests for email service functionality'

# Étape 4: Créer un test avec toutes les options
test_monitor_multiline "Créer un test complet" \
'phpunit:create OrderManager --class App\\Service\\OrderManager --description "Order management tests" --method testCreateOrder' \
'🔧 Méthode initiale : testCreateOrder'

# Étape 5: Vérifier que le test actuel est défini
test_monitor_expression "Vérifier test actuel" \
'echo isset($GLOBALS["phpunit_current_test"]) ? "Test actuel défini" : "Aucun test actuel"' \
'Test actuel défini'

# Étape 6: Créer un test avec nom invalide (test d'erreur)
test_monitor_error "Nom de test invalide" \
'phpunit:create 123InvalidName' \
'❌'

# Étape 7: Lister les tests créés
test_monitor_multiline "Lister les tests" \
'phpunit:list' \
'UserService'

# Étape 8: Créer un test avec namespace complexe
test_monitor_multiline "Test avec namespace complexe" \
'phpunit:create ComplexService --class App\\Domain\\User\\Service\\Registration\\EmailVerificationService' \
'App\\Domain\\User\\Service\\Registration\\EmailVerificationService'

# Étape 9: Overwrite d'un test existant
test_monitor_multiline "Écraser un test existant" \
'phpunit:create UserService --description "Updated description"' \
'✅ Test créé : UserService'

# Étape 10: Créer plusieurs tests et vérifier la liste
test_monitor_multiline "Créer plusieurs tests" \
'phpunit:create FirstTest
phpunit:create SecondTest
phpunit:list' \
'FirstTest'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
