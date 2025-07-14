# PsySH Enhanced - Shell PHP universel avec PHPUnit et Monitoring

## 🚀 Fonctionnalités

- ✅ **Compatible avec tous les projets PHP/Symfony** (toutes versions)
- ✅ **Détection automatique d'environnement** (Symfony, Laravel, PHP générique)
- ✅ **Commandes PHPUnit interactives** complètes
- ✅ **Monitoring Xdebug** intégré
- ✅ **Autoloader intelligent** multi-projet
- ✅ **Variables framework-specific** automatiques

## 📦 Installation

### Méthode 1: Copier dans votre projet
```bash
# Copiez le dossier .psysh dans votre projet
cp -r .psysh /path/to/your/project/
cd /path/to/your/project

# Lancez PsySH Enhanced
psysh --config ./.psysh/config.php
```

### Méthode 2: Utilisation portable
```bash
# Gardez .psysh dans un dossier central
# Lancez depuis n'importe quel projet
psysh --config /path/to/.psysh/config.php
```

### Méthode 3: Script de démarrage
```bash
# Utilisez le script de démarrage
php .psysh/start.php
```

## Commandes disponibles

### `phpunit:create <service>`
Crée un nouveau test PHPUnit interactif.

```bash
>>> phpunit:create App\Service\InvoiceService
✅ Test créé : InvoiceServiceTest (mode interactif)
```

### `phpunit:add <method>`
Ajoute une méthode de test au test actuel.

```bash
>>> phpunit:add testGenerate
✅ Méthode testGenerate ajoutée
```

### `phpunit:code`
Entre en mode code interactif pour développer le test.

```bash
>>> phpunit:code
📋 Mode code activé. Tapez "exit" pour quitter le mode code.
[Code Mode] >>> $invoiceService = new InvoiceService();
[Code Mode] >>> $user = new User(['id' => 1, 'email' => 'test@example.com']);
[Code Mode] >>> $result = $invoiceService->generate($user);
[Code Mode] >>> exit
✅ Code ajouté au test (3 lignes)
```

### `phpunit:assert <assertion>`
Ajoute une assertion au test actuel.

```bash
>>> phpunit:assert $result->getTotal() == 80
✅ Assertion ajoutée : $result->getTotal() == 80
```

### `phpunit:run [test]`
Exécute le test actuel ou un test spécifique.

```bash
>>> phpunit:run
🧪 Exécution : testGenerate
✅ Test réussi avec 2 assertions
```

### `phpunit:export <testName> [path]`
Exporte un test vers un fichier.

```bash
>>> phpunit:export InvoiceServiceTest
✅ Test exporté vers tests/Generated/InvoiceServiceTest.php
```

### `phpunit:list`
Liste tous les tests actifs.

```bash
>>> phpunit:list
📋 Tests actifs :
- InvoiceServiceTest::testGenerate [3 lignes, 2 assertions]
- UserServiceTest::testCreate [5 lignes, 1 assertion]
```

### `phpunit:help <className>`
Obtient de l'aide contextuelle pour une classe.

```bash
>>> phpunit:help InvoiceService
📋 InvoiceService - Méthodes disponibles :
- generate(User $user, array $products): Invoice
- calculate(float $amount): float
- setTaxRate(float $rate): void
```

## Exemple d'utilisation complète

```bash
# 1. Créer un test
>>> phpunit:create App\Service\InvoiceService
✅ Test créé : InvoiceServiceTest

# 2. Ajouter une méthode
>>> phpunit:add testComplexScenario
✅ Méthode ajoutée : testComplexScenario

# 3. Développer le test en mode code
>>> phpunit:code
[Code Mode] >>> $user = new User(['id' => 1, 'email' => 'test@example.com']);
[Code Mode] >>> $products = [
[Code Mode] ...     new Product(['id' => 1, 'price' => 50]),
[Code Mode] ...     new Product(['id' => 2, 'price' => 30])
[Code Mode] ... ];
[Code Mode] >>> $invoiceService = new InvoiceService();
[Code Mode] >>> $result = $invoiceService->generate($user, $products);
[Code Mode] >>> exit
✅ Code ajouté au test (5 lignes)

# 4. Ajouter des assertions
>>> phpunit:assert $result->getTotal() == 80
>>> phpunit:assert count($result->getItems()) == 2

# 5. Exécuter le test
>>> phpunit:run
🧪 Exécution : testComplexScenario
✅ Test réussi avec 2 assertions

# 6. Exporter le test
>>> phpunit:export InvoiceServiceTest
✅ Test exporté vers tests/Generated/InvoiceServiceTest.php
```

## Fonctionnalités

- ✅ Création de tests interactifs
- ✅ Mode code avec variables persistantes
- ✅ Gestion des assertions
- ✅ Exécution des tests
- ✅ Export vers fichiers PHPUnit
- ✅ Aide contextuelle
- ✅ Gestion des erreurs
- ✅ Interface utilisateur avec emojis

## Architecture

```
.psysh/
├── Model/
│   └── InteractiveTest.php       # Modèle de test interactif
├── Service/
│   └── PHPUnitService.php        # Service de gestion des tests
├── Traits/
│   └── PHPUnitCommandTrait.php   # Fonctionnalités communes
├── PsyCommand/
│   ├── PHPUnitCreateCommand.php  # Commande create
│   ├── PHPUnitAddCommand.php     # Commande add
│   ├── PHPUnitCodeCommand.php    # Commande code
│   ├── PHPUnitAssertCommand.php  # Commande assert
│   ├── PHPUnitRunCommand.php     # Commande run
│   ├── PHPUnitExportCommand.php  # Commande export
│   ├── PHPUnitListCommand.php    # Commande list
│   └── PHPUnitHelpCommand.php    # Commande help
├── autoload.php                  # Chargement automatique
├── config.php                    # Configuration PsySH
└── README.md                     # Documentation
```
