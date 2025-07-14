<?php

namespace Psy\Extended\Service;

/**
 * Service Manager centralisé pour gérer toutes les dépendances des commandes
 */
class CommandServiceManager
{
    private static ?self $instance = null;
    private array $services = [];
    private array $config = [];

    private function __construct()
    {
        $this->initializeDefaultConfig();
    }

    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    /**
     * Récupère un service par son nom
     */
    public function getService(string $serviceName): object
    {
        if (!isset($this->services[$serviceName])) {
            $this->services[$serviceName] = $this->createService($serviceName);
        }
        return $this->services[$serviceName];
    }

    /**
     * Enregistre un service personnalisé
     */
    public function registerService(string $name, object $service): void
    {
        $this->services[$name] = $service;
    }

    /**
     * Récupère la configuration
     */
    public function getConfig(?string $key = null): mixed
    {
        if ($key === null) {
            return $this->config;
        }
        return $this->config[$key] ?? null;
    }

    /**
     * Met à jour la configuration
     */
    public function setConfig(string $key, mixed $value): void
    {
        $this->config[$key] = $value;
    }

    /**
     * Services disponibles avec leurs classes correspondantes
     */
    private function getServiceClasses(): array
    {
        return [
            'phpunit' => PHPUnitService::class,
            'mock' => PHPUnitMockService::class,
            'config' => PHPUnitConfigService::class,
            'debug' => PHPUnitDebugService::class,
            'monitoring' => PHPUnitMonitoringService::class,
            'performance' => PHPUnitPerformanceService::class,
            'profiling' => PHPUnitProfilingService::class,
            'project' => PHPUnitProjectService::class,
            'snapshot' => PHPUnitSnapshotService::class,
            'help' => HelpService::class,
            'autocompletion' => AutocompletionService::class,
            'environment' => EnvironmentLoader::class,
            'shell_sync' => ShellSyncService::class,
        ];
    }

    /**
     * Crée une instance de service
     */
    private function createService(string $serviceName): object
    {
        $serviceClasses = $this->getServiceClasses();
        
        if (!isset($serviceClasses[$serviceName])) {
            throw new \InvalidArgumentException("Service '{$serviceName}' not found");
        }

        $className = $serviceClasses[$serviceName];
        
        if (!class_exists($className)) {
            throw new \RuntimeException("Service class '{$className}' does not exist");
        }

        // Vérifier si le service a besoin du manager comme dépendance
        $reflection = new \ReflectionClass($className);
        $constructor = $reflection->getConstructor();
        
        if ($constructor && $constructor->getNumberOfParameters() > 0) {
            $firstParam = $constructor->getParameters()[0];
            if ($firstParam->getType() && $firstParam->getType()->getName() === self::class) {
                return new $className($this);
            }
        }

        return new $className();
    }

    /**
     * Configuration par défaut
     */
    private function initializeDefaultConfig(): void
    {
        $this->config = [
            'debug_mode' => false,
            'verbose_output' => false,
            'test_directory' => getcwd() . '/tests',
            'phpunit_binary' => 'vendor/bin/phpunit',
            'auto_save' => true,
            'context_persistence' => true,
            'mock_auto_expectations' => true,
            'performance_profiling' => false,
        ];
    }

    /**
     * Reset tous les services (utile pour les tests)
     */
    public function reset(): void
    {
        $this->services = [];
        $this->initializeDefaultConfig();
    }

    /**
     * Vérifie si un service est disponible
     */
    public function hasService(string $serviceName): bool
    {
        return isset($this->getServiceClasses()[$serviceName]);
    }

    /**
     * Liste tous les services disponibles
     */
    public function getAvailableServices(): array
    {
        return array_keys($this->getServiceClasses());
    }
}
