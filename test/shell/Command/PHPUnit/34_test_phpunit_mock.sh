#!/bin/bash

# Test 34: Commandes phpunit:mock - Système de mocks et stubs
# Tests d'intégration pour les fonctionnalités de mocking PHPUnit

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/test_utils.sh"

# Initialiser le test
init_test "TEST 34: Commandes phpunit:mock"

# Étape 1: Créer un test pour les mocks
test_monitor_multiline "Créer un test pour mocks" \
'phpunit:create MockTest' \
'✅ Test créé : MockTest'

# Étape 2: Créer un mock simple
test_monitor_multiline "Créer un mock simple" \
'phpunit:mock App\\Repository\\UserRepository' \
'✅ Mock créé'

# Étape 3: Créer un mock avec variable personnalisée
test_monitor_multiline "Mock avec variable personnalisée" \
'phpunit:mock App\\Service\\PaymentService --variable $paymentMock' \
'✅ Mock créé : $paymentMock'

# Étape 4: Créer un mock avec méthodes spécifiées
test_monitor_multiline "Mock avec méthodes" \
'phpunit:mock App\\Service\\EmailService --methods ["send", "validate", "queue"]' \
'🔧 Méthodes mockées : send, validate, queue'

# Étape 5: Mock avec arguments constructeur
test_monitor_multiline "Mock avec constructeur" \
'phpunit:mock App\\Service\\ConfigurableService --constructor-args ["arg1", "arg2"]' \
'🏗️ Arguments constructeur'

# Étape 6: Mock partiel
test_monitor_multiline "Mock partiel" \
'phpunit:partial-mock App\\Service\\EmailService ["send", "validate"]' \
'✅ Mock partiel créé'

# Étape 7: Configurer des expectations
test_monitor_multiline "Configurer expectation" \
'phpunit:expect $userRepository->findById(1)->willReturn($user)' \
'✅ Expectation configurée'

# Étape 8: Expectation avec argument any
test_monitor_multiline "Expectation avec Argument::any()" \
'phpunit:expect $paymentService->process(Argument::any())->willReturn(true)' \
'✅ Expectation configurée'

# Étape 9: Expectation avec exception
test_monitor_multiline "Expectation avec exception" \
'phpunit:expect $paymentService->validate(Argument::type("array"))->willThrow(new InvalidArgumentException())' \
'✅ Expectation configurée'

# Étape 10: Appel de méthode originale
test_monitor_multiline "Appeler méthode originale" \
'phpunit:call-original $emailService->validate()' \
'✅ Configuration pour appeler la méthode originale'

# Étape 11: Vérification des appels
test_monitor_multiline "Vérifier les appels" \
'phpunit:verify $paymentService->process(Argument::any())->wasCalledTimes(2)' \
'✅ Vérification réussie'

# Étape 12: Activer espionnage
test_monitor_multiline "Activer espionnage" \
'phpunit:spy $userRepository' \
'✅ Espionnage activé sur $userRepository'

# Étape 13: Obtenir les appels espionnés
test_monitor_multiline "Obtenir appels espionnés" \
'phpunit:get-calls $userRepository' \
'📊 Appels enregistrés'

# Étape 14: Mock avec JSON invalide (erreur)
test_monitor_error "Mock avec JSON invalide" \
'phpunit:mock App\\Service\\TestService --methods "invalid json"' \
'❌ Format JSON invalide'

# Étape 15: Mock avec interface
test_monitor_multiline "Mock d'interface" \
'phpunit:mock App\\Contract\\PaymentGatewayInterface' \
'✅ Mock créé'

# Étape 16: Mock avec classe abstraite
test_monitor_multiline "Mock de classe abstraite" \
'phpunit:mock App\\Abstract\\AbstractProcessor' \
'✅ Mock créé'

# Étape 17: Multiples mocks dans le même test
test_monitor_multiline "Multiples mocks" \
'phpunit:mock App\\Repository\\ProductRepository
phpunit:mock App\\Service\\NotificationService' \
'✅ Mock créé'

# Étape 18: Mock avec namespace complexe
test_monitor_multiline "Mock avec namespace complexe" \
'phpunit:mock App\\Domain\\User\\Service\\Registration\\EmailVerificationService' \
'✅ Mock créé'

# Étape 19: Test workflow complet mock
test_monitor_multiline "Workflow complet de mock" \
'phpunit:create CompleteWorkflow
phpunit:mock App\\Repository\\UserRepository
phpunit:expect $userRepository->findById(1)->willReturn($user)
phpunit:spy $userRepository
phpunit:verify $userRepository->findById(1)->wasCalledOnce()' \
'✅ Vérification réussie'

# Étape 20: Mock avec options complètes
test_monitor_multiline "Mock avec toutes options" \
'phpunit:mock App\\Service\\ComplexService --variable $complexMock --methods ["process", "validate"] --constructor-args ["dep1", "dep2"] --partial' \
'⚙️ Mock partiel activé'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
