# Prompt : Intégration complète PHPUnit dans PsySH

## Objectif
Créer une suite complète de commandes PHPUnit intégrées dans le shell PsySH pour un projet Symfony, permettant de créer, exécuter et déboguer des tests unitaires de manière interactive. Créer cette commande dans le dossier ./.psysh/

## Architecture des commandes

### 1. Gestion des Tests Interactifs

#### Création et gestion de tests
```bash
# Créer un nouveau test interactif
>>> phpunit:create App\Service\InvoiceService
✅ Test créé : InvoiceServiceTest (mode interactif)

# Ajouter une méthode de test
>>> phpunit:add testGenerate
✅ Méthode testGenerate ajoutée

# Ajouter du code de test ligne par ligne
>>> phpunit:code
[Test Code Mode] >>> $invoiceService = new InvoiceService();
[Test Code Mode] >>> $user = new User(['id' => 1, 'email' => 'test@example.com']);
[Test Code Mode] >>> $result = $invoiceService->generate($user);
[Test Code Mode] >>> exit
## 1. Créer un test
>>> phpunit:create App\Service\InvoiceService
✅ Test créé : InvoiceServiceTest

## 2. Ajouter une méthode
>>> phpunit:add testComplexScenario
✅ Méthode ajoutée : testComplexScenario

## 3. Entrer en mode code pour développer le test
>>> phpunit:code
[Code Mode] >>> // Setup des données
[Code Mode] >>> $user = new User(['id' => 1, 'email' => 'test@example.com']);
[Code Mode] >>> $products = [
[Code Mode] ...     new Product(['id' => 1, 'price' => 50]),
[Code Mode] ...     new Product(['id' => 2, 'price' => 30])
[Code Mode] ... ];
[Code Mode] >>> 
[Code Mode] >>> // Test du service
[Code Mode] >>> $invoiceService = new InvoiceService();
[Code Mode] >>> $result = $invoiceService->generate($user, $products);
[Code Mode] >>> 
[Code Mode] >>> // Vérifications intermédiaires
[Code Mode] >>> var_dump($result->getTotal()); // 80
[Code Mode] >>> var_dump($result->getItems()); // Array(2)
[Code Mode] >>> 
[Code Mode] >>> exit
✅ Code ajouté au test (8 lignes)

## 4. Ajouter des assertions
>>> phpunit:assert $result->getTotal() == 80
>>> phpunit:assert count($result->getItems()) == 2

## 5. Exécuter le test complet
>>> phpunit:run
🧪 Exécution : testComplexScenario
✅ Test réussi avec 2 assertions

## 6. Sauvegarder le test
>>> phpunit:export InvoiceServiceTest
✅ Test exporté vers tests/Generated/InvoiceServiceTest.php

# Lister les tests actifs
>>> phpunit:list
📋 Tests actifs :
- InvoiceServiceTest::testGenerate [3 lignes]
- UserServiceTest::testCreate [5 lignes]
```

#### Snapshots et captures d'état
```bash
# Créer un snapshot du résultat
>>> phpunit:snapshot 'invoice_generation_result' => $result
✅ Snapshot créé :
$this->assertEquals([
    'id' => 1,
    'status' => 'pending',
    'total' => 100.0,
    'items' => [...]
], $invoiceService->generate($user));

# Comparer avec un snapshot existant
>>> phpunit:compare 'invoice_generation_result' => $newResult
❌ Différence détectée :
- Expected: 'status' => 'pending'
+ Actual: 'status' => 'paid'

# Sauvegarder un snapshot permanent
>>> phpunit:save-snapshot 'invoice_generation_result'
✅ Snapshot sauvegardé dans tests/snapshots/invoice_generation_result.php
```

### 2. Système de Mocks et Stubs

#### Création et configuration de mocks
```bash
# Créer un mock
>>> phpunit:mock App\Repository\InvoiceRepository
✅ Mock créé : $invoiceRepository

# Configurer les expectations
>>> phpunit:expect $invoiceRepository->findById(1)->willReturn($invoice)
✅ Expectation configurée

# Mock avec méthodes multiples
>>> phpunit:mock App\Service\PaymentService
>>> phpunit:expect $paymentService->process(Argument::any())->willReturn(true)
>>> phpunit:expect $paymentService->validate(Argument::type('array'))->willThrow(new InvalidArgumentException())

# Mock partiel
>>> phpunit:partial-mock App\Service\EmailService ['send', 'validate']
>>> phpunit:expect $emailService->send(Argument::any())->willReturn(true)
>>> phpunit:call-original $emailService->validate()

# Vérifier les appels
>>> phpunit:verify $paymentService->process(Argument::any())->wasCalledTimes(2)
✅ Vérification réussie

# Spy sur les appels
>>> phpunit:spy $invoiceRepository
>>> phpunit:get-calls $invoiceRepository
📊 Appels enregistrés :
- findById(1) - appelé 2 fois
- save(Invoice) - appelé 1 fois
```

### 3. Assertions Avancées

#### Assertions classiques
```bash
# Assertion simple
>>> phpunit:assert $invoice->getTotal() == 100
✅ Assertion réussie

# Assertion avec message
>>> phpunit:assert $invoice->getStatus() == 'paid', 'Invoice should be paid'
❌ Assertion échouée : Invoice should be paid
Expected: 'paid'
Actual: 'pending'

# Assertions typées
>>> phpunit:assert-type 'array' => $result
>>> phpunit:assert-instance App\Entity\Invoice => $invoice
>>> phpunit:assert-count 3 => $items
>>> phpunit:assert-empty => $errors
>>> phpunit:assert-true => $isValid
```

#### Assertions sur les exceptions
```bash
# Expect exception
>>> phpunit:expect-exception InvalidArgumentException
>>> $service->processInvalidData([])
✅ Exception attendue capturée

# Expect exception avec message
>>> phpunit:expect-exception InvalidArgumentException, 'Invalid data provided'
>>> $service->processInvalidData([])
✅ Exception avec message correct

# Expect no exception
>>> phpunit:expect-no-exception
>>> $service->processValidData(['valid' => true])
✅ Aucune exception lancée
```

### 4. Configuration et Exécution

#### Configuration PHPUnit
```bash
# Afficher la configuration actuelle
>>> phpunit:config
📋 Configuration PHPUnit :
- phpunit.dist.xml : ./phpunit.dist.xml
- TestSuite : unit
- Bootstrap : tests/bootstrap.php
- Coverage : disabled

# Modifier la configuration
>>> phpunit:config --testsuite=integration
>>> phpunit:config --coverage=html --coverage-dir=var/coverage
>>> phpunit:config --bootstrap=tests/custom_bootstrap.php

# Créer une configuration temporaire
>>> phpunit:temp-config
✅ Configuration temporaire créée pour cette session

# Restaurer la configuration
>>> phpunit:restore-config
✅ Configuration restaurée
```

#### Exécution des tests
```bash
# Exécuter le test actuel
>>> phpunit:run
🧪 Exécution du test : InvoiceServiceTest::testGenerate
✅ Test réussi (0.15s)

# Exécuter tous les tests interactifs
>>> phpunit:run-all
🧪 Exécution de 3 tests interactifs :
✅ InvoiceServiceTest::testGenerate (0.15s)
❌ UserServiceTest::testCreate (0.08s)
✅ PaymentServiceTest::testProcess (0.22s)

# Exécuter les tests du projet
>>> phpunit:run-project
🧪 Exécution des tests du projet :
✅ 45 tests réussis, 2 échecs, 1 skipped

# Exécuter avec coverage
>>> phpunit:run --coverage
🧪 Test avec coverage :
✅ Test réussi
📊 Coverage : 85% (lignes), 92% (méthodes)

# Exécuter en mode watch
>>> phpunit:watch
👁️ Mode watch activé - Les tests se relancent automatiquement...
```

### 5. Debugging et Analyse

#### Traces et stack traces
```bash
# Activer le mode debug
>>> phpunit:debug on
✅ Mode debug activé

# Afficher la stack trace du dernier échec
>>> phpunit:trace
📊 Stack trace :
InvoiceServiceTest::testGenerate:15
App\Service\InvoiceService::generate:42
App\Repository\InvoiceRepository::findById:23

# Profiler une méthode
>>> phpunit:profile $invoiceService->generate($user)
📊 Profiling :
- Temps d'exécution : 0.045s
- Mémoire utilisée : 2.5MB
- Appels de méthodes : 15

# Expliquer un échec
>>> phpunit:explain
💡 Analyse de l'échec :
Le test a échoué car $invoice->getTotal() retourne 0 au lieu de 100.
Causes possibles :
1. Les items de la facture ne sont pas correctement calculés
2. La méthode calculateTotal() n'est pas appelée
3. Les prix des items sont incorrects

Suggestions :
- Vérifier que $invoice->getItems() n'est pas vide
- Déboguer la méthode calculateTotal()
- Vérifier les données de test
```

#### Monitoring et métriques
```bash
# Monitoring en temps réel
>>> phpunit:monitor
📊 Monitoring actif :
- Tests exécutés : 12
- Temps moyen : 0.18s
- Succès rate : 85%
- Mémoire pic : 8.5MB

# Benchmark de performance
>>> phpunit:benchmark $invoiceService->generate($user), 1000
📊 Benchmark (1000 itérations) :
- Temps moyen : 0.025s
- Temps médian : 0.022s
- Temps min : 0.018s
- Temps max : 0.089s
- Écart type : 0.008s

# Comparer les performances
>>> phpunit:compare-performance 'invoice_generation_v1' vs 'invoice_generation_v2'
📊 Comparaison :
- v1 : 0.035s moyenne
- v2 : 0.025s moyenne
- Amélioration : 28.5%
```

### 6. Intégration avec les Tests Existants

#### Gestion des tests Symfony
```bash
# Lister les tests du projet
>>> phpunit:list-project
📋 Tests du projet :
- tests/Unit/Service/InvoiceServiceTest.php (5 tests)
- tests/Integration/Repository/InvoiceRepositoryTest.php (8 tests)
- tests/Functional/Controller/InvoiceControllerTest.php (12 tests)

# Exécuter un test spécifique
>>> phpunit:run-test tests/Unit/Service/InvoiceServiceTest.php::testGenerate
🧪 Exécution : InvoiceServiceTest::testGenerate
✅ Test réussi (0.12s)

# Importer un test dans la session
>>> phpunit:import tests/Unit/Service/InvoiceServiceTest.php::testGenerate
✅ Test importé dans la session interactive

# Créer un nouveau fichier de test
>>> phpunit:create-file tests/Unit/Service/NewServiceTest.php
✅ Fichier créé avec template par défaut
```

#### Fixtures et données de test
```bash
# Charger des fixtures
>>> phpunit:fixtures load
✅ Fixtures chargées : 150 entités

# Créer des données de test
>>> phpunit:factory User, 10
✅ 10 utilisateurs créés avec Factory

# Utiliser des builders
>>> phpunit:builder Invoice
>>> $invoice = InvoiceBuilder::create()->withTotal(100)->withStatus('paid')->build()
✅ Invoice créée avec Builder

# Snapshot des données
>>> phpunit:data-snapshot 'test_users' => User::findAll()
✅ Snapshot de données créé
```

### 7. Commandes Utilitaires

#### Nettoyage et maintenance
```bash
# Nettoyer les tests interactifs
>>> phpunit:clear
✅ Tests interactifs supprimés

# Nettoyer les mocks
>>> phpunit:clear-mocks
✅ Mocks supprimés

# Nettoyer les snapshots
>>> phpunit:clear-snapshots
✅ Snapshots supprimés

# Reset complet
>>> phpunit:reset
✅ Session PHPUnit réinitialisée
```

#### Export et sauvegarde
```bash
# Exporter un test interactif
>>> phpunit:export InvoiceServiceTest
✅ Test exporté vers tests/Generated/InvoiceServiceTest.php

# Sauvegarder la session
>>> phpunit:save-session my_session
✅ Session sauvegardée

# Charger une session
>>> phpunit:load-session my_session
✅ Session chargée

# Générer un rapport
>>> phpunit:report
📊 Rapport généré : var/phpunit-report.html
```

## Structure des fichiers à créer

### 1. Commandes PsySH
```
.psysh/PsyCommand/
├── PhpunitCommand.php (commande principale)
├── PhpunitCreateCommand.php
├── PhpunitAddCommand.php
├── PhpunitMockCommand.php
├── PhpunitAssertCommand.php
├── PhpunitRunCommand.php
├── PhpunitConfigCommand.php
└── PhpunitDebugCommand.php
```

### 2. Services de support
```
.psysh/Service/Phpunit/
├── InteractiveTestManager.php
├── MockManager.php
├── SnapshotManager.php
├── AssertionManager.php
├── ConfigurationManager.php
├── DebugManager.php
└── ReportManager.php
```

### 3. Modèles et entités
```
./psysh/Model/Phpunit/
├── InteractiveTest.php
├── TestMethod.php
├── MockDefinition.php
├── Snapshot.php
└── TestResult.php
```

### 4. Configuration
```
config/packages/
├── phpunit_shell.yaml
└── psysh.yaml
```

## Fonctionnalités à implémenter

### Phase 1 : Core
- [x] Création de tests interactifs
- [x] Ajout de méthodes de test
- [x] Assertions basiques
- [x] Exécution des tests

### Phase 2 : Mocks et Stubs
- [x] Création de mocks
- [x] Configuration des expectations
- [x] Vérification des appels
- [x] Spy et monitoring

### Phase 3 : Debugging
- [x] Traces d'exécution
- [x] Profiling
- [x] Explain des échecs
- [x] Mode debug

### Phase 4 : Intégration
- [x] Import/Export des tests
- [x] Intégration avec les tests existants
- [x] Configuration PHPUnit
- [x] Fixtures et données

### Phase 5 : Avancé
- [x] Snapshots
- [x] Benchmarking
- [x] Monitoring temps réel
- [x] Rapports et métriques

## Exemples d'utilisation complète

### Scénario 1 : Développement TDD
```bash
>>> phpunit:create App\Service\OrderService
>>> phpunit:add testCreateOrder
>>> phpunit:mock App\Repository\ProductRepository
>>> phpunit:expect $productRepository->findById(1)->willReturn($product)
>>> $orderService = new OrderService($productRepository)
>>> $result = $orderService->createOrder(['product_id' => 1, 'quantity' => 2])
>>> phpunit:snapshot 'order_creation' => $result
>>> phpunit:assert $result->getTotal() > 0
>>> phpunit:run
```

### Scénario 2 : Debug d'un test existant
```bash
>>> phpunit:import tests/Unit/Service/PaymentServiceTest.php::testProcessPayment
>>> phpunit:debug on
>>> phpunit:run
>>> phpunit:trace
>>> phpunit:explain
>>> phpunit:profile $paymentService->process($payment)
```

### Scénario 3 : Benchmark de performance
```bash
>>> phpunit:benchmark $service->heavyOperation(), 100
>>> phpunit:compare-performance 'before_optimization' vs 'after_optimization'
>>> phpunit:monitor
```

Cette intégration doit permettre un workflow de développement fluide où les développeurs peuvent créer, tester et déboguer leur code directement dans le shell interactif, avec toute la puissance de PHPUnit à portée de main.