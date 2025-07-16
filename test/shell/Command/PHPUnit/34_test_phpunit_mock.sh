#!/bin/bash

# Test 34: Commandes phpunit:mock - Système de mocks et stubs
# Tests d'intégration pour les fonctionnalités de mocking PHPUnit

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 34: Commandes phpunit:mock"

# Étape 1: Créer un test pour les mocks
'phpunit:create MockTest' \
test_session_sync "Créer un test pour mocks" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Test créé : MockTest'

# Étape 2: Créer un mock simple
'phpunit:mock App\\Repository\\UserRepository' \
test_session_sync "Créer un mock simple" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Mock créé'

# Étape 3: Créer un mock avec variable personnalisée
'phpunit:mock App\\Service\\PaymentService --variable $paymentMock' \
test_session_sync "Mock avec variable personnalisée" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Mock créé : $paymentMock'

# Étape 4: Créer un mock avec méthodes spécifiées
'phpunit:mock App\\Service\\EmailService --methods ["send", "validate", "queue"]' \
test_session_sync "Mock avec méthodes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'🔧 Méthodes mockées : send, validate, queue'

# Étape 5: Mock avec arguments constructeur
'phpunit:mock App\\Service\\ConfigurableService --constructor-args ["arg1", "arg2"]' \
test_session_sync "Mock avec constructeur" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'🏗️ Arguments constructeur'

# Étape 6: Mock partiel
'phpunit:partial-mock App\\Service\\EmailService ["send", "validate"]' \
test_session_sync "Mock partiel" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Mock partiel créé'

# Étape 7: Configurer des expectations
'phpunit:expect $userRepository->findById(1)->willReturn($user)' \
test_session_sync "Configurer expectation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Expectation configurée'

# Étape 8: Expectation avec argument any
'phpunit:expect $paymentService->process(Argument::any())->willReturn(true)' \
test_session_sync "Expectation avec Argument::any()" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Expectation configurée'

# Étape 9: Expectation avec exception
'phpunit:expect $paymentService->validate(Argument::type(--output-check result))->willThrow(new InvalidArgumentException())' \
test_session_sync "Expectation avec exception" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Expectation configurée'

# Étape 10: Appel de méthode originale
'phpunit:call-original $emailService->validate()' \
test_session_sync "Appeler méthode originale" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Configuration pour appeler la méthode originale'

# Étape 11: Vérification des appels
'phpunit:verify $paymentService->process(Argument::any())->wasCalledTimes(2)' \
test_session_sync "Vérifier les appels" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Vérification réussie'

# Étape 12: Activer espionnage
'phpunit:spy $userRepository' \
test_session_sync "Activer espionnage" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Espionnage activé sur $userRepository'

# Étape 13: Obtenir les appels espionnés
'phpunit:get-calls $userRepository' \
test_session_sync "Obtenir appels espionnés" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'📊 Appels enregistrés'

# Étape 14: Mock avec JSON invalide (erreur)
'phpunit:mock App\\Service\\TestService --methods "invalid json"' \
test_session_sync "Mock avec JSON invalide" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'❌ Format JSON invalide'

# Étape 15: Mock avec interface
'phpunit:mock App\\Contract\\PaymentGatewayInterface' \
test_session_sync "Mock d'interface" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Mock créé'

# Étape 16: Mock avec classe abstraite
'phpunit:mock App\\Abstract\\AbstractProcessor' \
test_session_sync "Mock de classe abstraite" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Mock créé'

# Étape 17: Multiples mocks dans le même test
'phpunit:mock App\\Repository\\ProductRepository
test_session_sync "Multiples mocks" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
phpunit:mock App\\Service\\NotificationService' \
'✅ Mock créé'

# Étape 18: Mock avec namespace complexe
'phpunit:mock App\\Domain\\User\\Service\\Registration\\EmailVerificationService' \
test_session_sync "Mock avec namespace complexe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Mock créé'

# Étape 19: Test workflow complet mock
'phpunit:create CompleteWorkflow
test_session_sync "Workflow complet de mock" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
phpunit:mock App\\Repository\\UserRepository
phpunit:expect $userRepository->findById(1)->willReturn($user)
phpunit:spy $userRepository
phpunit:verify $userRepository->findById(1)->wasCalledOnce()' \
'✅ Vérification réussie'

# Étape 20: Mock avec options complètes
'phpunit:mock App\\Service\\ComplexService --variable $complexMock --methods ["process", "validate"] --constructor-args ["dep1", "dep2"] --partial' \
test_session_sync "Mock avec toutes options" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'⚙️ Mock partiel activé'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
