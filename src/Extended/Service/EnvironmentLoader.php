<?php

namespace Psy\Extended\Service;

class EnvironmentLoader
{
    private string $projectRoot;
    private array $context = [];

    public function __construct()
    {
        // Utiliser le nouveau système d'autoload intelligent
        $this->projectRoot = $GLOBALS['mediashare_psysh_project_root'] ?? $GLOBALS['project_root'] ?? getcwd();
    }

    public function loadProjectContext(): array
    {
        $this->context = [
            'type' => 'php',
            'framework' => null,
            'variables' => [],
            'info' => [],
            'welcome_message' => '',
            'autoload_config' => []
        ];

        // Détecter le type de projet
        $this->detectProjectType();
        
        // Charger les variables selon le type
        $this->loadProjectVariables();
        
        // Configurer l'auto-complétion
        $this->configureAutocompletion();
        
        // Créer le message d'accueil
        $this->createWelcomeMessage();
        
        return $this->context;
    }

    private function detectProjectType(): void
    {
        // Détecter Symfony
        if (file_exists($this->projectRoot . '/symfony.lock') || 
            file_exists($this->projectRoot . '/config/bundles.php') ||
            file_exists($this->projectRoot . '/public/index.php')) {
            
            $this->context['type'] = 'symfony';
            $this->context['framework'] = 'Symfony';
            $this->detectSymfonyVersion();
        }
        
        // Détecter Laravel
        elseif (file_exists($this->projectRoot . '/artisan')) {
            $this->context['type'] = 'laravel';
            $this->context['framework'] = 'Laravel';
        }
        
        // Détecter CodeIgniter
        elseif (file_exists($this->projectRoot . '/system/CodeIgniter.php')) {
            $this->context['type'] = 'codeigniter';
            $this->context['framework'] = 'CodeIgniter';
        }
        
        // Détecter CakePHP
        elseif (file_exists($this->projectRoot . '/bin/cake')) {
            $this->context['type'] = 'cakephp';
            $this->context['framework'] = 'CakePHP';
        }
        
        // Détecter Zend Framework / Laminas
        elseif (file_exists($this->projectRoot . '/public/index.php') && 
                file_exists($this->projectRoot . '/module')) {
            $this->context['type'] = 'zend';
            $this->context['framework'] = 'Zend/Laminas';
        }
        
        // Détecter Yii Framework
        elseif (file_exists($this->projectRoot . '/yii')) {
            $this->context['type'] = 'yii';
            $this->context['framework'] = 'Yii';
        }
        
        // Détecter Phalcon
        elseif (file_exists($this->projectRoot . '/public/index.php') && 
                file_exists($this->projectRoot . '/app/config')) {
            $this->context['type'] = 'phalcon';
            $this->context['framework'] = 'Phalcon';
        }
        
        // Projet PHP générique
        elseif (file_exists($this->projectRoot . '/composer.json')) {
            $this->context['type'] = 'composer';
            $this->context['framework'] = 'Composer Project';
        }
        
        // Projet PHP basique
        else {
            $this->context['type'] = 'php';
            $this->context['framework'] = 'PHP';
        }
    }

    private function detectSymfonyVersion(): void
    {
        $kernelFile = $this->projectRoot . '/src/Kernel.php';
        if (file_exists($kernelFile)) {
            $this->context['info']['kernel_file'] = $kernelFile;
        }
        
        $composerLock = $this->projectRoot . '/composer.lock';
        if (file_exists($composerLock)) {
            $lockData = json_decode(file_get_contents($composerLock), true);
            foreach ($lockData['packages'] ?? [] as $package) {
                if ($package['name'] === 'symfony/framework-bundle') {
                    $this->context['info']['symfony_version'] = $package['version'];
                    break;
                }
            }
        }
    }

    private function loadProjectVariables(): void
    {
        $variables = [];
        
        switch ($this->context['type']) {
            case 'symfony':
                $variables = $this->loadSymfonyVariables();
                break;
            case 'laravel':
                $variables = $this->loadLaravelVariables();
                break;
            case 'codeigniter':
                $variables = $this->loadCodeIgniterVariables();
                break;
            case 'cakephp':
                $variables = $this->loadCakePHPVariables();
                break;
            case 'yii':
                $variables = $this->loadYiiVariables();
                break;
            case 'zend':
            case 'phalcon':
            case 'composer':
            case 'php':
            default:
                $variables = $this->loadGenericVariables();
                break;
        }
        
        $this->context['variables'] = $variables;
    }

    private function loadSymfonyVariables(): array
    {
        $variables = [];
        
        try {
            // Charger l'autoloader Composer si nécessaire
            if (file_exists($this->projectRoot . '/vendor/autoload.php')) {
                require_once $this->projectRoot . '/vendor/autoload.php';
            }
            
            // Charger les variables d'environnement
            $this->loadEnvironmentVariables();
            
            // Tenter de charger le kernel Symfony
            $kernelFile = $this->projectRoot . '/src/Kernel.php';
            if (file_exists($kernelFile)) {
                require_once $kernelFile;
                
                if (class_exists('App\\Kernel')) {
                    $kernel = new \App\Kernel('dev', true);
                    $kernel->boot();
                    
                    $container = $kernel->getContainer();
                    
                    $variables = [
                        'kernel' => $kernel,
                        'container' => $container,
                        'parameterBag' => $container->getParameterBag(),
                        'env' => $_ENV,
                        'server' => $_SERVER,
                    ];
                    
                    // Ajouter les services Symfony courants si disponibles
                    if ($container->has('doctrine.orm.entity_manager')) {
                        $variables['entityManager'] = $container->get('doctrine.orm.entity_manager');
                        $variables['em'] = $variables['entityManager'];
                        $variables['doctrine'] = $container->get('doctrine');
                    }
                    
                    if ($container->has('router')) {
                        $variables['router'] = $container->get('router');
                    }
                    
                    if ($container->has('event_dispatcher')) {
                        $variables['dispatcher'] = $container->get('event_dispatcher');
                    }
                    
                    if ($container->has('security.token_storage')) {
                        $variables['security'] = $container->get('security.token_storage');
                    }
                    
                    if ($container->has('session')) {
                        $variables['session'] = $container->get('session');
                    }
                    
                    if ($container->has('cache.app')) {
                        $variables['cache'] = $container->get('cache.app');
                    }
                    
                    if ($container->has('logger')) {
                        $variables['logger'] = $container->get('logger');
                    }
                    
                    if ($container->has('serializer')) {
                        $variables['serializer'] = $container->get('serializer');
                    }
                    
                    if ($container->has('validator')) {
                        $variables['validator'] = $container->get('validator');
                    }
                    
                    if ($container->has('translator')) {
                        $variables['translator'] = $container->get('translator');
                    }
                    
                    if ($container->has('twig')) {
                        $variables['twig'] = $container->get('twig');
                    }
                    
                    if ($container->has('mailer')) {
                        $variables['mailer'] = $container->get('mailer');
                    }
                    
                    // Ajouter des raccourcis pratiques
                    if (isset($variables['entityManager'])) {
                        $variables['connection'] = $variables['entityManager']->getConnection();
                    }
                }
            }
        } catch (\Throwable $e) {
            // Si le chargement échoue, ajouter les variables de base
            $variables = $this->loadGenericVariables();
            $variables['symfony_error'] = $e->getMessage();
        }
        
        return array_merge($variables, $this->loadGenericVariables());
    }

    private function loadLaravelVariables(): array
    {
        $variables = [];
        
        try {
            // Charger l'autoloader Composer si nécessaire
            if (file_exists($this->projectRoot . '/vendor/autoload.php')) {
                require_once $this->projectRoot . '/vendor/autoload.php';
            }
            
            // Tenter de charger Laravel
            $bootstrapFile = $this->projectRoot . '/bootstrap/app.php';
            if (file_exists($bootstrapFile)) {
                $app = require_once $bootstrapFile;
                $variables['app'] = $app;
                
                if (method_exists($app, 'make')) {
                    $variables['db'] = $app->make('db');
                    $variables['cache'] = $app->make('cache');
                    $variables['config'] = $app->make('config');
                    $variables['logger'] = $app->make('log');
                    $variables['validator'] = $app->make('validator');
                    $variables['session'] = $app->make('session');
                    $variables['request'] = $app->make('request');
                    $variables['response'] = $app->make('response');
                    $variables['auth'] = $app->make('auth');
                    $variables['storage'] = $app->make('filesystem');
                    $variables['mail'] = $app->make('mail');
                    $variables['queue'] = $app->make('queue');
                    $variables['event'] = $app->make('events');
                }
                
                // Ajouter les variables d'environnement Laravel
                $variables['env'] = $_ENV;
                $variables['server'] = $_SERVER;
            }
        } catch (\Throwable $e) {
            $variables['laravel_error'] = $e->getMessage();
        }
        
        return array_merge($variables, $this->loadGenericVariables());
    }

    private function loadGenericVariables(): array
    {
        $variables = [
            'projectRoot' => $this->projectRoot,
            'composerAutoloader' => $GLOBALS['composer_autoloader'] ?? null,
            'phpunitService' => $GLOBALS['phpunit_service'] ?? null,
            'env' => $_ENV,
            'server' => $_SERVER,
        ];
        
        // Ajouter les informations Composer si disponibles
        if (file_exists($this->projectRoot . '/composer.json')) {
            $composerData = json_decode(file_get_contents($this->projectRoot . '/composer.json'), true);
            $variables['composer'] = $composerData;
        }
        
        // Ajouter des fonctions utilitaires
        $variables['help'] = function() {
            echo "\n🚀 PsySH Enhanced Shell - Variables disponibles:\n";
            echo "📦 Variables de base:\n";
            echo "   • \$projectRoot    - Racine du projet\n";
            echo "   • \$env           - Variables d'environnement\n";
            echo "   • \$server        - Variables serveur\n";
            echo "   • \$composer      - Données composer.json\n";
            
            if (isset($GLOBALS['em'])) {
                echo "\n🗄️  Variables Symfony/Doctrine:\n";
                echo "   • \$em            - Entity Manager\n";
                echo "   • \$kernel        - Kernel Symfony\n";
                echo "   • \$container     - Container de services\n";
            }
            
            if (isset($GLOBALS['app'])) {
                echo "\n🚀 Variables Laravel:\n";
                echo "   • \$app           - Application Laravel\n";
                echo "   • \$db            - Base de données\n";
                echo "   • \$cache         - Cache\n";
            }
            
            echo "\n🧪 Commandes PHPUnit:\n";
            echo "   • phpunit:create  - Créer un test\n";
            echo "   • phpunit:add     - Ajouter une méthode\n";
            echo "   • phpunit:code    - Mode code\n";
            echo "   • phpunit:run     - Exécuter\n";
            echo "   • phpunit:list    - Lister\n";
            echo "\n📚 Tapez 'help()' pour revoir cette aide\n";
        };
        
        $variables['resetTerminal'] = function() {
            system('clear');
        };
        
        return $variables;
    }

    private function loadCodeIgniterVariables(): array
    {
        $variables = [];
        
        try {
            // Charger l'autoloader Composer si nécessaire
            if (file_exists($this->projectRoot . '/vendor/autoload.php')) {
                require_once $this->projectRoot . '/vendor/autoload.php';
            }
            
            // Charger CodeIgniter
            if (file_exists($this->projectRoot . '/index.php')) {
                // Note: CodeIgniter nécessite une initialisation spécifique
                $variables['codeigniter_path'] = $this->projectRoot;
                $variables['env'] = $_ENV;
                $variables['server'] = $_SERVER;
            }
        } catch (\Throwable $e) {
            $variables['codeigniter_error'] = $e->getMessage();
        }
        
        return array_merge($variables, $this->loadGenericVariables());
    }

    private function loadCakePHPVariables(): array
    {
        $variables = [];
        
        try {
            // Charger l'autoloader Composer si nécessaire
            if (file_exists($this->projectRoot . '/vendor/autoload.php')) {
                require_once $this->projectRoot . '/vendor/autoload.php';
            }
            
            // Charger CakePHP
            if (file_exists($this->projectRoot . '/config/bootstrap.php')) {
                require_once $this->projectRoot . '/config/bootstrap.php';
                
                // Ajouter les variables CakePHP communes
                $variables['cakephp_path'] = $this->projectRoot;
                $variables['env'] = $_ENV;
                $variables['server'] = $_SERVER;
            }
        } catch (\Throwable $e) {
            $variables['cakephp_error'] = $e->getMessage();
        }
        
        return array_merge($variables, $this->loadGenericVariables());
    }

    private function loadYiiVariables(): array
    {
        $variables = [];
        
        try {
            // Charger l'autoloader Composer si nécessaire
            if (file_exists($this->projectRoot . '/vendor/autoload.php')) {
                require_once $this->projectRoot . '/vendor/autoload.php';
            }
            
            // Charger Yii
            if (file_exists($this->projectRoot . '/vendor/yiisoft/yii2/Yii.php')) {
                require_once $this->projectRoot . '/vendor/yiisoft/yii2/Yii.php';
                
                // Ajouter les variables Yii communes
                $variables['yii_path'] = $this->projectRoot;
                $variables['env'] = $_ENV;
                $variables['server'] = $_SERVER;
            }
        } catch (\Throwable $e) {
            $variables['yii_error'] = $e->getMessage();
        }
        
        return array_merge($variables, $this->loadGenericVariables());
    }

    private function loadEnvironmentVariables(): void
    {
        // Charger le fichier .env si il existe
        $envFile = $this->projectRoot . '/.env';
        if (file_exists($envFile)) {
            $envContent = file_get_contents($envFile);
            $lines = explode("\n", $envContent);
            
            foreach ($lines as $line) {
                $line = trim($line);
                if (empty($line) || str_starts_with($line, '#')) {
                    continue;
                }
                
                if (str_contains($line, '=')) {
                    list($key, $value) = explode('=', $line, 2);
                    $key = trim($key);
                    $value = trim($value, '"\' ');
                    
                    // Ne pas écraser les variables déjà définies
                    if (!isset($_ENV[$key])) {
                        $_ENV[$key] = $value;
                        putenv("$key=$value");
                    }
                }
            }
        }
        
        // Charger le fichier .env.local si il existe
        $envLocalFile = $this->projectRoot . '/.env.local';
        if (file_exists($envLocalFile)) {
            $envContent = file_get_contents($envLocalFile);
            $lines = explode("\n", $envContent);
            
            foreach ($lines as $line) {
                $line = trim($line);
                if (empty($line) || str_starts_with($line, '#')) {
                    continue;
                }
                
                if (str_contains($line, '=')) {
                    list($key, $value) = explode('=', $line, 2);
                    $key = trim($key);
                    $value = trim($value, '"\' ');
                    
                    $_ENV[$key] = $value;
                    putenv("$key=$value");
                }
            }
        }
    }

    private function configureAutocompletion(): void
    {
        // Charger l'autoloader Composer pour activer l'auto-complétion
        $this->loadComposerAutoloader();
        
        // Précharger les classes du projet pour l'auto-complétion
        $this->preloadProjectClasses();
        
        // Charger toutes les classes disponibles via l'autoloader
        $this->loadAllAvailableClasses();
    }

    private function loadComposerAutoloader(): void
    {
        static $composerLoaded = false;

        if ($composerLoaded) {
            return;
        }

        $autoloadPath = $this->projectRoot . '/vendor/autoload.php';
        if (file_exists($autoloadPath)) {
            require_once $autoloadPath;
        }

        // Autoloader pour les classes personnalisées PsySH
        spl_autoload_register(function ($class) {
            $namespaces = [
                'Psy\\Extended\\Command\\' => __DIR__ . '/../Command/',
                'Psy\\Extended\\Service\\' => __DIR__ . '/../Service/',
                'Psy\\Extended\\Model\\' => __DIR__ . '/../Model/',
                'Psy\\Extended\\Trait\\' => __DIR__ . '/../Trait/',
                'Mediashare\\Psysh\\TabCompletion\\' => __DIR__ . '/../TabCompletion/',
            ];

            foreach ($namespaces as $namespace => $path) {
                if (strpos($class, $namespace) === 0) {
                    $relativeClass = substr($class, strlen($namespace));
                    $file = $path . str_replace('\\', '/', $relativeClass) . '.php';

                    if (file_exists($file)) {
                        require_once $file;
                        return;
                    }
                }
            }
        });

        $composerLoaded = true;
    }
    
    private function preloadProjectClasses(): void
    {
        $composerJsonPath = $this->projectRoot . '/composer.json';
        if (!file_exists($composerJsonPath)) {
            return;
        }
        
        $composerConfig = json_decode(file_get_contents($composerJsonPath), true);
        
        // Charger les classes définies dans autoload
        if (isset($composerConfig['autoload']['psr-4'])) {
            foreach ($composerConfig['autoload']['psr-4'] as $namespace => $path) {
                $fullPath = $this->projectRoot . '/' . rtrim($path, '/');
                if (is_dir($fullPath)) {
                    $this->scanAndLoadClasses($fullPath, $namespace);
                }
            }
        }
        
        // Charger les classes définies dans autoload-dev
        if (isset($composerConfig['autoload-dev']['psr-4'])) {
            foreach ($composerConfig['autoload-dev']['psr-4'] as $namespace => $path) {
                $fullPath = $this->projectRoot . '/' . rtrim($path, '/');
                if (is_dir($fullPath)) {
                    $this->scanAndLoadClasses($fullPath, $namespace);
                }
            }
        }
        
        // Stocker la configuration d'autoload
        $this->context['autoload_config'] = $composerConfig['autoload'] ?? [];
    }
    
    private function scanAndLoadClasses(string $directory, string $namespace): void
    {
        if (!is_dir($directory)) {
            return;
        }
        
        $iterator = new \RecursiveIteratorIterator(
            new \RecursiveDirectoryIterator($directory, \RecursiveDirectoryIterator::SKIP_DOTS)
        );
        
        foreach ($iterator as $file) {
            if ($file->getExtension() === 'php') {
                $relativePath = str_replace($directory . '/', '', $file->getPathname());
                $className = $namespace . str_replace(['/', '.php'], ['\\', ''], $relativePath);
                
                // Vérifier si la classe existe avant de l'utiliser
                if (class_exists($className, false) || interface_exists($className, false) || trait_exists($className, false)) {
                    // La classe est maintenant chargée dans l'autoloader
                    continue;
                }
            }
        }
    }
    
    private function loadAllAvailableClasses(): void
    {
        // Utiliser l'autoloader Composer pour récupérer toutes les classes
        $autoloadPath = $this->projectRoot . '/vendor/autoload.php';
        if (file_exists($autoloadPath)) {
            $loader = require $autoloadPath;
            
            // Récupérer les classes du classmap
            $classMap = $loader->getClassMap();
            
            // Récupérer les namespaces PSR-4
            $prefixes = $loader->getPrefixesPsr4();
            
            // Sauvegarder les informations d'autoload pour l'auto-complétion
            $this->context['composer_classmap'] = array_keys($classMap);
            $this->context['composer_prefixes'] = array_keys($prefixes);
            
            // Charger quelques classes fréquemment utilisées
            $this->loadFrequentlyUsedClasses($classMap, $prefixes);
        }
    }
    
    private function loadFrequentlyUsedClasses(array $classMap, array $prefixes): void
    {
        // Patterns de classes fréquemment utilisées
        $patterns = [
            'App\\Service\\',
            'App\\Controller\\',
            'App\\Entity\\',
            'App\\Repository\\',
            'App\\Form\\',
            'Symfony\\Component\\',
            'Symfony\\Bundle\\',
            'Doctrine\\ORM\\',
            'Doctrine\\Persistence\\',
            'Psr\\Log\\',
            'Twig\\'
        ];
        
        foreach ($classMap as $className => $file) {
            foreach ($patterns as $pattern) {
                if (str_starts_with($className, $pattern)) {
                    // Tentative de chargement de la classe pour l'auto-complétion
                    if (class_exists($className, false) || interface_exists($className, false) || trait_exists($className, false)) {
                        continue;
                    }
                    break;
                }
            }
        }
    }

    private function createWelcomeMessage(): void
    {
        // Détecter l'environnement de test
        if ($this->isTestEnvironment()) {
            $this->context['welcome_message'] = ''; // Pas de message d'accueil en test
            return;
        }
        
        $framework = $this->context['framework'];
        $version = $this->context['info']['symfony_version'] ?? '';
        $environment = $this->detectEnvironment();
        
        $message = $this->createPersonalizedWelcomeMessage($framework, $version, $environment);
        
        $this->context['welcome_message'] = $message;
    }
    
    /**
     * Détecte si on est dans un environnement de test
     */
    private function isTestEnvironment(): bool
    {
        // Vérifier les variables d'environnement définies par les tests
        if (getenv('SIMPLE_MODE') || getenv('AUTO_MODE') || 
            ($_ENV['SIMPLE_MODE'] ?? false) || ($_ENV['AUTO_MODE'] ?? false)) {
            return true;
        }
        
        // Vérifier si on est lancé depuis le script de test
        $backtrace = debug_backtrace(DEBUG_BACKTRACE_IGNORE_ARGS);
        foreach ($backtrace as $trace) {
            if (isset($trace['file']) && str_contains($trace['file'], '/tests/')) {
                return true;
            }
        }
        
        // Vérifier si on est en mode non-interactif avec input depuis stdin
        if (in_array('--no-interactive', $GLOBALS['argv'] ?? []) || 
            !posix_isatty(STDIN)) {
            return true;
        }
        
        // Vérifier APP_ENV=test
        if (($_ENV['APP_ENV'] ?? '') === 'test' || getenv('APP_ENV') === 'test') {
            return true;
        }
        
        return false;
    }
    
    /**
     * Détecte l'environnement actuel (dev, prod, staging, etc.)
     */
    private function detectEnvironment(): string
    {
        // Vérifier APP_ENV d'abord
        $appEnv = $_ENV['APP_ENV'] ?? getenv('APP_ENV');
        if ($appEnv) {
            return $appEnv;
        }
        
        // Vérifier SYMFONY_ENV (legacy)
        $symfonyEnv = $_ENV['SYMFONY_ENV'] ?? getenv('SYMFONY_ENV');
        if ($symfonyEnv) {
            return $symfonyEnv;
        }
        
        // Détecter par la structure des fichiers
        if (file_exists($this->projectRoot . '/.env.local')) {
            return 'dev';
        } elseif (file_exists($this->projectRoot . '/.env.prod')) {
            return 'prod';
        } elseif (file_exists($this->projectRoot . '/.env.staging')) {
            return 'staging';
        }
        
        // Par défaut
        return 'dev';
    }

    /**
     * Liste dynamiquement toutes les commandes disponibles dans le projet (PSR-4 autoload)
     */
    private function getAvailableCommands(string $environment): string
    {
        // Nécessite : composer autoloader
        if (!class_exists('Symfony\\Component\\Console\\Command\\Command')) {
            if (file_exists($this->projectRoot . '/vendor/autoload.php')) {
                require_once $this->projectRoot . '/vendor/autoload.php';
            }
        }
        if (!class_exists('Symfony\\Component\\Console\\Command\\Command')) {
            return "\033[31m(Aucune commande disponible: le Composer autoload est manquant)\033[0m\n";
        }
        
        // Scanne le dossier src/ et ses sous-dossiers à la recherche de classes *Command
        $directory = $this->projectRoot . '/src/';
        $rii = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator($directory));
        $commandClasses = [];
        foreach ($rii as $file) {
            if ($file->isDir()) { continue; }
            if (substr($file->getFilename(), -11) === 'Command.php') {
                $rel = str_replace([$directory, '/', '.php'], ['', '\\', ''], $file->getPathname());
                // Essayer les namespaces connus PSR-4 autoloadés
                $candidateClasses = [
                    'Mediashare\\Psysh\\' . $rel,
                    'App\\' . $rel,
                ];
                foreach ($candidateClasses as $class) {
                    if (class_exists($class)) {
                        if (is_subclass_of($class, 'Symfony\\Component\\Console\\Command\\Command')) {
                            $commandClasses[] = $class;
                        }
                    }
                }
            }
        }
        // Si le projet expose des commandes ailleurs (plugins, vendor, etc.), on peut élargir ici !
        if (empty($commandClasses)) {
            return "\033[33m(Aucune commande custom trouvée dans src/)\033[0m\n";
        }
        // Instancie et formate la description de chaque commande :
        $out = "";
        foreach ($commandClasses as $class) {
            try {
                // Skip abstract classes
                $reflection = new \ReflectionClass($class);
                if ($reflection->isAbstract()) {
                    continue;
                }
                
                // Handle classes that need constructor parameters
                $constructor = $reflection->getConstructor();
                if ($constructor && $constructor->getNumberOfRequiredParameters() > 0) {
                    // Skip classes that require specific constructor parameters
                    // These should be handled by the config.php instantiation logic
                    continue;
                }
                
                $command = new $class();
                $usage = $command->getName() ?: $class;
                $desc  = method_exists($command, 'getDescription') ? $command->getDescription() : '';
                $aliases = method_exists($command, 'getAliases') ? $command->getAliases() : [];
                $out .= "   • \033[32m" . $usage . "\033[0m";
                if (!empty($aliases)) {
                    $out .= " (aussi: " . implode(', ', $aliases) . ")";
                }
                if ($desc) {
                    $out .= " — " . trim($desc);
                }
                $out .= "\n";
            } catch (\Throwable $e) {
                $out .= "   [\033[31mKO\033[0m] $class — " . $e->getMessage() . "\n";
            }
        }
        return $out ?: "(Aucune commande trouvée)\n";
    }

    /**
     * Crée un message d'accueil personnalisé selon l'environnement
     */
    private function createPersonalizedWelcomeMessage(string $framework, string $version, string $environment): string
    {
        $message = "\n";
        
        // Header personnalisé selon l'environnement
        switch ($environment) {
            case 'prod':
                $message .= "<error>" . str_repeat('=', 80) . "</error>\n";
                $message .= "<error>PsySH Shell Enhanced - {$framework} [PRODUCTION]</error>" . ($version ? " <comment>{$version}</comment>" : '') . "\n";
                $message .= "<bg=red;fg=white>ATTENTION: Vous etes en environnement de PRODUCTION!</bg=red;fg=white>\n";
                break;
                
            case 'staging':
                $message .= "<comment>" . str_repeat('=', 80) . "</comment>\n";
                $message .= "<comment>PsySH Shell Enhanced - {$framework} [STAGING]</comment>" . ($version ? " <info>{$version}</info>" : '') . "\n";
                $message .= "<comment>Environnement de pre-production</comment>\n";
                break;
                
            case 'test':
                $message .= "<info>" . str_repeat('=', 80) . "</info>\n";
                $message .= "<info>PsySH Shell Enhanced - {$framework} [TEST]</info>" . ($version ? " <comment>{$version}</comment>" : '') . "\n";
                $message .= "<info>Environnement de test</info>\n";
                break;
                
            default: // dev
                $message .= "<info>" . str_repeat('=', 80) . "</info>\n";
                $message .= "<info>PsySH Shell Enhanced - {$framework}</info>" . ($version ? " <comment>{$version}</comment>" : '') . "\n";
                $message .= "<comment>Environnement de developpement</comment>\n";
                break;
        }
        
        $message .= "<comment>Project: " . basename($this->projectRoot) . "</comment>\n";
        $message .= "<info>" . str_repeat('=', 80) . "</info>\n\n";
        
        // Commandes dynamiquement détectées
        $message .= "\033[36mCOMMANDES DISPONIBLES (détection automatique):\033[0m\n";
        $message .= $this->getAvailableCommands($environment);
        
        if ($environment === 'prod') {
            $message .= "   <fg=yellow>-</fg=yellow> <fg=green>help()</fg=green>                   - Aide et documentation\n";
            $message .= "   <fg=yellow>-</fg=yellow> <fg=green>ls</fg=green>                       - Lister les variables\n";
            $message .= "   <fg=yellow>-</fg=yellow> <fg=green>show \$variable</fg=green>           - Examiner une variable\n";
            $message .= "   <fg=yellow>-</fg=yellow> <fg=green>exit</fg=green>                     - Quitter le shell\n";
            $message .= "\n<error>En production, les commandes de modification sont desactivees.</error>\n";
        } else {
            $message .= "   <fg=magenta>Monitoring:</fg=magenta>\n";
            $message .= "     <fg=yellow>-</fg=yellow> <fg=green>monitor <code></fg=green>           - Monitor code execution\n";
            $message .= "     <fg=yellow>-</fg=yellow> <fg=green>monitor-advanced <code></fg=green>  - Advanced monitoring\n";
            $message .= "\n   <fg=magenta>PHPUnit Enhanced:</fg=magenta>\n";
            $message .= "     <fg=yellow>-</fg=yellow> <fg=green>phpunit:create <service></fg=green> - Create interactive test\n";
            $message .= "     <fg=yellow>-</fg=yellow> <fg=green>phpunit:add <method></fg=green>     - Add test method\n";
            $message .= "     <fg=yellow>-</fg=yellow> <fg=green>phpunit:code</fg=green>             - Enter code mode\n";
            $message .= "     <fg=yellow>-</fg=yellow> <fg=green>phpunit:run</fg=green>              - Run tests\n";
            $message .= "     <fg=yellow>-</fg=yellow> <fg=green>phpunit:mock <class></fg=green>     - Create mocks\n";
            $message .= "     <fg=yellow>-</fg=yellow> <fg=green>phpunit:list</fg=green>             - List active tests\n";
            $message .= "\n   <fg=magenta>Aide avancee:</fg=magenta>\n";
            $message .= "     <fg=yellow>-</fg=yellow> <fg=green>help phpunit:add</fg=green>         - Aide detaillee pour une commande\n";
            $message .= "     <fg=yellow>-</fg=yellow> <fg=green>help()</fg=green>                   - Aide generale\n";
            
            if ($this->context['type'] === 'symfony') {
                $message .= "\n   <fg=magenta>Variables Symfony disponibles:</fg=magenta>\n";
                $message .= "     <fg=yellow>-</fg=yellow> <fg=cyan>\$kernel, \$container, \$em</fg=cyan> (EntityManager)\n";
                $message .= "     <fg=yellow>-</fg=yellow> <fg=cyan>\$router, \$security, \$cache, \$logger</fg=cyan>\n";
            }
        }
        
        $message .= "\n<info>" . str_repeat('=', 80) . "</info>\n";
        
        // Message de bienvenue personnalisé
        switch ($environment) {
            case 'prod':
                $message .= "<error>Soyez prudent! Tapez 'exit' pour quitter.</error>\n";
                break;
            case 'staging':
                $message .= "<comment>Environnement de staging - Testez vos fonctionnalites!</comment>\n";
                break;
            case 'test':
                $message .= "<info>Mode test active - Environnement isole.</info>\n";
                break;
            default:
                $message .= "<fg=green>Happy coding! Tapez 'help()' pour commencer.</fg=green>\n";
                break;
        }
        
        $message .= "\n";
        
        return $message;
    }
}
