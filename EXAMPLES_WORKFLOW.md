# 🧪 PHPUnit Extended Commands - Guide de Workflows

Ce guide présente des workflows complets pour utiliser efficacement les commandes PHPUnit dans PsySH.

## 🚀 Démarrage Rapide

```bash
# Démarrer PsySH avec la configuration PHPUnit
bin/psysh --config config/config.php

# Lister les commandes PHPUnit disponibles
>>> help phpunit

# Obtenir l'aide détaillée d'une commande
>>> phpunit:help create
```

## 📋 Workflows Principaux

### 1. 🏗️ **Création et Test d'un Service**

```php
// Créer un test pour une classe/service
>>> phpunit:create UserService
✅ Test créé : UserServiceTest (mode interactif)

// Vérifier que le test est créé
>>> phpunit:list
Tests actifs :
- UserService::UserServiceTest [0 lignes, 0 assertions]

// Ajouter du code au test
>>> $user = new User("John", "john@email.com")
>>> $userService = new UserService()

// Créer des assertions
>>> phpunit:assert true $user->isValid()
✅ Assertion réussie
📝 Assertion ajoutée au test UserService

>>> phpunit:assert equals $user->getName() "John"
✅ Assertion réussie
📝 Assertion ajoutée au test UserService

// Exécuter le test
>>> phpunit:run UserService
🧪 EXÉCUTION DU TEST: UserServiceTest
✅ Test terminé!
```

### 2. 🎭 **Workflow avec Mocks et Expectations**

```php
// Créer un test pour un service avec dépendances
>>> phpunit:create EmailService

// Créer un mock pour une dépendance
>>> phpunit:mock App\\Repository\\UserRepository userRepo
✅ Mock créé: $userRepo
🔧 Méthodes disponibles pour les expectations:
  • find()
  • save()
  • delete()

// Configurer les expectations
>>> phpunit:expect $userRepo->find(1)->willReturn($user)
✅ Expectation configurée
📝 Expectation ajoutée au test EmailService

>>> phpunit:expect $userRepo->save($user)->willReturn(true)
✅ Expectation configurée

// Tester le service avec les mocks
>>> $emailService = new EmailService($userRepo)
>>> $result = $emailService->sendWelcomeEmail(1)

// Vérifier le résultat
>>> phpunit:assert true $result
✅ Assertion réussie

// Exécuter le test complet
>>> phpunit:run EmailService
```

### 3. 📸 **Workflow avec Snapshots**

```php
// Créer un test
>>> phpunit:create DataProcessor

// Exécuter du code complexe
>>> $data = ['users' => [['id' => 1, 'name' => 'John'], ['id' => 2, 'name' => 'Jane']]]
>>> $processor = new DataProcessor()
>>> $result = $processor->transform($data)

// Créer un snapshot du résultat
>>> phpunit:snapshot result_snapshot $result
✅ Snapshot créé : result_snapshot
📋 Assertion générée:
$this->assertEquals($expectedResult, $result);

// Sauvegarder le snapshot dans un fichier
>>> phpunit:save-snapshot result_snapshot --path=tests/snapshots/
✅ Snapshot sauvegardé dans tests/snapshots/result_snapshot.php

// Réutiliser le snapshot dans d'autres tests
>>> phpunit:run DataProcessor
```

### 4. 🔍 **Workflow de Debug et Monitoring**

```php
// Créer un test avec debug activé
>>> phpunit:create Calculator
>>> phpunit:debug on
🐛 Mode debug activé

// Tester une fonction avec monitoring
>>> phpunit:monitor '$calculator = new Calculator(); $result = $calculator->divide(10, 2);'
🔄 Monitoring: $calculator = new Calculator(); $result = $calculator->divide(10, 2);
📊 Résultat: 5
⏱️ Temps d'exécution: 0.001s
💾 Variables créées: $calculator, $result

// Analyser une erreur
>>> phpunit:monitor '$result = $calculator->divide(10, 0);'
❌ Exception: Division by zero
🐛 Stack trace:
  Calculator->divide() line 25
  
// Utiliser le profiling
>>> phpunit:profile '$calculator->complexOperation()'
📈 Profile de performance:
  Temps total: 0.125s
  Mémoire: 2.1 MB
  Appels de fonction: 45

// Tracer l'exécution
>>> phpunit:trace '$calculator->divide(8, 2)'
🔍 Trace d'exécution:
  1. Calculator->divide(8, 2)
  2. Calculator->validateInput(8, 2)
  3. Calculator->performDivision(8, 2)
✅ Résultat: 4
```

### 5. ⚡ **Workflow de Performance et Benchmarking**

```php
// Créer un test de performance
>>> phpunit:create PerformanceTest

// Comparer différentes implémentations
>>> $dataSet = range(1, 1000)
>>> phpunit:benchmark 'array_map(fn($x) => $x * 2, $dataSet)' 'Algorithm A'
📊 Benchmark 'Algorithm A': 0.045ms (moyenne sur 100 itérations)

>>> phpunit:benchmark 'foreach($dataSet as &$item) $item *= 2;' 'Algorithm B'
📊 Benchmark 'Algorithm B': 0.032ms (moyenne sur 100 itérations)

// Comparer les performances
>>> phpunit:compare Algorithm_A Algorithm_B
📈 Comparaison de performance:
  Algorithm B est 29% plus rapide que Algorithm A
  ✅ Recommandation: Utiliser Algorithm B
```

### 6. 👁️ **Workflow avec Mode Watch (Développement Continu)**

```bash
# Démarrer en mode watch (dans un terminal séparé)
>>> phpunit:watch --paths=src,tests --filter=User
👁️ Mode watch activé - Les tests se relancent automatiquement...
📁 Surveillance: src
🧪 Tests: tests
⏱️ Intervalle: 1s
⌨️ Appuyez sur Ctrl+C pour arrêter

# Dans PsySH principal, continuer le développement
>>> phpunit:create UserValidator
>>> // Modifier le code source...
# 🔄 Changements détectés:
#   • UserValidator.php
# ✅ Tests re-exécutés automatiquement
```

### 7. 🎯 **Workflow de Test d'Intégration**

```php
// Créer un test d'intégration
>>> phpunit:create Integration\\OrderProcessingTest

// Setup avec plusieurs mocks
>>> phpunit:mock App\\Service\\PaymentService paymentService
>>> phpunit:mock App\\Service\\InventoryService inventoryService
>>> phpunit:mock App\\Service\\EmailService emailService

// Configurer les expectations complexes
>>> phpunit:expect $paymentService->charge(100)->willReturn(['success' => true, 'transaction_id' => 'tx123'])
>>> phpunit:expect $inventoryService->reserve('product123', 1)->willReturn(true)
>>> phpunit:expect $emailService->sendConfirmation()->willReturn(true)

// Tester le workflow complet
>>> $orderProcessor = new OrderProcessor($paymentService, $inventoryService, $emailService)
>>> $order = new Order('product123', 1, 100)
>>> $result = $orderProcessor->process($order)

// Vérifier le résultat final
>>> phpunit:assert true $result['success']
>>> phpunit:assert equals $result['transaction_id'] 'tx123'

// Exécuter tous les tests d'intégration
>>> phpunit:run Integration
```

### 8. 🚀 **Workflow de Test de Régression**

```php
// Créer un snapshot de l'état actuel
>>> $api = new ApiClient()
>>> $response = $api->getUser(123)
>>> phpunit:snapshot api_user_response $response

// Après modifications du code, vérifier la régression
>>> $newResponse = $api->getUser(123)
>>> phpunit:assert equals $newResponse $response "API response should not change"

// Tester plusieurs endpoints
>>> phpunit:create RegressionTest
>>> foreach([123, 456, 789] as $userId) {
...   $response = $api->getUser($userId);
...   phpunit:snapshot "user_${userId}" $response;
... }

// Exécuter tous les tests de régression
>>> phpunit:run RegressionTest
```

## 🛠️ **Commandes Utilitaires**

### Configuration et Gestion

```php
// Lister tous les tests disponibles
>>> phpunit:list

// Exporter un test vers un fichier
>>> phpunit:export UserServiceTest --path=tests/Unit/

// Afficher l'aide détaillée
>>> phpunit:help --command=mock

// Réinitialiser l'environnement de test
>>> phpunit:config --reset
```

### Debug et Inspection

```php
// Activer/désactiver le mode debug
>>> phpunit:debug on|off

// Expliquer pourquoi un test a échoué
>>> phpunit:explain UserServiceTest

// Afficher les variables du contexte actuel
>>> phpunit:debug vars

// Monitorer l'exécution d'une expression
>>> phpunit:monitor '$complex->operation()'
```

## 🎯 **Bonnes Pratiques**

### 1. **Nommage des Tests**
```php
// ✅ Bon
>>> phpunit:create UserAuthenticationService
>>> phpunit:create PaymentProcessorTest

// ❌ Éviter
>>> phpunit:create test
>>> phpunit:create MyTest
```

### 2. **Organisation des Mocks**
```php
// ✅ Grouper les mocks par fonctionnalité
>>> phpunit:mock App\\Repository\\UserRepository userRepo
>>> phpunit:mock App\\Service\\EmailService emailService
>>> phpunit:expect $userRepo->find(1)->willReturn($user)
>>> phpunit:expect $emailService->send()->willReturn(true)
```

### 3. **Utilisation des Snapshots**
```php
// ✅ Snapshots pour des données complexes
>>> phpunit:snapshot api_response $complexApiResponse
>>> phpunit:save-snapshot api_response --path=tests/fixtures/
```

### 4. **Mode Watch pour TDD**
```bash
# ✅ Développement TDD avec auto-reload
>>> phpunit:watch --filter=CurrentFeature
# Écrire le test → Voir l'échec → Implémenter → Voir le succès
```

## 🔧 **Résolution de Problèmes**

### Erreurs Communes

```php
// Test non trouvé
>>> phpunit:run NonExistentTest
❌ Test NonExistentTest non trouvé
💡 Solution: Vérifier avec phpunit:list

// Mock non configuré
>>> $mockService->someMethod()
❌ Method someMethod() not configured
💡 Solution: Ajouter phpunit:expect $mockService->someMethod()->willReturn($value)

// Expression invalide
>>> phpunit:assert invalid_expression
❌ Erreur dans l'expression: Parse error
💡 Solution: Vérifier la syntaxe PHP
```

## 📊 **Métriques et Rapports**

```php
// Exécuter tous les tests avec rapport
>>> phpunit:run-all --report

// Comparer les performances
>>> phpunit:compare-performance test1 test2

// Générer un rapport de couverture
>>> phpunit:coverage --output=html
```

---

**💡 Conseil**: Utilisez `phpunit:help [commande]` pour obtenir l'aide détaillée de chaque commande avec des exemples spécifiques à votre contexte.
