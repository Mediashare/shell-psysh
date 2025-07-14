<?php

/*
 * This file is part of Psy Shell Enhanced.
 */

namespace Psy\Extended\Trait;

use Psy\Extended\Service\ServiceManager;

/**
 * Trait for simplified service access in commands
 */
trait ServiceAwareTrait
{
    private ?ServiceManager $serviceManager = null;

    /**
     * Get the service manager
     */
    protected function getServiceManager(): ServiceManager
    {
        if ($this->serviceManager === null) {
            $this->serviceManager = ServiceManager::getInstance();
        }
        return $this->serviceManager;
    }

    /**
     * Get a specific service
     */
    protected function getService(string $serviceName): object
    {
        return $this->getServiceManager()->getService($serviceName);
    }

    /**
     * Shortcuts for commonly used services
     */
    protected function phpunit(): object
    {
        return $this->getService('phpunit');
    }

    protected function environment(): object
    {
        return $this->getService('environment');
    }

    protected function sync(): object
    {
        return $this->getService('sync');
    }

    protected function monitor(): object
    {
        return $this->getService('monitor');
    }

    protected function mock(): object
    {
        return $this->getService('mock');
    }

    protected function snapshot(): object
    {
        return $this->getService('snapshot');
    }

    /**
     * Get global configuration
     */
    protected function getConfig(?string $key = null): mixed
    {
        return $this->getServiceManager()->getConfig($key);
    }

    /**
     * Set global configuration
     */
    protected function setConfig(string $key, mixed $value): void
    {
        $this->getServiceManager()->setConfig($key, $value);
    }

    /**
     * Check if debug mode is enabled
     */
    protected function isDebugMode(): bool
    {
        return $this->getConfig('debug_mode') ?? false;
    }

    /**
     * Enable/disable debug mode
     */
    protected function setDebugMode(bool $enabled): void
    {
        $this->setConfig('debug_mode', $enabled);
    }

    /**
     * Check if verbose output is enabled
     */
    protected function isVerboseOutput(): bool
    {
        return $this->getConfig('verbose_output') ?? false;
    }
}
