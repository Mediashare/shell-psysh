<?php

namespace Psy\Extended\Service;

class PHPUnitConfigService
{
    private array $config = [];
    private array $originalConfig = [];
    private bool $tempConfigActive = false;
    private static $instance = null;

    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function __construct()
    {
        $this->loadDefaultConfig();
    }

    public function getCurrentConfig(): array
    {
        return $this->config;
    }

    public function setTestSuite(string $testsuite): void
    {
        $this->config['testsuite'] = $testsuite;
    }

    public function setCoverage(string $type, string $dir): void
    {
        $this->config['coverage'] = [
            'enabled' => true,
            'type' => $type,
            'dir' => $dir
        ];
    }

    public function setBootstrap(string $bootstrap): void
    {
        $this->config['bootstrap'] = $bootstrap;
    }

    public function createTempConfig(): void
    {
        if (!$this->tempConfigActive) {
            $this->originalConfig = $this->config;
            $this->tempConfigActive = true;
            $this->config['temp_config'] = true;
        }
    }

    public function restoreOriginalConfig(): bool
    {
        if ($this->tempConfigActive) {
            $this->config = $this->originalConfig;
            $this->tempConfigActive = false;
            $this->originalConfig = [];
            return true;
        }
        return false;
    }

    private function loadDefaultConfig(): void
    {
        $this->config = [
            'config_file' => $this->findConfigFile(),
            'testsuite' => 'unit',
            'bootstrap' => 'tests/bootstrap.php',
            'coverage' => [
                'enabled' => false,
                'type' => 'html',
                'dir' => 'var/coverage'
            ],
            'temp_config' => false
        ];

        // Charger la configuration depuis phpunit.xml si disponible
        if ($this->config['config_file'] && file_exists($this->config['config_file'])) {
            $this->loadFromXmlFile($this->config['config_file']);
        }
    }

    private function findConfigFile(): ?string
    {
        $possibleFiles = [
            'phpunit.xml',
            'phpunit.xml.dist',
            'phpunit.dist.xml'
        ];

        foreach ($possibleFiles as $file) {
            if (file_exists($file)) {
                return $file;
            }
        }

        return null;
    }

    private function loadFromXmlFile(string $configFile): void
    {
        try {
            $xml = simplexml_load_file($configFile);
            
            if ($xml === false) {
                return;
            }

            // Extraire les informations de base
            if (isset($xml['bootstrap'])) {
                $this->config['bootstrap'] = (string) $xml['bootstrap'];
            }

            // Extraire les test suites
            if (isset($xml->testsuites->testsuite)) {
                $testsuites = $xml->testsuites->testsuite;
                if (is_array($testsuites) && !empty($testsuites)) {
                    $this->config['testsuite'] = (string) $testsuites[0]['name'];
                } elseif (isset($testsuites['name'])) {
                    $this->config['testsuite'] = (string) $testsuites['name'];
                }
            }

            // Vérifier la couverture
            if (isset($xml->logging)) {
                $this->config['coverage']['enabled'] = true;
            }

        } catch (\Exception $e) {
            // Ignorer les erreurs de parsing XML et utiliser la configuration par défaut
        }
    }

    public function generateConfigXml(): string
    {
        $config = $this->config;
        
        $xml = '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
        $xml .= '<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' . "\n";
        $xml .= '         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"' . "\n";
        
        if (!empty($config['bootstrap'])) {
            $xml .= '         bootstrap="' . htmlspecialchars($config['bootstrap']) . '"' . "\n";
        }
        
        $xml .= '         colors="true">' . "\n";
        
        // Test suites
        $xml .= '    <testsuites>' . "\n";
        $xml .= '        <testsuite name="' . htmlspecialchars($config['testsuite']) . '">' . "\n";
        $xml .= '            <directory>tests</directory>' . "\n";
        $xml .= '        </testsuite>' . "\n";
        $xml .= '    </testsuites>' . "\n";
        
        // Coverage
        if ($config['coverage']['enabled']) {
            $xml .= '    <coverage>' . "\n";
            $xml .= '        <include>' . "\n";
            $xml .= '            <directory suffix=".php">src</directory>' . "\n";
            $xml .= '        </include>' . "\n";
            $xml .= '    </coverage>' . "\n";
        }
        
        $xml .= '</phpunit>' . "\n";
        
        return $xml;
    }

    public function saveConfigToFile(string $filename): bool
    {
        try {
            $xml = $this->generateConfigXml();
            return file_put_contents($filename, $xml) !== false;
        } catch (\Exception $e) {
            return false;
        }
    }

    public function getPhpUnitExecutable(): string
    {
        $possiblePaths = [
            'vendor/bin/phpunit',
            './vendor/bin/phpunit',
            'phpunit'
        ];

        foreach ($possiblePaths as $path) {
            if (file_exists($path)) {
                return $path;
            }
        }

        return 'phpunit'; // Fallback pour PATH global
    }

    public function buildCommand(array $options = []): string
    {
        $command = $this->getPhpUnitExecutable();
        
        // Configuration file
        if (!empty($this->config['config_file'])) {
            $command .= ' --configuration=' . escapeshellarg($this->config['config_file']);
        }
        
        // Test suite
        if (!empty($options['testsuite']) || !empty($this->config['testsuite'])) {
            $testsuite = $options['testsuite'] ?? $this->config['testsuite'];
            $command .= ' --testsuite=' . escapeshellarg($testsuite);
        }
        
        // Bootstrap
        if (!empty($this->config['bootstrap'])) {
            $command .= ' --bootstrap=' . escapeshellarg($this->config['bootstrap']);
        }
        
        // Coverage
        if ($options['coverage'] ?? $this->config['coverage']['enabled']) {
            $coverageType = $options['coverage_type'] ?? $this->config['coverage']['type'];
            $coverageDir = $options['coverage_dir'] ?? $this->config['coverage']['dir'];
            
            switch ($coverageType) {
                case 'html':
                    $command .= ' --coverage-html=' . escapeshellarg($coverageDir);
                    break;
                case 'text':
                    $command .= ' --coverage-text';
                    break;
                case 'clover':
                    $command .= ' --coverage-clover=' . escapeshellarg($coverageDir . '/clover.xml');
                    break;
            }
        }
        
        // Options supplémentaires
        if (!empty($options['filter'])) {
            $command .= ' --filter=' . escapeshellarg($options['filter']);
        }
        
        if ($options['verbose'] ?? true) {
            $command .= ' --verbose';
        }
        
        if ($options['stop_on_failure'] ?? false) {
            $command .= ' --stop-on-failure';
        }
        
        return $command;
    }

    public function validateConfig(): array
    {
        $errors = [];
        
        // Vérifier le bootstrap
        if (!empty($this->config['bootstrap']) && !file_exists($this->config['bootstrap'])) {
            $errors[] = "Fichier bootstrap non trouvé: " . $this->config['bootstrap'];
        }
        
        // Vérifier le répertoire des tests
        if (!is_dir('tests')) {
            $errors[] = "Répertoire 'tests' non trouvé";
        }
        
        // Vérifier PHPUnit
        if (!file_exists($this->getPhpUnitExecutable())) {
            $errors[] = "PHPUnit non trouvé. Installez-le via Composer : composer require --dev phpunit/phpunit";
        }
        
        return $errors;
    }
}
