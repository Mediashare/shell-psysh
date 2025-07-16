#!/bin/bash

# Test 30: Commande phpunit:create avec architecture modulaire
# Démonstration des capacités avancées de l'unified_test_executor

# Obtenir le répertoire du script et charger l'exécuteur unifié
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 30: Commande phpunit:create - Architecture avancée"

# Étape 1: Créer un test simple
'phpunit:create UserService' \
test_session_sync "Créer un test simple" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Test créé : UserService'

# Étape 2: Créer un test avec classe spécifiée
'phpunit:create PaymentService --class App\\Service\\PaymentService' \
test_session_sync "Créer un test avec classe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'📋 Classe testée : App\\Service\\PaymentService'

# Étape 3: Créer un test avec description
'phpunit:create EmailService --description "Tests for email service functionality"' \
test_session_sync "Créer un test avec description" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'📄 Description : Tests for email service functionality'

# Étape 4: Créer un test avec toutes les options
'phpunit:create OrderManager --class App\\Service\\OrderManager --description "Order management tests" --method testCreateOrder' \
test_session_sync "Créer un test complet" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'🔧 Méthode initiale : testCreateOrder'

# Étape 5: Vérifier que le test actuel est défini
'echo isset($GLOBALS["phpunit_current_test"]) ? "Test actuel défini" : "Aucun test actuel"' \
test_session_sync "Vérifier test actuel" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'Test actuel défini'

# Étape 6: Créer un test avec nom invalide (test d'erreur)
'phpunit:create 123InvalidName' \
test_session_sync "Nom de test invalide" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'❌'

# Étape 7: Lister les tests créés
'phpunit:list' \
test_session_sync "Lister les tests" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'UserService'

# Étape 8: Créer un test avec namespace complexe
'phpunit:create ComplexService --class App\\Domain\\User\\Service\\Registration\\EmailVerificationService' \
test_session_sync "Test avec namespace complexe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'App\\Domain\\User\\Service\\Registration\\EmailVerificationService'

# Étape 9: Overwrite d'un test existant
'phpunit:create UserService --description "Updated description"' \
test_session_sync "Écraser un test existant" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Test créé : UserService'

# Étape 10: Créer plusieurs tests et vérifier la liste
'phpunit:create FirstTest
test_session_sync "Créer plusieurs tests" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
phpunit:create SecondTest
phpunit:list' \
'FirstTest'

# =============================================================================
# TESTS AVANCÉS - Démonstration des nouvelles capacités
# =============================================================================

# Test avec retry automatique
"phpunit:create RetryTest" \
test_session_sync "Test avec retry" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
"✅ Test créé" \
--context phpunit --retry 3 --timeout 10

# Test avec vérification exacte
"phpunit:create ExactTest" \
test_session_sync "Vérification exacte du message" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
"✅ Test créé : ExactTest" \
--context phpunit --output-check exact

# Test combiné avec synchronisation
"phpunit:create SyncTest" \
test_session_sync "Test de synchronisation PHPUnit" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
"SyncTest" \
--context phpunit --sync-test

# Test avec input depuis fichier temporaire
echo 'phpunit:create FileTest --description "Test from file"' > /tmp/test_input.txt
    --step "cat /tmp/test_input.txt" \ --context psysh --output-check contains --tag "default_session"
test_session_sync "Test depuis fichier" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Test créé" \
    --context shell
rm -f /tmp/test_input.txt

# Test de combinaison de commandes
"phpunit:create CombinedTest" \
test_session_sync "Combinaison create + list" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
"phpunit:list" \
"CombinedTest"

# Test avec pattern d'erreur spécifique
"phpunit:create" \
test_session_sync "Pattern d'erreur spécifique" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
"Arguments manquants"

# Test avec debug activé
"phpunit:create DebugTest" \
test_session_sync "Test avec debug" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
"Test créé" \
--context phpunit --debug

# Test de performance avec timeout court
"phpunit:create PerfTest" \
test_session_sync "Test de performance" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
"Test créé" \
--context phpunit --timeout 5

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
