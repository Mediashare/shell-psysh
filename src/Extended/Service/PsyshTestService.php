<?php

namespace Psy\Extended\Service;

use Symfony\Component\DependencyInjection\Attribute\Autoconfigure;
use Symfony\Component\DependencyInjection\ParameterBag\ParameterBagInterface;

#[Autoconfigure(public: true)]
class PsyshTestService
{
    private ?string $persistentConfigPath = null;
    private array $currentConfig = [];
    private array $testOptions = [];
    private ?string $currentFilter = null;
    private ?string $currentTestPath = null;

    private string $projectDir;

    public function __construct(
        private readonly ParameterBagInterface $parameterBag,
    ) {
        $this->projectDir = $this->parameterBag->get('kernel.project_dir');
    }

    // =================================================================
    // CONFIGURATION PHPUNIT - MÉTHODES INTELLIGENTES ET FLEXIBLES
    // =================================================================

    /**
     * Configuration principale - supporte tous les formats
     */
    public function config(mixed ...$args): self
    {
        // Format 1: config(['env' => [...], 'server' => [...]])
        if (count($args) === 1 && is_array($args[0])) {
            $this->currentConfig = array_merge_recursive($this->currentConfig, $args[0]);
        }
        // Format 2: config('env', ['RUN_PRE_TEST' => 'false'])
        elseif (count($args) === 2 && is_string($args[0]) && is_array($args[1])) {
            $this->currentConfig[$args[0]] = array_merge($this->currentConfig[$args[0]] ?? [], $args[1]);
        }
        // Format 3: config('env', 'RUN_PRE_TEST', 'false')
        elseif (count($args) === 3 && is_string($args[0]) && is_string($args[1])) {
            $this->currentConfig[$args[0]][$args[1]] = $args[2];
        }

        $this->applyConfig();
        return $this;
    }

    /**
     * Configurer les variables d'environnement
     */
    public function env(mixed ...$args): self
    {
        // env(['RUN_PRE_TEST' => 'false', 'APP_ENV' => 'test'])
        if (count($args) === 1 && is_array($args[0])) {
            foreach ($args[0] as $key => $value) {
                $this->currentConfig['env'][$key] = $value;
            }
        }
        // env('RUN_PRE_TEST', 'false')
        elseif (count($args) === 2) {
            $this->currentConfig['env'][$args[0]] = $args[1];
        }

        $this->applyConfig();
        return $this;
    }

    /**
     * Configurer les variables serveur
     */
    public function server(mixed ...$args): self
    {
        if (count($args) === 1 && is_array($args[0])) {
            foreach ($args[0] as $key => $value) {
                $this->currentConfig['server'][$key] = $value;
            }
        } elseif (count($args) === 2) {
            $this->currentConfig['server'][$args[0]] = $args[1];
        }

        $this->applyConfig();
        return $this;
    }

    /**
     * Configurer les directives PHP
     */
    public function ini(mixed ...$args): self
    {
        if (count($args) === 1 && is_array($args[0])) {
            foreach ($args[0] as $key => $value) {
                $this->currentConfig['ini'][$key] = $value;
            }
        } elseif (count($args) === 2) {
            $this->currentConfig['ini'][$args[0]] = $args[1];
        }

        $this->applyConfig();
        return $this;
    }

    /**
     * Configurer les options de test (flags PHPUnit)
     */
    public function options(mixed ...$args): self
    {
        // options(['verbose' => true, 'testdox' => true])
        if (count($args) === 1 && is_array($args[0])) {
            $this->testOptions = array_merge($this->testOptions, $args[0]);
        }
        // options('verbose', true)
        elseif (count($args) === 2) {
            $this->testOptions[$args[0]] = $args[1];
        }
        // options('verbose') - flag simple
        elseif (count($args) === 1 && is_string($args[0])) {
            $this->testOptions[$args[0]] = true;
        }

        echo "Options de test mises à jour: " . json_encode($this->testOptions) . "\n";
        return $this;
    }

    /**
     * Configurer le filtre de test
     */
    public function filter(mixed ...$args): self
    {
        // filter('.*(Candidate|Student).*')
        if (count($args) === 1 && is_string($args[0])) {
            $this->currentFilter = $args[0];
        }
        // filter(['Candidate', 'Student']) - mots-clés
        elseif (count($args) === 1 && is_array($args[0])) {
            $this->currentFilter = '.*(' . implode('|', $args[0]) . ').*';
        }
        // filter('Candidate', 'Student') - mots-clés en arguments
        elseif (count($args) > 1) {
            $this->currentFilter = '.*(' . implode('|', $args) . ').*';
        }

        echo "Filtre configuré: {$this->currentFilter}\n";
        return $this;
    }

    /**
     * Configurer le chemin des tests
     */
    public function path(string $path): self
    {
        $this->currentTestPath = $path;
        echo "Chemin des tests configuré: {$path}\n";
        return $this;
    }

    /**
     * Méthodes de configuration rapides
     */
    public function debug(bool $enabled = true): self
    {
        return $this->server(['APP_DEBUG' => $enabled ? 'true' : 'false'])
            ->ini(['display_errors' => $enabled ? '1' : '0']);
    }

    public function noPreTest(): self
    {
        return $this->env('RUN_PRE_TEST', 'false');
    }

    public function preTest(bool $enabled = true): self
    {
        return $this->env('RUN_PRE_TEST', $enabled ? 'true' : 'false');
    }

    public function testEnv(string $env = 'test'): self
    {
        return $this->env('APP_ENV', $env);
    }

    public function verbose(): self
    {
        return $this->options('verbose');
    }

    public function testdox(): self
    {
        return $this->options('testdox');
    }

    public function stopOnFailure(): self
    {
        return $this->options('stop-on-failure');
    }

    // =================================================================
    // OPTIMISATIONS DE PERFORMANCE
    // =================================================================

    /**
     * Configuration rapide pour les tests unitaires
     */
    public function fast(): self
    {
        return $this->config([
            'env' => [
                'RUN_PRE_TEST' => 'false',
                'APP_ENV' => 'test',
                'KERNEL_CLASS' => 'App\Kernel',
                'SYMFONY_DEPRECATIONS_HELPER' => 'disabled',
                'PANTHER_NO_HEADLESS' => '0',
                'PANTHER_DEVTOOLS' => '0'
            ],
            'server' => [
                'APP_DEBUG' => 'false'
            ],
            'ini' => [
                'memory_limit' => '512M',
                'opcache.enable' => '1',
                'opcache.enable_cli' => '1',
                'opcache.validate_timestamps' => '0',
                'realpath_cache_size' => '4096k',
                'realpath_cache_ttl' => '600'
            ]
        ])
            ->options([
                'no-coverage' => true,
                'dont-report-useless-tests' => true,
                'order-by' => 'random',
                'cache-result' => true
            ]);
    }

    /**
     * Configuration ultra-rapide (désactive tout ce qui n'est pas essentiel)
     */
    public function ultraFast(): self
    {
        return $this->fast()
            ->options([
                'no-logging' => true,
                'no-progress' => true,
//                'no-results' => true,
                'no-output' => true,
            ])
            ->env([
                'SYMFONY_DEPRECATIONS_HELPER' => 'disabled',
                'PANTHER_NO_HEADLESS' => '1',
                'MAILER_DSN' => 'null://null'
            ]);
    }

    /**
     * Configuration pour tests en parallèle
     */
    public function parallel(?int $processes = null): array
    {
        $processes = $processes ?? (int) (shell_exec('nproc') ?: 4);

        return $this->options([
            'process-isolation' => true,
            'order-by' => 'random'
        ])
            ->env([
                'PARATEST_PROCESSES' => (string) $processes,
                'TEST_TOKEN' => uniqid()
            ]);
    }

    /**
     * Configuration pour tests avec cache
     */
    public function cached(): self
    {
        return $this->options([
            'cache-result' => true,
            'cache-result-file' => '.phpunit.result.cache'
        ])
            ->ini([
                'opcache.enable' => '1',
                'opcache.enable_cli' => '1'
            ]);
    }

    /**
     * Configuration pour tests sans base de données
     */
    public function noDatabase(): self
    {
        return $this->env([
            'DATABASE_URL' => 'sqlite:///:memory:',
            'DOCTRINE_FIXTURES_LOAD' => 'false'
        ]);
    }

    /**
     * Configuration pour tests sans réseau
     */
    public function offline(): self
    {
        return $this->env([
            'MAILER_DSN' => 'null://null',
            'HTTP_CLIENT_TIMEOUT' => '1',
            'DISABLE_EXTERNAL_CALLS' => 'true'
        ]);
    }

    /**
     * Mesurer le temps d'exécution
     */
    public function benchmark(): self
    {
        return $this->options([
            'log-timing' => true,
            'report-useless-tests' => true
        ]);
    }

    /**
     * Exécuter seulement les tests qui ont échoué la dernière fois
     */
    public function failedOnly(): self
    {
        return $this->options([
            'cache-result' => true,
            'order-by' => 'defects'
        ]);
    }

    // =================================================================
    // MÉTHODES DE RECHERCHE ET FILTRAGE AVANCÉES
    // =================================================================

    /**
     * Recherche fuzzy par mots-clés
     */
    public function search(mixed ...$args): self
    {
        if (count($args) === 1 && is_string($args[0])) {
            // Recherche simple
            $this->currentFilter = ".*{$args[0]}.*";
        } elseif (count($args) === 1 && is_array($args[0])) {
            // Recherche par tableau de mots-clés
            $this->currentFilter = '.*(' . implode('|', $args[0]) . ').*';
        } elseif (count($args) > 1) {
            // Recherche par arguments multiples
            $this->currentFilter = '.*(' . implode('|', $args) . ').*';
        }

        echo "Recherche configurée: {$this->currentFilter}\n";
        return $this;
    }



    /**
     * Recherche par nom de classe
     */
    public function byClass(string $className): self
    {
        $this->currentFilter = ".*{$className}.*";
        echo "Filtre par classe configuré: {$className}\n";
        return $this;
    }

    /**
     * Recherche par nom de méthode
     */
    public function byMethod(string $methodName): self
    {
        $this->currentFilter = ".*::{$methodName}.*";
        echo "Filtre par méthode configuré: {$methodName}\n";
        return $this;
    }

    /**
     * Recherche par testsuite
     */
    public function suite(string $suiteName): self
    {
        $this->testOptions['testsuite'] = $suiteName;
        echo "Testsuite configurée: {$suiteName}\n";
        return $this;
    }

    // =================================================================
    // CIBLAGE EXACT (SANS FUZZY SEARCH)
    // =================================================================

    /**
     * Cibler une classe de test exacte (NOUVEAU - utilise le chemin de fichier)
     */
    public function testClass(string $className): self
    {
        // Nettoyer le nom de classe
        $cleanClassName = $this->cleanClassName($className);

        // Essayer de trouver le fichier exact et l'ajouter au chemin
        $filePath = $this->findExactTestFile($cleanClassName);

        if ($filePath) {
            // Fichier trouvé : ajouter au chemin des tests (plus fiable que --filter)
            if ($this->currentTestPath) {
                $this->currentTestPath .= ' ' . escapeshellarg($filePath);
            } else {
                $this->currentTestPath = $filePath;
            }
            echo "✅ Classe ajoutée par fichier: {$filePath}\n";
        } else {
            // Fichier non trouvé : fallback sur le filtre (avec avertissement)
            echo "⚠️  Fichier non trouvé pour {$cleanClassName}, utilisation du filtre (peut être imprécis)\n";
            $exactPattern = $this->createExactClassPattern($cleanClassName);

            if ($this->currentFilter) {
                $this->currentFilter .= '|' . $exactPattern;
            } else {
                $this->currentFilter = $exactPattern;
            }
            echo "Pattern de fallback: {$exactPattern}\n";
        }

        return $this;
    }

    /**
     * Cibler plusieurs classes exactes (NOUVEAU - utilise les chemins de fichiers)
     */
    public function testClasses(array $classNames): self
    {
        $foundFiles = [];
        $notFoundClasses = [];

        foreach ($classNames as $className) {
            $cleanClassName = $this->cleanClassName($className);
            $filePath = $this->findExactTestFile($cleanClassName);

            if ($filePath) {
                $foundFiles[] = $filePath;
            } else {
                $notFoundClasses[] = $cleanClassName;
            }
        }

        // Ajouter les fichiers trouvés au chemin
        if (!empty($foundFiles)) {
            $escapedPaths = array_map('escapeshellarg', $foundFiles);

            if ($this->currentTestPath) {
                $this->currentTestPath .= ' ' . implode(' ', $escapedPaths);
            } else {
                $this->currentTestPath = implode(' ', $escapedPaths);
            }

            echo "✅ Classes ajoutées par fichiers: " . implode(', ', $foundFiles) . "\n";
        }

        // Fallback sur le filtre pour les classes non trouvées
        if (!empty($notFoundClasses)) {
            echo "⚠️  Classes non trouvées (fallback filtre): " . implode(', ', $notFoundClasses) . "\n";

            $patterns = [];
            foreach ($notFoundClasses as $className) {
                $patterns[] = $this->createExactClassPattern($className);
            }

            $combinedPattern = implode('|', $patterns);

            if ($this->currentFilter) {
                $this->currentFilter .= '|' . $combinedPattern;
            } else {
                $this->currentFilter = $combinedPattern;
            }
        }

        return $this;
    }

    /**
     * Cibler une méthode de test exacte (CORRIGÉ)
     */
    public function testMethod(string $className, string $methodName): self
    {
        $cleanClassName = $this->cleanClassName($className);
        $cleanMethodName = $this->cleanMethodName($methodName);

        // Pattern exact pour classe::méthode
        $exactPattern = $this->createExactMethodPattern($cleanClassName, $cleanMethodName);

        if ($this->currentFilter) {
            $this->currentFilter .= '|' . $exactPattern;
        } else {
            $this->currentFilter = $exactPattern;
        }

        echo "Méthode de test ajoutée (exact): {$cleanClassName}::{$cleanMethodName}\n";
        echo "Pattern utilisé: {$exactPattern}\n";
        return $this;
    }

    /**
     * Cibler plusieurs méthodes exactes (CORRIGÉ)
     */
    public function testMethods(array $methods): self
    {
        $patterns = [];
        foreach ($methods as $method) {
            if (str_contains($method, '::')) {
                [$className, $methodName] = explode('::', $method, 2);
                $cleanClassName = $this->cleanClassName($className);
                $cleanMethodName = $this->cleanMethodName($methodName);
                $patterns[] = $this->createExactMethodPattern($cleanClassName, $cleanMethodName);
            }
        }

        $combinedPattern = implode('|', $patterns);

        if ($this->currentFilter) {
            $this->currentFilter .= '|' . $combinedPattern;
        } else {
            $this->currentFilter = $combinedPattern;
        }

        echo "Méthodes de test ajoutées (exact): " . implode(', ', $methods) . "\n";
        return $this;
    }

    /**
     * Cibler un fichier de test exact
     */
    public function testFile(string $filePath): self
    {
        if ($this->currentTestPath) {
            $this->currentTestPath .= ' ' . escapeshellarg($filePath);
        } else {
            $this->currentTestPath = $filePath;
        }

        echo "Fichier de test ajouté: {$filePath}\n";
        return $this;
    }

    /**
     * Cibler plusieurs fichiers de tests exacts
     */
    public function testFiles(array $filePaths): self
    {
        $escapedPaths = array_map('escapeshellarg', $filePaths);

        if ($this->currentTestPath) {
            $this->currentTestPath .= ' ' . implode(' ', $escapedPaths);
        } else {
            $this->currentTestPath = implode(' ', $escapedPaths);
        }

        echo "Fichiers de test ajoutés: " . implode(', ', $filePaths) . "\n";
        return $this;
    }

    /**
     * Cibler par namespace exact
     */
    public function testNamespace(string $namespace): self
    {
        // Approche plus simple pour les namespaces
        $this->currentFilter = str_replace('\\', '\\\\', $namespace);
        echo "Namespace de test ciblé: {$namespace}\n";
        return $this;
    }

    /**
     * Méthodes de convenance pour les patterns courants
     */
    public function unitTest(string $className): self
    {
        return $this->testFile("tests/Unit/{$className}.php");
    }

    public function integrationTest(string $className): self
    {
        return $this->testFile("tests/Integration/{$className}.php");
    }

    public function functionalTest(string $className): self
    {
        return $this->testFile("tests/Functional/{$className}.php");
    }

    public function apiTest(string $className): self
    {
        return $this->testFile("tests/Api/{$className}.php");
    }

    /**
     * Cibler par annotation/attribut
     */
    public function withGroup(string $groupName): self
    {
        $this->testOptions['group'] = $groupName;
        echo "Groupe de test ciblé: {$groupName}\n";
        return $this;
    }

    public function excludeGroup(string $groupName): self
    {
        $this->testOptions['exclude-group'] = $groupName;
        echo "Groupe de test exclu: {$groupName}\n";
        return $this;
    }

    /**
     * Cibler par type de test (via annotations)
     */
    public function smallTests(): self
    {
        return $this->withGroup('small');
    }

    public function mediumTests(): self
    {
        return $this->withGroup('medium');
    }

    public function largeTests(): self
    {
        return $this->withGroup('large');
    }

    // =================================================================
    // MÉTHODES UTILITAIRES POUR TROUVER LES FICHIERS EXACTS
    // =================================================================

    /**
     * Trouver le chemin exact d'un fichier de test
     */
    private function findExactTestFile(string $className): ?string
    {
        // Ordre de priorité des répertoires de tests
        $testDirs = array_map(
            fn (string $dir) => str_replace($this->projectDir . '/', '', $dir),
            array_filter(glob($this->projectDir . '/tests/*'), 'is_dir')
        );

        foreach ($testDirs as $dir) {
            $path = "{$dir}/{$className}.php";
            $fullPath = $this->projectDir . '/' . $path;

            if (file_exists($fullPath)) {
                return $path;
            }
        }

        return null;
    }

    /**
     * Nettoyer le nom de classe (enlever préfixes/suffixes parasites)
     */
    private function cleanClassName(string $className): string
    {
        // Enlever les caractères parasites comme ** en début/fin
        $cleaned = trim($className, '*');

        // Enlever les espaces
        $cleaned = trim($cleaned);

        // Si c'est un chemin de fichier, extraire juste le nom de classe
        if (str_contains($cleaned, '/') && str_ends_with($cleaned, '.php')) {
            $cleaned = basename($cleaned, '.php');
        }

        // Enlever le namespace si présent, garder juste le nom de classe
        if (str_contains($cleaned, '\\')) {
            $parts = explode('\\', $cleaned);
            $cleaned = end($parts);
        }

        return $cleaned;
    }

    /**
     * Nettoyer le nom de méthode
     */
    private function cleanMethodName(string $methodName): string
    {
        return trim($methodName, '*');
    }

    /**
     * Créer un pattern regex exact pour une classe
     */
    private function createExactClassPattern(string $className): string
    {
        // Pattern qui matche exactement le nom de classe (pas les sous-chaînes)
        // Utilise des word boundaries (\b) pour éviter les matches partiels
        return '\\b' . preg_quote($className, '/') . '\\b';
    }

    /**
     * Créer un pattern regex exact pour une méthode
     */
    private function createExactMethodPattern(string $className, string $methodName): string
    {
        return '\\b' . preg_quote($className, '/') . '::' . preg_quote($methodName, '/') . '\\b';
    }

    /**
     * Méthode de debug pour voir les patterns générés
     */
    public function debugFilter(): void
    {
        echo "=== DEBUG FILTER ===\n";
        echo "Filtre actuel: " . ($this->currentFilter ?? 'AUCUN') . "\n";

        if ($this->currentFilter) {
            echo "Patterns individuels:\n";
            $patterns = explode('|', $this->currentFilter);
            foreach ($patterns as $i => $pattern) {
                echo "  [$i] $pattern\n";
            }
        }
        echo "===================\n";
    }

    /**
     * Test du pattern sur un exemple
     */
    public function testPattern(string $testExample): bool
    {
        if (!$this->currentFilter) {
            echo "Aucun filtre défini\n";
            return false;
        }

        $matches = preg_match('/' . $this->currentFilter . '/', $testExample);
        echo "Test pattern sur '$testExample': " . ($matches ? "✅ MATCH" : "❌ NO MATCH") . "\n";

        return (bool) $matches;
    }

    /**
     * Alternative: utiliser --filter avec des patterns plus précis
     */
    public function testClassExact(string $className): self
    {
        $cleanClassName = $this->cleanClassName($className);

        // Utiliser un pattern très strict qui évite les matches partiels
        $strictPattern = '^.*\\\\?' . preg_quote($cleanClassName, '/') . '$';

        if ($this->currentFilter) {
            $this->currentFilter .= '|' . $strictPattern;
        } else {
            $this->currentFilter = $strictPattern;
        }

        echo "Classe de test ajoutée (très exact): {$cleanClassName}\n";
        echo "Pattern strict: {$strictPattern}\n";
        return $this;
    }

    /**
     * Alternative plus robuste: utiliser le chemin de fichier au lieu du filtre
     */
    public function testClassByFile(string $className): self
    {
        $cleanClassName = $this->cleanClassName($className);

        // Essayer de trouver le fichier exact
        $possiblePaths = array_map(
            fn (string $dir) => str_replace($this->projectDir.'/', '', $dir)."/PsyshTestService.php",
            array_filter(glob($this->projectDir . '/tests/*'), 'is_dir')
        );

        foreach ($possiblePaths as $path) {
            $fullPath = $this->projectDir . '/' . $path;
            if (file_exists($fullPath)) {
                return $this->testFile($path);
            }
        }

        echo "⚠️  Fichier non trouvé pour {$cleanClassName}, utilisation du filtre exact\n";
        return $this->testClassExact($cleanClassName);
    }

    /**
     * Méthode intelligente qui combine plusieurs approches
     */
    public function smartTest(string $className): self
    {
        $cleanClassName = $this->cleanClassName($className);

        echo "🔍 Test intelligent pour: {$cleanClassName}\n";

        // 1. Essayer de trouver le fichier exact (plus fiable)
        $possiblePaths = array_map(
            fn (string $dir) => str_replace($this->projectDir.'/', '', $dir)."/PsyshTestService.php",
            array_filter(glob($this->projectDir . '/tests/*'), 'is_dir')
        );

        foreach ($possiblePaths as $path) {
            $fullPath = $this->projectDir . '/' . $path;
            if (file_exists($fullPath)) {
                echo "✅ Trouvé: {$path}\n";
                return $this->testFile($path);
            }
        }

        // 2. Si fichier non trouvé, utiliser le pattern exact
        echo "⚠️  Fichier non trouvé, utilisation du pattern exact\n";
        return $this->testClassExact($cleanClassName);
    }

    /**
     * Trouver le chemin d'un test (utilitaire de debug)
     */
    public function findTestPath(string $className): ?string
    {
        $cleanClassName = $this->cleanClassName($className);
        $foundPath = $this->findExactTestFile($cleanClassName);

        if ($foundPath) {
            echo "✅ {$cleanClassName} trouvé : {$foundPath}\n";
            return $foundPath;
        }

        echo "❌ {$cleanClassName} non trouvé\n";
        echo "Répertoires vérifiés :\n";

        $testDirs = array_map(
            fn (string $dir) => str_replace($this->projectDir . '/', '', $dir),
            array_filter(glob($this->projectDir . '/tests/*'), 'is_dir')
        );

        foreach ($testDirs as $dir) {
            $path = "{$dir}/{$cleanClassName}.php";
            echo "  - {$path}\n";
        }

        return null;
    }

    /**
     * Debug: chercher toutes les classes qui contiennent le nom
     */
    public function findTestsByClass(string $className): array
    {
        $cleanClassName = $this->cleanClassName($className);
        $found = [];

        $testDirs = array_map(
            fn (string $dir) => str_replace($this->projectDir . '/', '', $dir),
            array_filter(glob($this->projectDir . '/tests/*'), 'is_dir')
        );

        foreach ($testDirs as $dir) {
            $fullDir = $this->projectDir . '/' . $dir;
            if (!is_dir($fullDir)) continue;

            $files = glob($fullDir . '/*Test.php');
            foreach ($files as $file) {
                $filename = basename($file, '.php');
                if (str_contains($filename, $cleanClassName)) {
                    $relativePath = str_replace($this->projectDir . '/', '', $file);
                    $found[] = $relativePath;
                }
            }
        }

        echo "🔍 Tests trouvés contenant '{$cleanClassName}':\n";
        foreach ($found as $path) {
            echo "  - {$path}\n";
        }

        return $found;
    }

    /**
     * Afficher la configuration de ciblage actuelle
     */
    public function showTargeting(): void
    {
        echo "=== CONFIGURATION DE CIBLAGE ===\n";

        if ($this->currentTestPath) {
            echo "📁 Fichiers de tests ciblés :\n";
            $paths = explode(' ', $this->currentTestPath);
            foreach ($paths as $path) {
                $cleanPath = trim($path, '"\'');
                echo "  - {$cleanPath}\n";
            }
        }

        if ($this->currentFilter) {
            echo "🔍 Filtres regex :\n";
            $patterns = explode('|', $this->currentFilter);
            foreach ($patterns as $i => $pattern) {
                echo "  [$i] {$pattern}\n";
            }
        }

        if (!$this->currentTestPath && !$this->currentFilter) {
            echo "Aucun ciblage défini (tous les tests seront exécutés)\n";
        }

        echo "===============================\n";
    }

    // =================================================================
    // MÉTHODES D'EXÉCUTION DES TESTS
    // =================================================================

    /**
     * Méthode principale - lance les tests avec toute la configuration
     */
    public function runTest(mixed ...$args): int
    {
        $command = ['vendor/bin/phpunit'];

        // Utiliser la configuration persistante si elle existe
        if ($this->persistentConfigPath && file_exists($this->persistentConfigPath)) {
            $command[] = '-c';
            $command[] = $this->persistentConfigPath;
        }

        // Ajouter le filtre si configuré
        if ($this->currentFilter) {
            $command[] = '--filter';
            $command[] = escapeshellarg($this->currentFilter);
        }

        // Ajouter les options de test
        foreach ($this->testOptions as $key => $value) {
            if (is_numeric($key)) {
                $command[] = $value;
            } else {
                $command[] = "--{$key}";
                if ($value !== true) {
                    $command[] = $value;
                }
            }
        }

        // Traiter les arguments
        if (count($args) === 1 && is_string($args[0])) {
            // runTest('tests/Api/CandidateTest.php')
            $command[] = $args[0];
        } elseif (count($args) === 2) {
            // runTest('tests/Api/CandidateTest.php', 'testCreate')
            if (!$this->currentFilter) {
                $command[] = '--filter';
                $command[] = $args[1];
            }
            $command[] = $args[0];
        } elseif ($this->currentTestPath) {
            // Utiliser le chemin configuré
            $command[] = $this->currentTestPath;
        }

        $commandStr = implode(' ', $command);
        echo "Exécution: $commandStr\n";

        system($commandStr, $returnCode);

        return $returnCode;
    }

    /**
     * Lancer les tests avec la configuration actuelle (sans arguments)
     */
    public function run(): int
    {
        return $this->runTest();
    }

    // =================================================================
    // HELPER ET DOCUMENTATION
    // =================================================================

    /**
     * Afficher l'aide complète
     */
    public function help(): void
    {
        echo $this->getHelpText();
    }

    /**
     * Afficher l'aide rapide
     */
    public function quickHelp(): void
    {
        echo $this->getQuickHelpText();
    }

    /**
     * Lister toutes les méthodes disponibles
     */
    public function methods(): array
    {
        $methods = [
            'Configuration' => [
                'config(...args)' => 'Configuration générale flexible',
                'env(...args)' => 'Variables d\'environnement',
                'server(...args)' => 'Variables serveur',
                'ini(...args)' => 'Directives PHP',
                'options(...args)' => 'Options PHPUnit',
                'filter(...args)' => 'Filtre de tests',
                'path($path)' => 'Chemin des tests'
            ],
            'Configuration rapide' => [
                'debug($enabled = true)' => 'Mode debug',
                'noPreTest()' => 'Désactiver RUN_PRE_TEST',
                'preTest($enabled = true)' => 'Activer/désactiver RUN_PRE_TEST',
                'testEnv($env = "test")' => 'Environnement de test',
                'verbose()' => 'Mode verbose',
                'testdox()' => 'Format testdox',
                'stopOnFailure()' => 'Arrêter au premier échec'
            ],
            'Ciblage exact' => [
                'testClass($className)' => 'Cibler une classe exacte',
                'testMethod($className, $methodName)' => 'Cibler une méthode exacte',
                'testClasses($classNames)' => 'Cibler plusieurs classes exactes',
                'testMethods($methods)' => 'Cibler plusieurs méthodes exactes',
                'testFile($filePath)' => 'Cibler un fichier exact',
                'testFiles($filePaths)' => 'Cibler plusieurs fichiers',
                'testNamespace($namespace)' => 'Cibler par namespace exact',
                'unitTest($className)' => 'Test unitaire (tests/Unit/)',
                'integrationTest($className)' => 'Test d\'intégration (tests/Integration/)',
                'functionalTest($className)' => 'Test fonctionnel (tests/Functional/)',
                'apiTest($className)' => 'Test API (tests/Api/)',
                'withGroup($groupName)' => 'Cibler par groupe',
                'excludeGroup($groupName)' => 'Exclure un groupe',
                'smallTests()' => 'Tests petits (@group small)',
                'mediumTests()' => 'Tests moyens (@group medium)',
                'largeTests()' => 'Tests larges (@group large)',
                'smartTest($className)' => 'Test intelligent (trouve auto le fichier)',
                'findTestPath($className)' => 'Trouver le chemin d\'un test',
                'findTestsByClass($className)' => 'Debug - chercher une classe'
            ],
            'Optimisations' => [
                'fast()' => 'Configuration rapide',
                'ultraFast()' => 'Configuration ultra-rapide',
                'parallel($processes = null)' => 'Tests en parallèle',
                'cached()' => 'Tests avec cache',
                'noDatabase()' => 'Tests sans base de données',
                'offline()' => 'Tests sans réseau',
                'benchmark()' => 'Mesurer les performances',
                'failedOnly()' => 'Seulement les tests échoués'
            ],
            'Recherche fuzzy' => [
                'search(...args)' => 'Recherche fuzzy',
                'byClass($className)' => 'Recherche par classe (fuzzy)',
                'byMethod($methodName)' => 'Recherche par méthode (fuzzy)',
                'suite($suiteName)' => 'Recherche par testsuite'
            ],
            'Exécution' => [
                'runTest(...args)' => 'Lancer les tests',
                'run()' => 'Lancer avec configuration actuelle',
                'listTests()' => 'Lister les tests correspondants'
            ],
            'Gestion d\'état' => [
                'showConfig()' => 'Afficher la configuration',
                'reset()' => 'Réinitialiser',
                'save($name = "default")' => 'Sauvegarder la configuration',
                'load($name = "default")' => 'Charger une configuration'
            ],
            'Aide' => [
                'help()' => 'Aide complète',
                'quickHelp()' => 'Aide rapide',
                'methods()' => 'Liste des méthodes',
                'examples()' => 'Exemples d\'utilisation'
            ]
        ];

        foreach ($methods as $category => $categoryMethods) {
            echo "\n\033[1;33m=== {$category} ===\033[0m\n";
            foreach ($categoryMethods as $method => $description) {
                echo sprintf("  \033[1;32m%-35s\033[0m %s\n", $method, $description);
            }
        }

        return $methods;
    }

    /**
     * Afficher des exemples d'utilisation
     */
    public function examples(): void
    {
        echo $this->getExamplesText();
    }

    /**
     * Afficher les configurations prédéfinies
     */
    public function presets(): void
    {
        echo $this->getPresetsText();
    }

    private function getHelpText(): string
    {
        return "
\033[1;36m╔════════════════════════════════════════════════════════════════════════════════════════╗
║                                 PSYSH PHPUNIT HELPER                                   ║
╚════════════════════════════════════════════════════════════════════════════════════════╝\033[0m

\033[1;33m🚀 UTILISATION RAPIDE\033[0m
\$psysh->noPreTest()->debug()->verbose()->filter('Candidate')->runTest();

\033[1;33m⚡ OPTIMISATIONS DE PERFORMANCE\033[0m
• \033[1;32mfast()\033[0m           - Configuration rapide standard
• \033[1;32multraFast()\033[0m      - Configuration ultra-rapide (minimal)
• \033[1;32mparallel(\$n)\033[0m     - Tests en parallèle (n processus)
• \033[1;32mcached()\033[0m         - Utilise le cache PHPUnit
• \033[1;32mnoDatabase()\033[0m     - Tests sans base de données
• \033[1;32moffline()\033[0m        - Tests sans réseau
• \033[1;32mbenchmark()\033[0m      - Mesure les performances
• \033[1;32mfailedOnly()\033[0m     - Seulement les tests échoués

\033[1;33m🔧 CONFIGURATION FLEXIBLE\033[0m
• \033[1;32mconfig(\$array)\033[0m  - Configuration complète
• \033[1;32menv(\$key, \$value)\033[0m - Variables d'environnement
• \033[1;32mserver(\$key, \$value)\033[0m - Variables serveur
• \033[1;32mini(\$key, \$value)\033[0m - Directives PHP
• \033[1;32moptions(\$key, \$value)\033[0m - Options PHPUnit

\033[1;33m🎯 CIBLAGE EXACT (CUMULATIF)\033[0m
• \033[1;32mtestClass(\$name)\033[0m - Cibler une classe (cumulable)
• \033[1;32mtestClasses(\$array)\033[0m - Cibler plusieurs classes
• \033[1;32mtestMethod(\$class, \$method)\033[0m - Cibler une méthode (cumulable)
• \033[1;32mtestMethods(\$array)\033[0m - Cibler plusieurs méthodes
• \033[1;32mtestFile(\$path)\033[0m - Cibler un fichier (cumulable)
• \033[1;32mtestFiles(\$array)\033[0m - Cibler plusieurs fichiers
• \033[1;32mtestNamespace(\$ns)\033[0m - Par namespace
• \033[1;32munitTest(\$name)\033[0m - Test unitaire (tests/Unit/)
• \033[1;32mapiTest(\$name)\033[0m - Test API (tests/Api/)
• \033[1;32mintegrationTest(\$name)\033[0m - Test intégration (tests/Integration/)
• \033[1;32mfunctionalTest(\$name)\033[0m - Test fonctionnel (tests/Functional/)

\033[1;33m🔍 RECHERCHE ET FILTRAGE\033[0m
• \033[1;32mfilter(\$pattern)\033[0m - Filtre regex
• \033[1;32msearch(\$keywords...)\033[0m - Recherche fuzzy
• \033[1;32mbyClass(\$name)\033[0m - Par nom de classe (fuzzy)
• \033[1;32mbyMethod(\$name)\033[0m - Par nom de méthode (fuzzy)
• \033[1;32msuite(\$name)\033[0m - Par testsuite
• \033[1;32mwithGroup(\$group)\033[0m - Par groupe (@group)
• \033[1;32mexcludeGroup(\$group)\033[0m - Exclure un groupe
• \033[1;32msmallTests()\033[0m - Tests petits (@group small)
• \033[1;32mmediumTests()\033[0m - Tests moyens (@group medium)
• \033[1;32mlargeTests()\033[0m - Tests larges (@group large)

\033[1;33m🛠️ UTILITAIRES ET DEBUG\033[0m
• \033[1;32msmartTest(\$name)\033[0m - Test intelligent (auto-détection)
• \033[1;32mfindTestPath(\$name)\033[0m - Trouver le chemin d'un test
• \033[1;32mfindTestsByClass(\$name)\033[0m - Debug - chercher une classe
• \033[1;32mlistTests()\033[0m - Lister les tests correspondants

\033[1;33m💾 GESTION D'ÉTAT\033[0m
• \033[1;32msave(\$name)\033[0m - Sauvegarder la configuration
• \033[1;32mload(\$name)\033[0m - Charger une configuration
• \033[1;32mreset()\033[0m - Réinitialiser tout
• \033[1;32mshowConfig()\033[0m - Voir la configuration actuelle

\033[1;33m▶️ EXÉCUTION\033[0m
• \033[1;32mrunTest(...args)\033[0m - Lancer les tests avec arguments
• \033[1;32mrun()\033[0m - Lancer avec configuration actuelle

\033[1;33m📖 AIDE\033[0m
• \033[1;32mhelp()\033[0m - Cette aide
• \033[1;32mquickHelp()\033[0m - Aide rapide
• \033[1;32mmethods()\033[0m - Liste des méthodes
• \033[1;32mexamples()\033[0m - Exemples d'utilisation
• \033[1;32mpresets()\033[0m - Configurations prédéfinies

\033[1;33m🎯 EXEMPLES CUMULATIFS\033[0m
\$psysh->testClass('FooTest')->testClass('BarTest')->testClasses(['FooBarTest', 'FooBar2Test'])->run();
\$psysh->testFile('tests/Unit/FooTest.php')->testFile('tests/Api/BarTest.php')->run();
\$psysh->testMethod('FooTest', 'testCreate')->testMethod('BarTest', 'testUpdate')->run();

\033[1;33m🎯 EXEMPLES RAPIDES\033[0m
\$psysh->examples();
";
    }

    private function getQuickHelpText(): string
    {
        return "
\033[1;36m🚀 PSYSH PHPUNIT - AIDE RAPIDE (AVEC CUMUL)\033[0m

\033[1;33mMÉTHODE RECOMMANDÉE (smart test):\033[0m
• \$psysh->smartTest('CandidateApiTest')        # Auto-détection du fichier

\033[1;33mCIBLAGE CUMULATIF (NOUVEAU !):\033[0m
• \$psysh->testClass('FooTest')->testClass('BarTest')->run()
• \$psysh->testClass('FooTest')->testClasses(['BarTest', 'BazTest'])->run()
• \$psysh->testFile('tests/Unit/FooTest.php')->testFile('tests/Api/BarTest.php')->run()

\033[1;33mConfigurations rapides:\033[0m
• \$psysh->fast()->testClass('CandidateApiTest')     # Configuration rapide
• \$psysh->ultraFast()->testClass('FooTest')->testClass('BarTest')  # Ultra-rapide
• \$psysh->noPreTest()->debug()->verbose()->testClass('CandidateApiTest')

\033[1;33mCiblage exact (sans erreurs shell):\033[0m
• \$psysh->testFile('tests/Api/CandidateApiTest.php')->run()    # Le plus fiable
• \$psysh->testClass('CandidateApiTest')->run()                # Filtre simple
• \$psysh->smartTest('CandidateApiTest')                       # Auto-détection

\033[1;33mDebugging:\033[0m
• \$psysh->findTestPath('CandidateApiTest')         # Où est le fichier ?
• \$psysh->findTestsByClass('CandidateApiTest')     # Voir toutes les classes
• \$psysh->showConfig()                             # Configuration actuelle

\033[1;33mWorkflow avec cumul:\033[0m
• \$psysh->fast()->noPreTest()->debug()             # Configurer une fois
• \$psysh->testClass('CandidateApiTest')            # Ajouter test 1
• \$psysh->testClass('UserApiTest')                 # Ajouter test 2
• \$psysh->apiTest('AdminApiTest')                  # Ajouter test 3
• \$psysh->run()                                    # Lancer tous

";
    }

    private function getExamplesText(): string {
        return "
\033[1;36m📖 EXEMPLES D'UTILISATION (AVEC CUMUL)\033[0m

\033[1;33m🎯 CIBLAGE CUMULATIF (NOUVEAU !)\033[0m
# Plusieurs classes en chaînage
\$psysh->testClass('FooTest')->testClass('BarTest')->run();

# Mélange classes individuelles et groupées
\$psysh->testClass('FooTest')->testClasses(['BarTest', 'BazTest'])->run();

# Plusieurs fichiers en chaînage
\$psysh->testFile('tests/Unit/FooTest.php')->testFile('tests/Api/BarTest.php')->run();

# Mélange méthodes de différentes classes
\$psysh->testMethod('FooTest', 'testCreate')
      ->testMethod('BarTest', 'testUpdate')
      ->testMethod('BazTest', 'testDelete')
      ->run();

# Combinaison complexe
\$psysh->testClass('UserTest')
      ->apiTest('UserApiTest')
      ->testMethod('AdminTest', 'testPermissions')
      ->testFile('/Integration/UserIntegrationTest.php')
      ->run();

\033[1;33m⚡ OPTIMISATIONS AVEC CUMUL\033[0m
# Ultra-rapide sur plusieurs classes
\$psysh->ultraFast()
      ->testClass('FooTest')
      ->testClass('BarTest')
      ->testClasses(['BazTest', 'QuxTest'])
      ->run();

# Tests en parallèle sur plusieurs types
\$psysh->parallel(4)
      ->unitTest('UserTest')
      ->apiTest('UserApiTest')
      ->integrationTest('UserIntegrationTest')
      ->run();

\033[1;33m🔧 WORKFLOWS AVANCÉS\033[0m
# Configuration + tests multiples
\$psysh->fast()->noPreTest()->debug()
      ->testClass('CandidateApiTest')
      ->testClass('StudentApiTest')
      ->testClass('AdminApiTest')
      ->run();

# Tests par feature complète
\$psysh->ultraFast()
      ->testClass('UserTest')                    # Tests unitaires
      ->apiTest('UserApiTest')                   # Tests API
      ->integrationTest('UserIntegrationTest')   # Tests d'intégration
      ->functionalTest('UserFunctionalTest')     # Tests fonctionnels
      ->run();

\033[1;33m🔍 COMPARAISON FUZZY vs EXACT vs CUMULATIF\033[0m
# Fuzzy (trouve tout ce qui contient 'User')
\$psysh->search('User')->run();

# Exact (classes spécifiques)
\$psysh->testClasses(['UserTest', 'UserApiTest', 'UserServiceTest'])->run();

# Cumulatif (ajouter au fur et à mesure)
\$psysh->testClass('UserTest')
      ->testClass('UserApiTest')
      ->testClass('UserServiceTest')
      ->run();

\033[1;33m🚨 DEBUGGING AVEC CUMUL\033[0m
# Vérifier plusieurs fichiers
\$psysh->findTestPath('FooTest');
\$psysh->findTestPath('BarTest');

# Tester intelligemment plusieurs classes
\$psysh->smartTest('FooTest'); # Premier test
\$psysh->testClass('BarTest')->run(); # Ajouter un autre

# Lister avant d'exécuter
\$psysh->testClass('FooTest')
      ->testClass('BarTest')
      ->listTests(); # Voir ce qui sera exécuté

\033[1;33m💾 WORKFLOWS AVEC SAUVEGARDE\033[0m
# Configurer et sauvegarder un set de tests
\$psysh->fast()->noPreTest()
      ->testClass('UserTest')
      ->testClass('AdminTest')
      ->testClass('RoleTest')
      ->save('user_management_tests');

# Réutiliser et ajouter
\$psysh->load('user_management_tests')
      ->testClass('PermissionTest')  # Ajouter un test
      ->run();

# Set de tests par module
\$psysh->ultraFast()
      ->unitTest('UserTest')
      ->unitTest('AdminTest')
      ->save('unit_user_module');

\$psysh->fast()
      ->apiTest('UserApiTest')
      ->apiTest('AdminApiTest')
      ->save('api_user_module');

\033[1;33m🚀 EXEMPLES PRATIQUES\033[0m
# Feature complète en développement
\$psysh->debug()->verbose()->stopOnFailure()
      ->testMethod('UserTest', 'testNewFeature')
      ->testMethod('UserApiTest', 'testNewFeatureApi')
      ->run();

# Régression sur un module
\$psysh->fast()
      ->testClass('UserTest')
      ->testClass('UserServiceTest')
      ->testClass('UserRepositoryTest')
      ->testClass('UserValidatorTest')
      ->run();

# Tests de performance sur plusieurs composants
\$psysh->benchmark()->cached()
      ->testClass('DatabaseTest')
      ->testClass('CacheTest')
      ->testClass('ApiPerformanceTest')
      ->run();
";
    }

    private function getPresetsText(): string {
        return "
\033[1;36m🎯 CONFIGURATIONS PRÉDÉFINIES\033[0m

\033[1;33m⚡ PERFORMANCES\033[0m
• \033[1;32mfast()\033[0m - Configuration rapide standard
  └─ Désactive RUN_PRE_TEST, optimise PHP, cache activé
• \033[1;32multraFast()\033[0m - Configuration ultra-rapide
  └─ Comme fast() + mode silencieux, pas de logs
• \033[1;32mparallel(\$n)\033[0m - Tests en parallèle
  └─ Processus multiples, isolation des tests
• \033[1;32mcached()\033[0m - Utilise le cache PHPUnit
  └─ Cache des résultats, opcache activé

\033[1;33m🔧 ENVIRONNEMENT\033[0m
• \033[1;32mnoDatabase()\033[0m - Tests sans base de données
  └─ SQLite en mémoire, pas de fixtures
• \033[1;32moffline()\033[0m - Tests sans réseau
  └─ Mailer null, timeout court, appels externes désactivés
• \033[1;32mdebug()\033[0m - Mode debug
  └─ APP_DEBUG=true, erreurs affichées
• \033[1;32mverbose()\033[0m - Mode verbose
  └─ Sortie détaillée des tests

\033[1;33m📊 ANALYSE\033[0m
• \033[1;32mbenchmark()\033[0m - Mesure les performances
  └─ Log des temps, détection des tests inutiles
• \033[1;32mfailedOnly()\033[0m - Seulement les tests échoués
  └─ Réexécute uniquement les tests qui ont échoué

\033[1;33m🎮 UTILISATION\033[0m
# Ultra-rapide pour développement
\$psysh->ultraFast()->search('MyFeature')->run();

# Tests d'intégration optimisés
\$psysh->fast()->noDatabase()->suite('integration')->run();

# Debug d'un test spécifique
\$psysh->debug()->verbose()->stopOnFailure()->byClass('MyTest')->run();

# Performance testing
\$psysh->benchmark()->parallel(8)->cached()->run();
";
    }

    /**
     * Afficher la configuration actuelle
     */
    public function showConfig(): array
    {
        $config = [
            'phpunit_config' => $this->currentConfig,
            'test_options' => $this->testOptions,
            'filter' => $this->currentFilter,
            'test_path' => $this->currentTestPath,
            'config_file' => $this->persistentConfigPath
        ];

        echo "Configuration actuelle:\n";
        echo json_encode($config, JSON_PRETTY_PRINT) . "\n";

        return $config;
    }

    /**
     * Réinitialiser toute la configuration
     */
    public function reset(): self
    {
        if ($this->persistentConfigPath && file_exists($this->persistentConfigPath)) {
            unlink($this->persistentConfigPath);
        }

        $this->persistentConfigPath = null;
        $this->currentConfig = [];
        $this->testOptions = [];
        $this->currentFilter = null;
        $this->currentTestPath = null;

        echo "Configuration réinitialisée.\n";
        return $this;
    }

    /**
     * Sauvegarder la configuration actuelle
     */
    public function save(string $name = 'default'): self
    {
        $config = [
            'phpunit_config' => $this->currentConfig,
            'test_options' => $this->testOptions,
            'filter' => $this->currentFilter,
            'test_path' => $this->currentTestPath
        ];

        $configFile = $this->projectDir . "/psysh_config_{$name}.json";
        file_put_contents($configFile, json_encode($config, JSON_PRETTY_PRINT));

        echo "Configuration sauvegardée dans: {$configFile}\n";
        return $this;
    }

    /**
     * Charger une configuration sauvegardée
     */
    public function load(string $name = 'default'): self
    {
        $configFile = $this->projectDir . "/psysh_config_{$name}.json";

        if (!file_exists($configFile)) {
            echo "Configuration '{$name}' non trouvée.\n";
            return $this;
        }

        $config = json_decode(file_get_contents($configFile), true);

        $this->currentConfig = $config['phpunit_config'] ?? [];
        $this->testOptions = $config['test_options'] ?? [];
        $this->currentFilter = $config['filter'] ?? null;
        $this->currentTestPath = $config['test_path'] ?? null;

        $this->applyConfig();

        echo "Configuration '{$name}' chargée.\n";
        return $this;
    }

    // =================================================================
    // MÉTHODES PRIVÉES
    // =================================================================

    private function applyConfig(): void
    {
        if (!empty($this->currentConfig)) {
            $this->persistentConfigPath = $this->createCustomPhpunitConfig($this->currentConfig);
            echo "Configuration PHPUnit mise à jour.\n";
        }
    }

    private function createCustomPhpunitConfig(array $options = []): string
    {
        $configPath = $this->projectDir . '/phpunit.xml.dist';
        $tempConfigPath = $this->projectDir . '/phpunit.psysh.xml';

        if (!file_exists($configPath)) {
            throw new \RuntimeException('phpunit.xml.dist non trouvé');
        }

        $xml = simplexml_load_file($configPath);

        // Modifier les variables d'environnement
        if (isset($options['env'])) {
            $phpSection = $xml->php;
            if (!$phpSection) {
                $phpSection = $xml->addChild('php');
            }

            foreach ($options['env'] as $name => $value) {
                $found = false;
                foreach ($phpSection->env as $envVar) {
                    if ((string) $envVar['name'] === $name) {
                        $envVar['value'] = $value;
                        $found = true;
                        break;
                    }
                }

                if (!$found) {
                    $envVar = $phpSection->addChild('env');
                    $envVar->addAttribute('name', $name);
                    $envVar->addAttribute('value', $value);
                }
            }
        }

        // Modifier les variables serveur
        if (isset($options['server'])) {
            $phpSection = $xml->php ?? $xml->addChild('php');

            foreach ($options['server'] as $name => $value) {
                $found = false;
                foreach ($phpSection->server as $serverVar) {
                    if ((string) $serverVar['name'] === $name) {
                        $serverVar['value'] = $value;
                        $found = true;
                        break;
                    }
                }

                if (!$found) {
                    $serverVar = $phpSection->addChild('server');
                    $serverVar->addAttribute('name', $name);
                    $serverVar->addAttribute('value', $value);
                }
            }
        }

        // Modifier les directives PHP
        if (isset($options['ini'])) {
            $phpSection = $xml->php ?? $xml->addChild('php');

            foreach ($options['ini'] as $name => $value) {
                $found = false;
                foreach ($phpSection->ini as $iniVar) {
                    if ((string) $iniVar['name'] === $name) {
                        $iniVar['value'] = $value;
                        $found = true;
                        break;
                    }
                }

                if (!$found) {
                    $iniVar = $phpSection->addChild('ini');
                    $iniVar->addAttribute('name', $name);
                    $iniVar->addAttribute('value', $value);
                }
            }
        }

        $xml->asXML($tempConfigPath);

        return $tempConfigPath;
    }

    /**
     * Lister les tests qui correspondent à la configuration
     */
    public function listTests(): array
    {
        $command = ['vendor/bin/phpunit'];

        // Forcer RUN_PRE_TEST=false temporairement pour cette commande
        $tempConfigPath = $this->createTempConfigWithNoPreTest();

        if ($tempConfigPath) {
            $command[] = '-c';
            $command[] = $tempConfigPath;
        } elseif ($this->persistentConfigPath && file_exists($this->persistentConfigPath)) {
            $command[] = '-c';
            $command[] = $this->persistentConfigPath;
        }

        $command[] = '--list-tests';

        if ($this->currentFilter) {
            $command[] = '--filter';
            $command[] = escapeshellarg($this->currentFilter);
        }

        if ($this->currentTestPath) {
            $command[] = $this->currentTestPath;
        }

        $commandStr = implode(' ', $command);
        echo "Liste des tests: $commandStr\n";

        $output = [];
        exec($commandStr, $output, $returnCode);

        // Nettoyer le fichier temporaire
        if ($tempConfigPath && file_exists($tempConfigPath)) {
            unlink($tempConfigPath);
        }

        return [
            'output' => $output,
            'returnCode' => $returnCode,
            'command' => $commandStr
        ];
    }

    /**
     * Lister les groupes de tests disponibles
     */
    public function listGroups(): array
    {
        $command = ['vendor/bin/phpunit'];

        // Forcer RUN_PRE_TEST=false temporairement
        $tempConfigPath = $this->createTempConfigWithNoPreTest();

        if ($tempConfigPath) {
            $command[] = '-c';
            $command[] = $tempConfigPath;
        } elseif ($this->persistentConfigPath && file_exists($this->persistentConfigPath)) {
            $command[] = '-c';
            $command[] = $this->persistentConfigPath;
        }

        $command[] = '--list-groups';

        $commandStr = implode(' ', $command);
        echo "Liste des groupes: $commandStr\n";

        $output = [];
        exec($commandStr, $output, $returnCode);

        // Nettoyer le fichier temporaire
        if ($tempConfigPath && file_exists($tempConfigPath)) {
            unlink($tempConfigPath);
        }

        return [
            'output' => $output,
            'returnCode' => $returnCode,
            'command' => $commandStr
        ];
    }

    /**
     * Lister les test suites disponibles
     */
    public function listSuites(): array
    {
        $command = ['vendor/bin/phpunit'];

        // Forcer RUN_PRE_TEST=false temporairement
        $tempConfigPath = $this->createTempConfigWithNoPreTest();

        if ($tempConfigPath) {
            $command[] = '-c';
            $command[] = $tempConfigPath;
        } elseif ($this->persistentConfigPath && file_exists($this->persistentConfigPath)) {
            $command[] = '-c';
            $command[] = $this->persistentConfigPath;
        }

        $command[] = '--list-suites';

        $commandStr = implode(' ', $command);
        echo "Liste des suites: $commandStr\n";

        $output = [];
        exec($commandStr, $output, $returnCode);

        // Nettoyer le fichier temporaire
        if ($tempConfigPath && file_exists($tempConfigPath)) {
            unlink($tempConfigPath);
        }

        return [
            'output' => $output,
            'returnCode' => $returnCode,
            'command' => $commandStr
        ];
    }

    /**
     * Valider la configuration PHPUnit sans exécuter les tests
     */
    public function validateConfig(): array
    {
        $command = ['vendor/bin/phpunit'];

        // Forcer RUN_PRE_TEST=false temporairement
        $tempConfigPath = $this->createTempConfigWithNoPreTest();

        if ($tempConfigPath) {
            $command[] = '-c';
            $command[] = $tempConfigPath;
        } elseif ($this->persistentConfigPath && file_exists($this->persistentConfigPath)) {
            $command[] = '-c';
            $command[] = $this->persistentConfigPath;
        }

        $command[] = '--help'; // Juste pour valider que la config se charge

        $commandStr = implode(' ', $command);

        $output = [];
        exec($commandStr, $output, $returnCode);

        // Nettoyer le fichier temporaire
        if ($tempConfigPath && file_exists($tempConfigPath)) {
            unlink($tempConfigPath);
        }

        return [
            'output' => $output,
            'returnCode' => $returnCode,
            'command' => $commandStr,
            'valid' => $returnCode === 0
        ];
    }

    /**
     * Obtenir des informations sur la configuration PHPUnit
     */
    public function getConfigInfo(): array
    {
        $command = ['vendor/bin/phpunit'];

        // Forcer RUN_PRE_TEST=false temporairement
        $tempConfigPath = $this->createTempConfigWithNoPreTest();

        if ($tempConfigPath) {
            $command[] = '-c';
            $command[] = $tempConfigPath;
        } elseif ($this->persistentConfigPath && file_exists($this->persistentConfigPath)) {
            $command[] = '-c';
            $command[] = $this->persistentConfigPath;
        }

        $command[] = '--configuration';

        $commandStr = implode(' ', $command);

        $output = [];
        exec($commandStr, $output, $returnCode);

        // Nettoyer le fichier temporaire
        if ($tempConfigPath && file_exists($tempConfigPath)) {
            unlink($tempConfigPath);
        }

        return [
            'output' => $output,
            'returnCode' => $returnCode,
            'command' => $commandStr
        ];
    }

    /**
     * Créer un fichier de configuration temporaire avec RUN_PRE_TEST=false
     */
    private function createTempConfigWithNoPreTest(): ?string
    {
        // Créer une config temporaire basée sur la config actuelle mais avec RUN_PRE_TEST=false
        $tempConfig = $this->currentConfig;
        $tempConfig['env']['RUN_PRE_TEST'] = 'false';

        return $this->createCustomPhpunitConfig($tempConfig);
    }

    /**
     * Méthode utilitaire pour compter les tests sans les exécuter
     */
    public function countTests(): array
    {
        $result = $this->listTests();

        // Compter les lignes qui contiennent des tests
        $testCount = 0;
        foreach ($result['output'] as $line) {
            if (str_contains($line, '::test') || str_contains($line, 'Test::')) {
                $testCount++;
            }
        }

        return [
            'count' => $testCount,
            'output' => $result['output'],
            'returnCode' => $result['returnCode']
        ];
    }

    /**
     * Dry run - voir ce qui serait exécuté sans lancer les tests
     */
    public function dryRun(): array
    {
        echo "=== DRY RUN - Configuration qui serait utilisée ===\n";
        $this->showConfig();

        echo "\n=== Tests qui seraient exécutés ===\n";
        $tests = $this->listTests();

        echo "\n=== Nombre de tests ===\n";
        $count = $this->countTests();
        echo "Total: {$count['count']} tests\n";

        return [
            'config' => $this->showConfig(),
            'tests' => $tests,
            'count' => $count['count']
        ];
    }

    public function __destruct()
    {
        // Optionnel : nettoyer le fichier de configuration temporaire
        // if ($this->persistentConfigPath && file_exists($this->persistentConfigPath)) {
        //     unlink($this->persistentConfigPath);
        // }
    }
}
