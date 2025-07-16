# Guide Complet des Commandes PHPUnit Extended pour PsySH

Ce guide présente toutes les commandes PHPUnit personnalisées disponibles dans cette extension PsySH, avec des exemples d'utilisation pratiques et des workflows complets.

## 🎆 Caractéristiques Principales

### 🆕 **Innovation : Syntaxe sans Guillemets**
```bash
# Nouvelle syntaxe révolutionnaire (SANS guillemets)
>>> phpunit:assert $result === 42
>>> phpunit:assert $user->getName() == "John"
>>> phpunit:assert count($items) > 0
>>> phpunit:assert $obj instanceof User

# Fonctionne avec toutes les expressions PHP complexes !
```

### 📊 **32+ Commandes Spécialisées**
- **Base** : `create`, `add`, `code`, `run`, `list`, `export`
- **Assertions** : `assert`, `eval`, `verify`, `explain` + 9 assertions typées
- **Mocks** : `mock`, `partial-mock`, `expect`, `spy`, `call-original`
- **Debug** : `debug`, `trace`, `profile`, `monitor`
- **Performance** : `benchmark`, `compare`, `compare-performance`
- **Avancées** : `watch`, `snapshot`, `config`, `help`
- **Projet** : `run-all`, `run-project`, `list-project`
- **Exceptions** : `expect-exception`, `expect-no-exception`

### ⚙️ **Fonctionnalités Avancées**
- 🚀 **Surveillance automatique** avec `phpunit:watch`
- 📊 **Benchmarking intégré** pour tests de performance
- 📸 **Snapshots** pour sauvegarder/restaurer l'état
- 🔍 **Debug interactif** avec traces détaillées
- 🎭 **Mocking avancé** avec spies et mocks partiels
- 📦 **Export vers fichiers** PHPUnit standard
- 📚 **Aide contextuelle** pour chaque commande

### 🔗 **Intégration Complète**
- Compatible avec **Symfony**, **Laravel**, **Doctrine**
- Auto-complétion intelligente
- Variables persistantes entre sessions
- Mode code interactif avec synchronisation
- Support des namespaces et autoload

### 🎨 **Interface Utilisateur**
- ✨ **Emojis informatifs** pour chaque action
- 🎨 **Coloration syntaxique** des résultats
- 📊 **Rapports détaillés** avec métriques
- ⚡ **Feedback temps réel** sur les performances

## 🎯 Table des Matières

1. [Commandes de Base](#commandes-de-base)
2. [Commandes de Test](#commandes-de-test) 
3. [Commandes de Mock](#commandes-de-mock)
4. [Commandes de Debug](#commandes-de-debug)
5. [Commandes Avancées](#commandes-avancées)
6. [Workflows Complets](#workflows-complets)

---

## 🚀 Commandes de Base

### `phpunit:create` - Créer un nouveau test

**Syntaxe :**
```bash
>>> phpunit:create ClassName
>>> phpunit:create App\Service\UserService
>>> phpunit:create My\Domain\Calculator
```

**Usage avec expressions sans guillemets :**
```bash
# Création basique
>>> phpunit:create UserService

# Avec namespace complet
>>> phpunit:create App\Service\EmailService

# Pour un contrôleur
>>> phpunit:create App\Controller\ApiController
```

**Exemples pratiques :**
```bash
# Créer un test pour un service
>>> phpunit:create App\Service\PaymentService
✅ Test créé : PaymentServiceTest (mode interactif)

# Créer un test pour un repository
>>> phpunit:create App\Repository\UserRepository
✅ Test créé : UserRepositoryTest (mode interactif)

# Créer un test pour une classe utilitaire
>>> phpunit:create App\Utils\StringHelper
✅ Test créé : StringHelperTest (mode interactif)
```

### `phpunit:list` - Lister tous les tests

**Syntaxe :**
```bash
>>> phpunit:list
>>> phpunit:list --filter=User
>>> phpunit:list --directory=tests/Unit
```

**Exemples :**
```bash
# Lister tous les tests
>>> phpunit:list
Tests actifs :
- UserServiceTest::testCreateUser [5 lignes, 3 assertions]
- PaymentServiceTest::testProcessPayment [8 lignes, 5 assertions]

# Filtrer par nom
>>> phpunit:list --filter=User
Tests actifs :
- UserServiceTest::testCreateUser [5 lignes, 3 assertions]
- UserRepositoryTest::testFindUser [3 lignes, 2 assertions]
```

### `phpunit:run` - Exécuter un test

**Syntaxe :**
```bash
>>> phpunit:run
>>> phpunit:run TestName
>>> phpunit:run UserTest::testLogin
```

**Exemples :**
```bash
# Exécuter le test courant
>>> phpunit:run
🧪 EXÉCUTION DU TEST: UserServiceTest
✅ Test exécuté avec succès

# Exécuter un test spécifique
>>> phpunit:run UserTest::testLogin
🧪 EXÉCUTION DU TEST: UserTest::testLogin
✅ Toutes les assertions réussies
```

---

## 🧪 Commandes de Test

### `phpunit:assert` - Ajouter une assertion (SANS GUILLEMETS)

**Syntaxe moderne (recommandée) :**
```bash
>>> phpunit:assert $variable === expected_value
>>> phpunit:assert $user->getName() == "John"
>>> phpunit:assert count($items) > 0
>>> phpunit:assert $obj instanceof User
```

**Exemples pratiques :**
```bash
# Comparaisons strictes
>>> phpunit:assert $result === 42
✅ Assertion ajoutée : $result === 42

# Comparaisons de chaînes
>>> phpunit:assert $user->getName() == "John Doe"
✅ Assertion ajoutée : $user->getName() == "John Doe"

# Tests de type
>>> phpunit:assert $response instanceof JsonResponse
✅ Assertion ajoutée : $response instanceof JsonResponse

# Vérifications booléennes
>>> phpunit:assert !empty($data)
✅ Assertion ajoutée : !empty($data)

# Comparaisons numériques
>>> phpunit:assert $invoice->getTotal() >= 100.0
✅ Assertion ajoutée : $invoice->getTotal() >= 100.0

# Tests de contenu
>>> phpunit:assert isset($config['database'])
✅ Assertion ajoutée : isset($config['database'])
```

### `phpunit:eval` - Évaluer une expression avec analyse

**Syntaxe :**
```bash
>>> phpunit:eval 'expression_to_evaluate'
```

**Exemples :**
```bash
# Évaluer une expression simple
>>> phpunit:eval '$result === 42'
✅ Expression évaluée avec succès: $result === 42
📋 Résultat: true

# Évaluer avec détails d'échec
>>> phpunit:eval '$user->getAge() >= 18'
❌ Expression évaluée à false: $user->getAge() >= 18
Comparaison détaillée:
  Gauche: $user->getAge() = 16
  Droite: 18 = 18
  Opérateur: >=
```

### `phpunit:code` - Mode code interactif

**Syntaxe :**
```bash
>>> phpunit:code
```

**Exemple d'utilisation :**
```bash
>>> phpunit:code
🧪 Mode code activé pour le test: UserServiceTest
📋 Variables disponibles: $em (EntityManager), $container (Container)

# Vous entrez dans un shell interactif
phpunit:code> $user = new User();
phpunit:code> $user->setName("John");
phpunit:code> $user->setEmail("john@example.com");
phpunit:code> exit

✅ Mode code terminé.
✅ 3 ligne(s) de code ajoutée(s) au test
```

### `phpunit:add` - Ajouter une méthode de test

**Syntaxe :**
```bash
>>> phpunit:add methodName
>>> phpunit:add testCalculateTotal
>>> phpunit:add testValidateInput
```

**Exemples :**
```bash
# Ajouter une méthode de test
>>> phpunit:add testCreateUser
✅ Méthode testCreateUser ajoutée

# Ajouter une méthode avec nom descriptif
>>> phpunit:add testValidateEmailFormat
✅ Méthode testValidateEmailFormat ajoutée

# Ajouter plusieurs méthodes
>>> phpunit:add testCalculateDiscount
>>> phpunit:add testApplyTaxes
>>> phpunit:add testGenerateInvoice
✅ 3 méthodes ajoutées au test
```

### `phpunit:verify` - Vérifier les assertions

**Syntaxe :**
```bash
>>> phpunit:verify
>>> phpunit:verify --detailed
```

**Exemples :**
```bash
# Vérification rapide
>>> phpunit:verify
📊 Vérification des assertions:
  ✅ 5 assertions valides
  ❌ 1 assertion échouée
  
# Vérification détaillée
>>> phpunit:verify --detailed
📊 Analyse détaillée:
  ✅ $user->getName() === "John": PASSED
  ✅ $user->getAge() >= 18: PASSED
  ❌ $user->isActive() === true: FAILED (got false)
```

### `phpunit:explain` - Expliquer une assertion

**Syntaxe :**
```bash
>>> phpunit:explain assertion_expression
>>> phpunit:explain $result === 42
```

**Exemples :**
```bash
# Expliquer une assertion
>>> phpunit:explain $user->getName() === "John"
📚 Explication de l'assertion:
  • Type: Comparaison stricte (===)
  • Côté gauche: $user->getName() (méthode de User)
  • Côté droit: "John" (chaîne de caractères)
  • PHPUnit: $this->assertSame("John", $user->getName())
  • Objectif: Vérifier que le nom de l'utilisateur est exactement "John"
```

## 📎 Commandes d'Assertion Typées

### `phpunit:assert-type` - Vérifier le type

**Syntaxe :**
```bash
>>> phpunit:assert-type type expression
>>> phpunit:assert-type string $user->getName()
>>> phpunit:assert-type array $config
```

**Exemples :**
```bash
# Vérifier le type string
>>> phpunit:assert-type string $user->getName()
✅ Type correct: string

# Vérifier le type array
>>> phpunit:assert-type array $user->getPermissions()
✅ Type correct: array

# Vérifier le type object
>>> phpunit:assert-type object $user->getProfile()
✅ Type correct: object
```

### `phpunit:assert-instance` - Vérifier l'instance

**Syntaxe :**
```bash
>>> phpunit:assert-instance ClassName expression
>>> phpunit:assert-instance User $user
>>> phpunit:assert-instance JsonResponse $response
```

**Exemples :**
```bash
# Vérifier instance de classe
>>> phpunit:assert-instance User $user
✅ Instance correcte: App\Entity\User

# Vérifier instance de response
>>> phpunit:assert-instance JsonResponse $response
✅ Instance correcte: Symfony\Component\HttpFoundation\JsonResponse
```

### `phpunit:assert-count` - Vérifier le nombre d'éléments

**Syntaxe :**
```bash
>>> phpunit:assert-count expected_count expression
>>> phpunit:assert-count 5 $items
>>> phpunit:assert-count 0 $errors
```

**Exemples :**
```bash
# Vérifier le nombre d'éléments
>>> phpunit:assert-count 3 $user->getRoles()
✅ Nombre correct: 3 éléments

# Vérifier tableau vide
>>> phpunit:assert-count 0 $errors
✅ Nombre correct: 0 éléments (tableau vide)
```

### `phpunit:assert-empty` - Vérifier si vide

**Syntaxe :**
```bash
>>> phpunit:assert-empty expression
>>> phpunit:assert-empty $errors
>>> phpunit:assert-empty $user->getOptionalField()
```

**Exemples :**
```bash
# Vérifier que le tableau est vide
>>> phpunit:assert-empty $errors
✅ Variable vide: tableau avec 0 éléments

# Vérifier qu'une chaîne est vide
>>> phpunit:assert-empty $user->getMiddleName()
✅ Variable vide: chaîne vide
```

### `phpunit:assert-not-empty` - Vérifier si non vide

**Syntaxe :**
```bash
>>> phpunit:assert-not-empty expression
>>> phpunit:assert-not-empty $user->getName()
>>> phpunit:assert-not-empty $results
```

**Exemples :**
```bash
# Vérifier que la variable n'est pas vide
>>> phpunit:assert-not-empty $user->getName()
✅ Variable non vide: "John Doe"

# Vérifier que le tableau n'est pas vide
>>> phpunit:assert-not-empty $searchResults
✅ Variable non vide: tableau avec 5 éléments
```

### `phpunit:assert-true` - Vérifier si vrai

**Syntaxe :**
```bash
>>> phpunit:assert-true expression
>>> phpunit:assert-true $user->isActive()
>>> phpunit:assert-true $payment->isSuccessful()
```

**Exemples :**
```bash
# Vérifier qu'une condition est vraie
>>> phpunit:assert-true $user->isActive()
✅ Expression vraie: $user->isActive() retourne true

# Vérifier un état
>>> phpunit:assert-true $order->isPaid()
✅ Expression vraie: $order->isPaid() retourne true
```

### `phpunit:assert-false` - Vérifier si faux

**Syntaxe :**
```bash
>>> phpunit:assert-false expression
>>> phpunit:assert-false $user->isBlocked()
>>> phpunit:assert-false $validation->hasErrors()
```

**Exemples :**
```bash
# Vérifier qu'une condition est fausse
>>> phpunit:assert-false $user->isBlocked()
✅ Expression fausse: $user->isBlocked() retourne false

# Vérifier absence d'erreurs
>>> phpunit:assert-false $validation->hasErrors()
✅ Expression fausse: aucune erreur de validation
```

### `phpunit:assert-null` - Vérifier si null

**Syntaxe :**
```bash
>>> phpunit:assert-null expression
>>> phpunit:assert-null $user->getDeletedAt()
>>> phpunit:assert-null $cache->get('nonexistent')
```

**Exemples :**
```bash
# Vérifier qu'une valeur est null
>>> phpunit:assert-null $user->getDeletedAt()
✅ Variable null: $user->getDeletedAt() est null (utilisateur actif)

# Vérifier cache manquant
>>> phpunit:assert-null $cache->get('missing_key')
✅ Variable null: clé de cache inexistante
```

### `phpunit:assert-not-null` - Vérifier si non null

**Syntaxe :**
```bash
>>> phpunit:assert-not-null expression
>>> phpunit:assert-not-null $user->getId()
>>> phpunit:assert-not-null $response->getContent()
```

**Exemples :**
```bash
# Vérifier qu'une valeur n'est pas null
>>> phpunit:assert-not-null $user->getId()
✅ Variable non null: $user->getId() = 123

# Vérifier contenu de réponse
>>> phpunit:assert-not-null $response->getContent()
✅ Variable non null: contenu de réponse présent
```

## ⚠️ Commandes d'Exception

### `phpunit:expect-exception` - Attendre une exception

**Syntaxe :**
```bash
>>> phpunit:expect-exception ClassName expression
>>> phpunit:expect-exception InvalidArgumentException $service->process(null)
>>> phpunit:expect-exception \Exception $service->riskyOperation()
```

**Exemples :**
```bash
# Attendre une exception spécifique
>>> phpunit:expect-exception InvalidArgumentException $validator->validate(null)
✅ Exception attendue 'InvalidArgumentException' capturée

# Attendre une exception avec message
>>> phpunit:expect-exception --message="Invalid email" ValidationException $validator->validateEmail("invalid")
✅ Exception attendue 'ValidationException' capturée
✅ Message d'exception attendu: 'Invalid email'
```

### `phpunit:expect-no-exception` - Aucune exception attendue

**Syntaxe :**
```bash
>>> phpunit:expect-no-exception expression
>>> phpunit:expect-no-exception $service->safeOperation()
```

**Exemples :**
```bash
# Vérifier qu'aucune exception n'est lancée
>>> phpunit:expect-no-exception $user->getName()
✅ Aucune exception lancée

# Vérifier opération sécurisée
>>> phpunit:expect-no-exception $service->processValidData($validData)
✅ Aucune exception lancée
```

---

## 🎭 Commandes de Mock

### `phpunit:mock` - Créer un mock

**Syntaxe :**
```bash
>>> phpunit:mock ClassName
>>> phpunit:mock ClassName variableName
>>> phpunit:mock ClassName --methods=method1,method2
>>> phpunit:mock ClassName --partial
```

**Exemples :**
```bash
# Mock simple avec nom auto-généré
>>> phpunit:mock App\Service\EmailService
✅ Mock créé: $emailServiceMock
📋 Code généré:
$emailServiceMock = $this->createMock(App\Service\EmailService::class);

# Mock avec nom personnalisé
>>> phpunit:mock App\Service\EmailService emailSender
✅ Mock créé: $emailSender
📋 Code généré:
$emailSender = $this->createMock(App\Service\EmailService::class);

# Mock partiel avec méthodes spécifiques
>>> phpunit:mock App\Repository\UserRepository --methods=find,save
✅ Mock créé: $userRepositoryMock
🔧 Méthodes disponibles pour les expectations:
  • find
  • save
  • delete
  • findBy
```

### `phpunit:expect` - Configurer les expectations

**Syntaxe :**
```bash
>>> phpunit:expect $mock->method()->willReturn($value)
>>> phpunit:expect $mock->method()->expects($this->once())
```

**Exemples :**
```bash
# Expectation simple
>>> phpunit:expect $emailServiceMock->send()->willReturn(true)
✅ Expectation configurée
📋 Expectation: $emailServiceMock->send()->willReturn(true)

# Expectation avec paramètres
>>> phpunit:expect $userRepositoryMock->find(1)->willReturn($user)
✅ Expectation configurée
📝 Expectation ajoutée au test UserServiceTest

# Expectation de nombre d'appels
>>> phpunit:expect $emailServiceMock->send()->expects($this->once())
✅ Expectation configurée
```

### `phpunit:spy` - Créer un spy

**Syntaxe :**
```bash
>>> phpunit:spy ClassName
>>> phpunit:spy ClassName methodName
```

**Exemples :**
```bash
# Spy complet
>>> phpunit:spy App\Service\LoggerService
✅ Spy créé: $loggerServiceSpy
📋 Toutes les méthodes sont espionnées

# Spy pour une méthode spécifique
>>> phpunit:spy App\Service\EmailService send
✅ Spy créé pour la méthode: send
📋 Vous pouvez vérifier les appels avec: $this->assertEquals(1, $spy->getCallCount())
```

### `phpunit:partial-mock` - Créer un mock partiel

**Syntaxe :**
```bash
>>> phpunit:partial-mock ClassName methods
>>> phpunit:partial-mock App\Service\FileService read,write
```

**Exemples :**
```bash
# Mock partiel gardant certaines méthodes originales
>>> phpunit:partial-mock App\Service\FileService read,write
✅ Mock partiel créé: $fileServiceMock
📋 Méthodes mockées: read, write
📋 Autres méthodes conservent leur comportement original

# Mock partiel simple
>>> phpunit:partial-mock App\Utils\Calculator calculate
✅ Mock partiel créé: $calculatorMock
📋 Seule la méthode 'calculate' est mockée
```

---

## 🔍 Commandes de Debug

### `phpunit:debug` - Mode debug

**Syntaxe :**
```bash
>>> phpunit:debug
>>> phpunit:debug on
>>> phpunit:debug off
>>> phpunit:debug status
```

**Exemples :**
```bash
# Activer le debug
>>> phpunit:debug on
✅ Mode debug activé
🔧 Configuration debug:
  • Traces activées: ✅
  • Profiling activé: ✅
  • Analyse d'erreurs: ✅
  • Logging étendu: ✅

# Vérifier le statut
>>> phpunit:debug status
📊 Statut du mode debug:
  • Mode debug: ACTIVÉ
📈 Statistiques debug:
  • Tests tracés: 5
  • Erreurs capturées: 2
  • Sessions de profiling: 3
```

### `phpunit:trace` - Analyser les traces

**Syntaxe :**
```bash
>>> phpunit:trace
>>> phpunit:trace --detailed
>>> phpunit:trace --last-error
```

**Exemples :**
```bash
# Trace du dernier échec
>>> phpunit:trace
🔍 Trace du dernier échec:
  Method: testUserCreation
  File: UserServiceTest.php:45
  Error: Assertion failed: expected true, got false

# Trace détaillée
>>> phpunit:trace --detailed
🔍 Trace détaillée:
  Stack trace:
    1. UserServiceTest::testUserCreation() at line 45
    2. UserService::createUser() at line 23
    3. UserRepository::save() at line 78
```

### `phpunit:profile` - Profiler les performances

**Syntaxe :**
```bash
>>> phpunit:profile
>>> phpunit:profile start
>>> phpunit:profile stop
>>> phpunit:profile report
```

**Exemples :**
```bash
# Démarrer le profiling
>>> phpunit:profile start
✅ Profiling activé

# Arrêter et obtenir le rapport
>>> phpunit:profile stop
✅ Profiling arrêté
📊 Rapport de performance:
  • Temps d'exécution: 0.045s
  • Mémoire utilisée: 2.3MB
  • Nombre d'assertions: 12
```

---

## ⚙️ Commandes Avancées

### `phpunit:export` - Exporter les tests

**Syntaxe :**
```bash
>>> phpunit:export
>>> phpunit:export --format=file
>>> phpunit:export --path=tests/Generated
```

**Exemples :**
```bash
# Exporter le test courant vers un fichier
>>> phpunit:export
✅ Test exporté vers: tests/UserServiceTest.php
📋 Contenu: 1 classe, 3 méthodes, 8 assertions

# Exporter avec chemin personnalisé
>>> phpunit:export --path=tests/Unit
✅ Test exporté vers: tests/Unit/UserServiceTest.php

# Exporter avec format spécifique
>>> phpunit:export --format=xml
✅ Test exporté vers: tests/UserServiceTest.xml (format PHPUnit XML)
```

### `phpunit:config` - Configuration PHPUnit

**Syntaxe :**
```bash
>>> phpunit:config
>>> phpunit:config --bootstrap=bootstrap.php
>>> phpunit:config --testdox
```

**Exemples :**
```bash
# Afficher la configuration actuelle
>>> phpunit:config
📊 Configuration PHPUnit:
  • Bootstrap: bootstrap.php
  • Testdox: activé
  • Colors: activé
  • Répertoire tests: tests/

# Modifier le bootstrap
>>> phpunit:config --bootstrap=tests/bootstrap.php
✅ Bootstrap mis à jour: tests/bootstrap.php

# Activer le mode testdox
>>> phpunit:config --testdox
✅ Mode testdox activé (sortie lisible)
```

### `phpunit:snapshot` - Gestion des snapshots

**Syntaxe :**
```bash
>>> phpunit:snapshot save name
>>> phpunit:snapshot restore name
>>> phpunit:snapshot list
>>> phpunit:snapshot delete name
```

**Exemples :**
```bash
# Sauvegarder l'état actuel
>>> phpunit:snapshot save before_refactoring
✅ Snapshot sauvegardé: before_refactoring
📋 Contenus: 3 tests, 15 assertions, 8 mocks
📅 Date: 2025-07-10 23:15:00

# Lister les snapshots
>>> phpunit:snapshot list
📋 Snapshots disponibles:
  • before_refactoring (2025-07-10 23:15:00) - 3 tests
  • stable_state (2025-07-10 22:30:00) - 2 tests
  • initial_setup (2025-07-10 21:45:00) - 1 test

# Restaurer un snapshot
>>> phpunit:snapshot restore before_refactoring
✅ Snapshot restauré: before_refactoring
📋 3 tests restaurés avec succès
📋 15 assertions restaurées
📋 8 mocks restaurés

# Supprimer un snapshot
>>> phpunit:snapshot delete old_version
✅ Snapshot supprimé: old_version
```

### `phpunit:monitor` - Surveillance en temps réel

**Syntaxe :**
```bash
>>> phpunit:monitor
>>> phpunit:monitor --interval=500
>>> phpunit:monitor --alerts
```

**Exemples :**
```bash
# Démarrer la surveillance
>>> phpunit:monitor
👁️ Surveillance PHPUnit démarrée...
📊 Statistiques en temps réel:
  • Tests exécutés: 15
  • Assertions réussies: 142
  • Échecs: 2
  • Temps total: 3.45s

# Surveillance avec alertes
>>> phpunit:monitor --alerts
👁️ Surveillance avec alertes activée
🔔 Alerte: Test UserServiceTest::testLogin a échoué
🔔 Alerte: Performance dégradée (>2s par test)
```

### `phpunit:call-original` - Appeler les méthodes originales

**Syntaxe :**
```bash
>>> phpunit:call-original mockVariable methodName
>>> phpunit:call-original $userMock setName
```

**Exemples :**
```bash
# Permettre l'appel de la méthode originale
>>> phpunit:call-original $userServiceMock calculateTotal
✅ Méthode originale 'calculateTotal' sera appelée
📋 Le mock laissera passer les appels à cette méthode

# Configurer plusieurs méthodes
>>> phpunit:call-original $repositoryMock find,save
✅ Méthodes originales configurées: find, save
```

### `phpunit:temp-config` - Configuration temporaire

**Syntaxe :**
```bash
>>> phpunit:temp-config setting value
>>> phpunit:temp-config debug true
>>> phpunit:temp-config timeout 30
```

**Exemples :**
```bash
# Configuration temporaire du debug
>>> phpunit:temp-config debug true
✅ Configuration temporaire: debug = true
⚠️ Cette configuration sera perdue à la fin de la session

# Configuration du timeout
>>> phpunit:temp-config timeout 60
✅ Timeout temporaire: 60 secondes

# Voir les configurations temporaires
>>> phpunit:temp-config --list
📋 Configurations temporaires actives:
  • debug: true
  • timeout: 60
  • verbose: false
```

### `phpunit:restore-config` - Restaurer la configuration

**Syntaxe :**
```bash
>>> phpunit:restore-config
>>> phpunit:restore-config --default
```

**Exemples :**
```bash
# Restaurer la configuration par défaut
>>> phpunit:restore-config
✅ Configuration restaurée aux valeurs par défaut
📋 Toutes les configurations temporaires ont été supprimées

# Restaurer avec confirmation
>>> phpunit:restore-config --default
⚠️ Voulez-vous vraiment restaurer la configuration par défaut? (y/N)
>>> y
✅ Configuration par défaut restaurée
```

### `phpunit:run-all` - Exécuter tous les tests

**Syntaxe :**
```bash
>>> phpunit:run-all
>>> phpunit:run-all --parallel
>>> phpunit:run-all --stop-on-failure
```

**Exemples :**
```bash
# Exécuter tous les tests disponibles
>>> phpunit:run-all
🚀 Exécution de tous les tests...
📊 Progression: [████████████████████] 100% (15/15)
✅ Résultats: 13 réussis, 2 échecs
⏱️ Temps total: 5.23s

# Exécution parallèle
>>> phpunit:run-all --parallel
🚀 Exécution parallèle (4 processus)...
📊 Progression: [████████████████████] 100% (15/15)
✅ Résultats: 15 réussis, 0 échecs
⏱️ Temps total: 1.45s (3.6x plus rapide)

# Arrêt au premier échec
>>> phpunit:run-all --stop-on-failure
🚀 Exécution avec arrêt au premier échec...
❌ Arrêt: échec détecté dans UserServiceTest::testLogin
📊 Tests exécutés: 8/15
```

### `phpunit:run-project` - Exécuter tests d'un projet

**Syntaxe :**
```bash
>>> phpunit:run-project projectName
>>> phpunit:run-project myapp --config=phpunit.xml
```

**Exemples :**
```bash
# Exécuter les tests d'un projet spécifique
>>> phpunit:run-project ecommerce
🚀 Exécution des tests du projet: ecommerce
📁 Répertoire: /path/to/ecommerce
📊 Tests trouvés: 45
✅ Résultats: 43 réussis, 2 échecs

# Avec configuration personnalisée
>>> phpunit:run-project api --config=phpunit-integration.xml
🚀 Projet: api (configuration: phpunit-integration.xml)
📊 Tests d'intégration: 12 réussis
```

### `phpunit:list-project` - Lister les projets

**Syntaxe :**
```bash
>>> phpunit:list-project
>>> phpunit:list-project --detailed
```

**Exemples :**
```bash
# Lister tous les projets
>>> phpunit:list-project
📋 Projets PHPUnit disponibles:
  • ecommerce (45 tests)
  • api (12 tests)
  • frontend (8 tests)
  • shared (23 tests)

# Vue détaillée
>>> phpunit:list-project --detailed
📋 Projets détaillés:
  📁 ecommerce (/path/to/ecommerce)
    • Tests: 45 (38 unit, 7 integration)
    • Configuration: phpunit.xml
    • Dernier run: 2025-07-10 23:00:00
    • Statut: ✅ Tous les tests passent
```

### `phpunit:help` - Aide personnalisée

**Syntaxe :**
```bash
>>> phpunit:help
>>> phpunit:help commandName
>>> phpunit:help --examples
```

**Exemples :**
```bash
# Aide générale
>>> phpunit:help
📚 Aide PHPUnit Extended
🎯 Commandes disponibles:
  • Tests: create, run, assert, eval
  • Mocks: mock, expect, spy
  • Debug: debug, trace, profile
  • Avancées: watch, benchmark, snapshot

# Aide sur une commande spécifique
>>> phpunit:help assert
📚 Aide détaillée: phpunit:assert
[... aide complète de la commande ...]

# Exemples rapides
>>> phpunit:help --examples
💡 Exemples courants:
  • Créer un test: phpunit:create UserService
  • Ajouter assertion: phpunit:assert $result === 42
  • Créer un mock: phpunit:mock EmailService
  • Déboguer: phpunit:debug on
```

### `phpunit:watch` - Surveillance automatique

**Syntaxe :**
```bash
>>> phpunit:watch
>>> phpunit:watch --paths=src,tests
>>> phpunit:watch --filter=UserTest
>>> phpunit:watch --delay=500
```

**Exemples :**
```bash
# Surveillance basique
>>> phpunit:watch
👁️ Mode watch activé - Les tests se relancent automatiquement...
📁 Surveillance: src
🧪 Tests: tests
⏱️ Intervalle: 1s
⌨️ Appuyez sur Ctrl+C pour arrêter

🔄 Changements détectés:
  • UserService.php

🧪 EXÉCUTION DU TEST: UserServiceTest
✅ Test exécuté avec succès
```

### `phpunit:benchmark` - Tests de performance

**Syntaxe :**
```bash
>>> phpunit:benchmark expression iterations
>>> phpunit:benchmark '$service->processData($data)' 1000
```

**Exemples :**
```bash
# Benchmark d'une méthode
>>> phpunit:benchmark '$userService->createUser($userData)' 100
🚀 Benchmark: 100 itérations
⏱️ Temps moyen: 0.023s
⚡ Opérations/seconde: 43.48
📊 Mémoire moyenne: 1.2MB
```

### `phpunit:compare` - Comparer les performances

**Syntaxe :**
```bash
>>> phpunit:compare 'expression1' 'expression2'
>>> phpunit:compare 'old_method()' 'new_method()' --iterations=1000
```

**Exemples :**
```bash
# Comparer deux implémentations
>>> phpunit:compare '$service->oldMethod()' '$service->newMethod()' --iterations=500
📊 Comparaison de performance:
  Expression 1: $service->oldMethod()
    • Temps moyen: 0.045s
    • Mémoire: 2.1MB
  
  Expression 2: $service->newMethod()
    • Temps moyen: 0.023s
    • Mémoire: 1.8MB
  
  🏆 Gagnant: Expression 2 (2x plus rapide)
```

### `phpunit:snapshot` - Sauvegarder l'état

**Syntaxe :**
```bash
>>> phpunit:snapshot save name
>>> phpunit:snapshot restore name
>>> phpunit:snapshot list
```

**Exemples :**
```bash
# Sauvegarder l'état actuel
>>> phpunit:snapshot save before_refactoring
✅ Snapshot sauvegardé: before_refactoring
📋 Contenus: 3 tests, 15 assertions, 8 mocks

# Restaurer un état
>>> phpunit:snapshot restore before_refactoring
✅ Snapshot restauré: before_refactoring
📋 3 tests restaurés avec succès
```

---

## 📋 Workflows Complets

### 1. Workflow TDD (Test-Driven Development)

```bash
# 1. Créer un nouveau test
>>> phpunit:create App\Service\PaymentService
✅ Test créé : PaymentServiceTest (mode interactif)

# 2. Ajouter des assertions pour définir le comportement attendu
>>> phpunit:assert $result instanceof PaymentResult
>>> phpunit:assert $result->isSuccessful() === true
>>> phpunit:assert $result->getTransactionId() !== null

# 3. Exécuter le test (qui doit échouer)
>>> phpunit:run
❌ Test échoué: PaymentServiceTest
📋 Erreur: Class 'App\Service\PaymentService' not found

# 4. Implémenter le service minimal
>>> phpunit:code
phpunit:code> class PaymentService {
phpunit:code>   public function process($amount) {
phpunit:code>     return new PaymentResult(true, 'TXN123');
phpunit:code>   }
phpunit:code> }
phpunit:code> exit

# 5. Relancer le test
>>> phpunit:run
✅ Test exécuté avec succès
```

### 2. Workflow avec Mocks

```bash
# 1. Créer un test qui nécessite des dépendances
>>> phpunit:create App\Service\OrderService
✅ Test créé : OrderServiceTest (mode interactif)

# 2. Créer les mocks nécessaires
>>> phpunit:mock App\Repository\ProductRepository productRepo
>>> phpunit:mock App\Service\PaymentService paymentService
>>> phpunit:mock App\Service\EmailService emailService

# 3. Configurer les expectations
>>> phpunit:expect $productRepo->find(1)->willReturn($product)
>>> phpunit:expect $paymentService->charge(100.0)->willReturn(true)
>>> phpunit:expect $emailService->sendConfirmation()->expects($this->once())

# 4. Ajouter le code du test
>>> phpunit:code
phpunit:code> $orderService = new OrderService($productRepo, $paymentService, $emailService);
phpunit:code> $order = $orderService->createOrder(1, 100.0);
phpunit:code> exit

# 5. Ajouter les assertions
>>> phpunit:assert $order instanceof Order
>>> phpunit:assert $order->getStatus() === 'confirmed'
>>> phpunit:assert $order->getTotal() === 100.0

# 6. Exécuter le test
>>> phpunit:run
✅ Test exécuté avec succès
```

### 3. Workflow de Debug

```bash
# 1. Activer le mode debug
>>> phpunit:debug on
✅ Mode debug activé

# 2. Exécuter un test qui échoue
>>> phpunit:run UserServiceTest
❌ Test échoué: UserServiceTest
📋 3 assertions réussies, 1 échec

# 3. Analyser la trace
>>> phpunit:trace
🔍 Trace du dernier échec:
  Method: testUserCreation
  File: UserServiceTest.php:45
  Error: Assertion failed: expected 'John', got 'Jane'

# 4. Analyser les variables
>>> phpunit:debug vars
📊 Variables au moment de l'échec:
  $user->getName(): "Jane"
  $expectedName: "John"
  
# 5. Corriger le test ou le code
>>> phpunit:assert $user->getName() === "Jane"
✅ Assertion mise à jour

# 6. Relancer le test
>>> phpunit:run
✅ Test exécuté avec succès
```

### 4. Workflow de Performance

```bash
# 1. Créer un benchmark de référence
>>> phpunit:benchmark '$service->processLargeDataset($data)' 100
🚀 Benchmark: 100 itérations
⏱️ Temps moyen: 0.523s
📊 Mémoire moyenne: 15.2MB

# 2. Sauvegarder l'état avant optimisation
>>> phpunit:snapshot save before_optimization
✅ Snapshot sauvegardé: before_optimization

# 3. Optimiser le code
>>> phpunit:code
phpunit:code> // Implémenter l'optimisation
phpunit:code> exit

# 4. Comparer les performances
>>> phpunit:compare '$service->processLargeDataset($data)' '$service->processLargeDatasetOptimized($data)' --iterations=100
📊 Comparaison de performance:
  🏆 Gagnant: processLargeDatasetOptimized (3.2x plus rapide)

# 5. Ajouter un test de performance
>>> phpunit:assert $this->benchmark($service->processLargeDatasetOptimized($data)) < 0.200
✅ Assertion de performance ajoutée
```

### 5. Workflow avec Surveillance

```bash
# 1. Démarrer la surveillance
>>> phpunit:watch --paths=src/Service --filter=UserTest
👁️ Mode watch activé...
📁 Surveillance: src/Service
🧪 Tests: UserTest

# 2. Modifier le code source
# (Les tests se relancent automatiquement)

🔄 Changements détectés:
  • UserService.php

🧪 EXÉCUTION DU TEST: UserTest
✅ Test exécuté avec succès

# 3. Modifier un test
🔄 Changements détectés:
  • UserTest.php

🧪 EXÉCUTION DU TEST: UserTest
❌ Test échoué: assertion failed

# 4. Corriger rapidement
🔄 Changements détectés:
  • UserService.php

🧪 EXÉCUTION DU TEST: UserTest
✅ Test exécuté avec succès
```

---

## 🎯 Conseils et Bonnes Pratiques

### Syntaxe des Expressions

**✅ Recommandé (sans guillemets) :**
```bash
>>> phpunit:assert $result === 42
>>> phpunit:assert $user->getName() == "John"
>>> phpunit:assert count($items) > 0
>>> phpunit:assert $obj instanceof User
```

**⚠️ Ancienne syntaxe (encore supportée) :**
```bash
>>> phpunit:assert '$result === 42'
>>> phpunit:assert '$user->getName() == "John"'
```

### Organisation des Tests

```bash
# Créer des tests organisés par fonctionnalité
>>> phpunit:create App\Service\User\UserCreationService
>>> phpunit:create App\Service\User\UserUpdateService
>>> phpunit:create App\Service\User\UserDeletionService

# Utiliser des groupes et des filtres
>>> phpunit:list --filter=User
>>> phpunit:list --group=integration
```

### Gestion des Mocks

```bash
# Créer des mocks avec des noms explicites
>>> phpunit:mock App\Service\EmailService emailSender
>>> phpunit:mock App\Repository\UserRepository userRepo

# Utiliser des expectations claires
>>> phpunit:expect $emailSender->send()->willReturn(true)
>>> phpunit:expect $userRepo->find(1)->willReturn($user)
```

### Debug et Performance

```bash
# Toujours activer le debug lors du développement
>>> phpunit:debug on

# Utiliser le profiling pour optimiser
>>> phpunit:profile start
>>> phpunit:run
>>> phpunit:profile report

# Sauvegarder les états importants
>>> phpunit:snapshot save stable_state
```

---

## 📋 Index Complet des Commandes

### Commandes de Base
| Commande | Description | Syntaxe |
|----------|-------------|----------|
| `phpunit:create` | Créer un nouveau test | `phpunit:create ClassName` |
| `phpunit:add` | Ajouter une méthode de test | `phpunit:add testMethodName` |
| `phpunit:code` | Mode code interactif | `phpunit:code` |
| `phpunit:run` | Exécuter un test | `phpunit:run [TestName]` |
| `phpunit:list` | Lister tous les tests | `phpunit:list` |
| `phpunit:export` | Exporter vers fichier | `phpunit:export [--path=dir]` |

### Commandes d'Assertion
| Commande | Description | Syntaxe |
|----------|-------------|----------|
| `phpunit:assert` | **Assertion sans guillemets** | `phpunit:assert $var === value` |
| `phpunit:eval` | Évaluer avec analyse | `phpunit:eval 'expression'` |
| `phpunit:verify` | Vérifier assertions | `phpunit:verify [--detailed]` |
| `phpunit:explain` | Expliquer assertion | `phpunit:explain expression` |

### Commandes d'Assertion Typées
| Commande | Description | Syntaxe |
|----------|-------------|----------|
| `phpunit:assert-type` | Vérifier le type | `phpunit:assert-type type $var` |
| `phpunit:assert-instance` | Vérifier instance | `phpunit:assert-instance Class $obj` |
| `phpunit:assert-count` | Vérifier nombre | `phpunit:assert-count N $array` |
| `phpunit:assert-empty` | Vérifier si vide | `phpunit:assert-empty $var` |
| `phpunit:assert-not-empty` | Vérifier si non vide | `phpunit:assert-not-empty $var` |
| `phpunit:assert-true` | Vérifier si vrai | `phpunit:assert-true $condition` |
| `phpunit:assert-false` | Vérifier si faux | `phpunit:assert-false $condition` |
| `phpunit:assert-null` | Vérifier si null | `phpunit:assert-null $var` |
| `phpunit:assert-not-null` | Vérifier si non null | `phpunit:assert-not-null $var` |

### Commandes d'Exception
| Commande | Description | Syntaxe |
|----------|-------------|----------|
| `phpunit:expect-exception` | Attendre exception | `phpunit:expect-exception Class $expr` |
| `phpunit:expect-no-exception` | Aucune exception | `phpunit:expect-no-exception $expr` |

### Commandes de Mock
| Commande | Description | Syntaxe |
|----------|-------------|----------|
| `phpunit:mock` | Créer un mock | `phpunit:mock ClassName [varName]` |
| `phpunit:partial-mock` | Mock partiel | `phpunit:partial-mock Class methods` |
| `phpunit:expect` | Configurer expectation | `phpunit:expect $mock->method()->willReturn()` |
| `phpunit:spy` | Créer un spy | `phpunit:spy ClassName [method]` |
| `phpunit:call-original` | Appeler original | `phpunit:call-original $mock method` |

### Commandes de Debug
| Commande | Description | Syntaxe |
|----------|-------------|----------|
| `phpunit:debug` | Mode debug | `phpunit:debug [on/off/status]` |
| `phpunit:trace` | Analyser traces | `phpunit:trace [--detailed]` |
| `phpunit:profile` | Profiler performances | `phpunit:profile [start/stop/report]` |
| `phpunit:monitor` | Surveillance temps réel | `phpunit:monitor [--alerts]` |

### Commandes Avancées
| Commande | Description | Syntaxe |
|----------|-------------|----------|
| `phpunit:watch` | Surveillance auto | `phpunit:watch [--paths=dir]` |
| `phpunit:benchmark` | Tests performance | `phpunit:benchmark expression N` |
| `phpunit:compare` | Comparer performances | `phpunit:compare expr1 expr2` |
| `phpunit:compare-performance` | Comparaison avancée | `phpunit:compare-performance [options]` |

### Commandes de Configuration
| Commande | Description | Syntaxe |
|----------|-------------|----------|
| `phpunit:config` | Configuration | `phpunit:config [--option=value]` |
| `phpunit:temp-config` | Config temporaire | `phpunit:temp-config setting value` |
| `phpunit:restore-config` | Restaurer config | `phpunit:restore-config [--default]` |

### Commandes de Snapshot
| Commande | Description | Syntaxe |
|----------|-------------|----------|
| `phpunit:snapshot` | Gestion snapshots | `phpunit:snapshot [save/restore/list]` |
| `phpunit:save-snapshot` | Sauvegarder | `phpunit:save-snapshot name` |

### Commandes de Projet
| Commande | Description | Syntaxe |
|----------|-------------|----------|
| `phpunit:run-all` | Exécuter tous tests | `phpunit:run-all [--parallel]` |
| `phpunit:run-project` | Tests d'un projet | `phpunit:run-project name` |
| `phpunit:list-project` | Lister projets | `phpunit:list-project [--detailed]` |

### Commande d'Aide
| Commande | Description | Syntaxe |
|----------|-------------|----------|
| `phpunit:help` | Aide personnalisée | `phpunit:help [command]` |

---

*Ce guide couvre toutes les commandes PHPUnit personnalisées disponibles. Pour plus d'informations sur une commande spécifique, utilisez `phpunit:help nom_commande`.*
