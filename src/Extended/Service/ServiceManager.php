<?php

/*
 * This file is part of Psy Shell Enhanced.
 *
 * Manages services for the extended PsySH commands
 */

namespace Psy\Extended\Service;

use Psy\Shell;

/**
 * Service Manager for PsySH Enhanced
 * Singleton pattern to manage service instances
 */
class ServiceManager
{
    private static ?self $instance = null;
    private array $services = [];
    private array $config = [];
    private ?Shell $shell = null;
    
    private function __construct()
    {
        $this->initializeServices();
    }
    
    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /**
     * Initialize core services
     */
    private function initializeServices(): void
    {
        // Core services will be lazy-loaded when requested
        $this->services = [];
        
        // Default configuration
        $this->config = [
            'debug_mode' => false,
            'verbose_output' => false,
            'test_directory' => 'tests/Generated',
            'export_format' => 'phpunit',
            'monitoring_enabled' => true,
        ];
    }
    
    /**
     * Register a service
     */
    public function registerService(string $name, object $service): void
    {
        $this->services[$name] = $service;
    }
    
    /**
     * Get a service by name
     */
    public function getService(string $name): object
    {
        if (!isset($this->services[$name])) {
            $this->services[$name] = $this->createService($name);
        }
        return $this->services[$name];
    }
    
    /**
     * Create a service instance
     */
    private function createService(string $name): object
    {
        return match($name) {
            'phpunit' => PHPUnitService::getInstance(),
            'environment' => new EnvironmentLoader(),
            'sync' => new ShellSyncService($this->shell),
            'monitor' => new PHPUnitMonitoringService(),
            'snapshot' => new PHPUnitSnapshotService(),
            'mock' => new PHPUnitMockService(),
            default => throw new \RuntimeException("Service '{$name}' not found")
        };
    }
    
    /**
     * Set the shell instance
     */
    public function setShell(Shell $shell): void
    {
        $this->shell = $shell;
        // Update sync service if already created
        if (isset($this->services['sync'])) {
            $this->services['sync'] = new ShellSyncService($shell);
        }
    }
    
    /**
     * Get configuration value
     */
    public function getConfig(?string $key = null): mixed
    {
        if ($key === null) {
            return $this->config;
        }
        return $this->config[$key] ?? null;
    }
    
    /**
     * Set configuration value
     */
    public function setConfig(string $key, mixed $value): void
    {
        $this->config[$key] = $value;
    }
    
    /**
     * Reset the instance (useful for testing)
     */
    public static function reset(): void
    {
        self::$instance = null;
    }
}
