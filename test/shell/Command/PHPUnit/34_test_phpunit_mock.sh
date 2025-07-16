#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 34: Commandes phpunit:mock"

# Étape 1: Créer un test pour les mocks
test_session_sync "Créer un test pour mocks" \
'phpunit:create MockTest' \
'✅ Test créé : MockTest'

# Étape 2: Créer un mock simple
test_session_sync "Créer un mock simple" \
'phpunit:mock App\\Repository\\UserRepository' \
'✅ Mock créé'

# Étape 3: Créer un mock avec variable personnalisée
test_session_sync "Mock avec variable personnalisée" \
'phpunit:mock App\\Service\\PaymentService --variable $paymentMock' \
'✅ Mock créé : $paymentMock'

# Étape 4: Créer un mock avec méthodes spécifiées
test_session_sync "Mock avec méthodes" \
'phpunit:mock App\\Service\\EmailService --methods ["send", "validate", "queue"]' \
'🔧 Méthodes mockées : send, validate, queue'

# Étape 5: Mock avec arguments constructeur
test_session_sync "Mock avec constructeur" \
'phpunit:mock App\\Service\\ConfigurableService --constructor-args ["arg1", "arg2"]' \
'🏗️ Arguments constructeur'

# Étape 6: Mock partiel
test_session_sync "Mock partiel" \
'phpunit:partial-mock App\\Service\\EmailService ["send", "validate"]' \
'✅ Mock partiel créé'

# Étape 7: Configurer des expectations
test_session_sync "Configurer expectation" \
'phpunit:expect $userRepository->findById(1)->willReturn($user)' \
'✅ Expectation configurée'

# Étape 8: Expectation avec argument any
test_session_sync "Expectation avec Argument::any()" \
'phpunit:expect $paymentService->process(Argument::any())->willReturn(true)' \
'✅ Expectation configurée'

# Étape 9: Expectation avec exception
test_session_sync "Expectation avec exception" \
'phpunit:expect $paymentService->validate(Argument::type("array"))->willThrow(new InvalidArgumentException())' \
'✅ Expectation configurée'

# Étape 10: Appel de méthode originale
test_session_sync "Appeler méthode originale" \
'phpunit:call-original $emailService->validate()' \
'✅ Configuration pour appeler la méthode originale'

# Étape 11: Vérification des appels
test_session_sync "Vérifier les appels" \
'phpunit:verify $paymentService->process(Argument::any())->wasCalledTimes(2)' \
'✅ Vérification réussie'

# Étape 12: Activer espionnage
test_session_sync "Activer espionnage" \
'phpunit:spy $userRepository' \
'✅ Espionnage activé sur $userRepository'

# Étape 13: Obtenir les appels espionnés
test_session_sync "Obtenir appels espionnés" \
'phpunit:get-calls $userRepository' \
'📊 Appels enregistrés'

# Étape 14: Mock avec JSON invalide (erreur)
test_session_sync "Mock avec JSON invalide" \
'phpunit:mock App\\Service\\TestService --methods "invalid json"' \
'❌ Format JSON invalide'

# Étape 15: Mock avec interface
test_session_sync "Mock d'interface" \
'phpunit:mock App\\Contract\\PaymentGatewayInterface' \
'✅ Mock créé'

# Étape 16: Mock avec classe abstraite
test_session_sync "Mock de classe abstraite" \
'phpunit:mock App\\Abstract\\AbstractProcessor' \
'✅ Mock créé'

# Étape 17: Multiples mocks dans le même test
test_session_sync "Multiples mocks" \
'phpunit:mock App\\Repository\\ProductRepository
phpunit:mock App\\Service\\NotificationService' \
'✅ Mock créé'

# Étape 18: Mock avec namespace complexe
test_session_sync "Mock avec namespace complexe" \
'phpunit:mock App\\Domain\\User\\Service\\Registration\\EmailVerificationService' \
'✅ Mock créé'

# Étape 19: Test workflow complet mock
test_session_sync "Workflow complet de mock" \
'phpunit:create CompleteWorkflow
phpunit:mock App\\Repository\\UserRepository
phpunit:expect $userRepository->findById(1)->willReturn($user)
phpunit:spy $userRepository
phpunit:verify $userRepository->findById(1)->wasCalledOnce()' \
'✅ Vérification réussie'

# Étape 20: Mock avec options complètes
test_session_sync "Mock avec toutes options" \
'phpunit:mock App\\Service\\ComplexService --variable $complexMock --methods ["process", "validate"] --constructor-args ["dep1", "dep2"] --partial' \
'⚙️ Mock partiel activé'

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
