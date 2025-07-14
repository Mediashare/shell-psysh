# Enhanced Environment Loader

## Vue d'ensemble

L'`EnvironmentLoader` a été considérablement amélioré pour détecter automatiquement différents types de projets et frameworks PHP, et injecter les variables appropriées dans le shell PsySH.

## Frameworks supportés

### 1. Symfony
- **Détection** : Présence de `symfony.lock`, `config/bundles.php`, ou `public/index.php`
- **Variables injectées** :
  - `$kernel` - Kernel Symfony
  - `$container` - Container de services
  - `$em` / `$entityManager` - Entity Manager Doctrine
  - `$doctrine` - Service Doctrine
  - `$router` - Router Symfony
  - `$dispatcher` - Event Dispatcher
  - `$security` - Security Token Storage
  - `$session` - Session
  - `$cache` - Cache
  - `$logger` - Logger
  - `$serializer` - Serializer
  - `$validator` - Validator
  - `$translator` - Translator
  - `$twig` - Twig
  - `$mailer` - Mailer
  - `$connection` - Connection Doctrine
  - `$parameterBag` - Parameter Bag

### 2. Laravel
- **Détection** : Présence de `artisan`
- **Variables injectées** :
  - `$app` - Application Laravel
  - `$db` - Database
  - `$cache` - Cache
  - `$config` - Configuration
  - `$logger` - Logger
  - `$validator` - Validator
  - `$session` - Session
  - `$request` - Request
  - `$response` - Response
  - `$auth` - Authentication
  - `$storage` - Filesystem
  - `$mail` - Mailer
  - `$queue` - Queue
  - `$event` - Event Dispatcher

### 3. CodeIgniter
- **Détection** : Présence de `system/CodeIgniter.php`
- **Variables injectées** :
  - `$codeigniter_path` - Chemin du projet

### 4. CakePHP
- **Détection** : Présence de `bin/cake`
- **Variables injectées** :
  - `$cakephp_path` - Chemin du projet

### 5. Yii Framework
- **Détection** : Présence de `yii`
- **Variables injectées** :
  - `$yii_path` - Chemin du projet

### 6. Zend Framework / Laminas
- **Détection** : Présence de `public/index.php` et `module`
- **Variables génériques** seulement

### 7. Phalcon
- **Détection** : Présence de `public/index.php` et `app/config`
- **Variables génériques** seulement

## Variables communes

Tous les projets reçoivent ces variables de base :

- `$projectRoot` - Racine du projet
- `$env` - Variables d'environnement
- `$server` - Variables serveur
- `$composer` - Données du composer.json
- `$composerAutoloader` - Autoloader Composer
- `$phpunitService` - Service PHPUnit (si disponible)
- `$help()` - Fonction d'aide
- `$resetTerminal()` - Fonction pour nettoyer le terminal

## Gestion des variables d'environnement

L'`EnvironmentLoader` charge automatiquement :

1. **Fichier `.env`** - Variables d'environnement de base
2. **Fichier `.env.local`** - Variables d'environnement locales (priorité)

### Algorithme de chargement

```php
private function loadEnvironmentVariables(): void
{
    // 1. Charger .env (sans écraser les variables existantes)
    // 2. Charger .env.local (écrase les variables existantes)
    // 3. Ignorer les lignes vides et les commentaires (#)
    // 4. Parser les lignes au format KEY=VALUE
}
```

## Utilisation

### Lancement du shell

```bash
psysh --config ./.psysh/config.php
```

### Commandes disponibles

- `help()` - Afficher l'aide contextuelle
- `get_defined_vars()` - Lister toutes les variables
- `phpunit:*` - Commandes PHPUnit personnalisées
- `monitor <code>` - Monitorer l'exécution de code

### Exemple d'utilisation avec Symfony

```php
// Vérifier la connexion à la base de données
$em->getConnection()->ping()

// Lister les entités
$em->getMetadataFactory()->getAllMetadata()

// Exécuter une requête
$em->getRepository(User::class)->findAll()

// Accéder aux services
$container->get('logger')->info('Test depuis PsySH')
```

### Exemple d'utilisation avec Laravel

```php
// Vérifier la connexion à la base de données
$db->connection()->getPdo()

// Exécuter une requête
$db->table('users')->get()

// Accéder aux services
$app->make('log')->info('Test depuis PsySH')
```

## Gestion des erreurs

Si le chargement d'un framework échoue, l'`EnvironmentLoader` :

1. Capture l'exception
2. Ajoute une variable `{framework}_error` avec le message d'erreur
3. Retourne les variables génériques de base

## Structure du contexte retourné

```php
[
    'type' => 'symfony',           // Type de projet détecté
    'framework' => 'Symfony',      // Nom du framework
    'variables' => [...],          // Variables injectées
    'info' => [                    // Informations supplémentaires
        'symfony_version' => '7.3.1',
        'kernel_file' => '/path/to/Kernel.php'
    ],
    'welcome_message' => '...'     // Message d'accueil formaté
]
```

## Tests

Pour tester l'`EnvironmentLoader` :

```bash
# Test de détection
php -r "
require_once '.psysh/autoload.php';
\$loader = new Mediashare\Psysh\Service\EnvironmentLoader();
\$context = \$loader->loadProjectContext();
echo 'Framework: ' . \$context['framework'] . PHP_EOL;
echo 'Variables: ' . implode(', ', array_keys(\$context['variables'])) . PHP_EOL;
"

# Test du shell complet
psysh --config ./.psysh/config.php
```

## Avantages

1. **Détection automatique** - Pas besoin de configuration manuelle
2. **Support multi-framework** - Fonctionne avec les frameworks PHP populaires
3. **Variables contextuelles** - Accès direct aux services du framework
4. **Gestion robuste des erreurs** - Fallback gracieux en cas de problème
5. **Extensibilité** - Facile d'ajouter de nouveaux frameworks
6. **Performance** - Chargement optimal des variables d'environnement

## Prochaines améliorations

- Support de Drupal
- Support de WordPress
- Chargement conditionnel des services lourds
- Cache du contexte pour améliorer les performances
- Détection de la version des frameworks
