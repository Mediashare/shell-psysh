<?php

/*
 * This file is part of Psy Shell Enhanced.
 */

namespace Psy\Extended\Service;

/**
 * Service for loading project environment and context
 */
class EnvironmentService
{
    private array $projectContext = [];
    private array $availableVariables = [];
    
    /**
     * Load project context based on environment
     */
    public function loadProjectContext(): array
    {
        $projectRoot = getcwd();
        $context = [
            'variables' => [],
            'welcome_message' => '',
            'type' => 'generic',
        ];
        
        // Detect Symfony project
        if ($this->isSymfonyProject($projectRoot)) {
            $context = $this->loadSymfonyContext($projectRoot);
        }
        // Detect Laravel project
        elseif ($this->isLaravelProject($projectRoot)) {
            $context = $this->loadLaravelContext($projectRoot);
        }
        // Generic PHP project
        else {
            $context = $this->loadGenericContext($projectRoot);
        }
        
        $this->projectContext = $context;
        return $context;
    }
    
    /**
     * Check if project is Symfony
     */
    private function isSymfonyProject(string $root): bool
    {
        return file_exists($root . '/bin/console') || 
               file_exists($root . '/app/console') ||
               file_exists($root . '/symfony.lock');
    }
    
    /**
     * Check if project is Laravel
     */
    private function isLaravelProject(string $root): bool
    {
        return file_exists($root . '/artisan') &&
               file_exists($root . '/bootstrap/app.php');
    }
    
    /**
     * Load Symfony context
     */
    private function loadSymfonyContext(string $projectRoot): array
    {
        $variables = [];
        $welcomeMessage = "🎼 Symfony Project Detected\n";
        
        // Try to load Symfony kernel
        $kernelPath = $this->findSymfonyKernel($projectRoot);
        if ($kernelPath) {
            try {
                require_once $projectRoot . '/vendor/autoload.php';
                $kernel = require $kernelPath;
                
                if ($kernel instanceof \Symfony\Component\HttpKernel\KernelInterface) {
                    $kernel->boot();
                    $container = $kernel->getContainer();
                    
                    $variables['kernel'] = $kernel;
                    $variables['container'] = $container;
                    
                    // Common Symfony services
                    if ($container->has('doctrine.orm.entity_manager')) {
                        $variables['em'] = $container->get('doctrine.orm.entity_manager');
                    }
                    
                    if ($container->has('router')) {
                        $variables['router'] = $container->get('router');
                    }
                    
                    if ($container->has('logger')) {
                        $variables['logger'] = $container->get('logger');
                    }
                    
                    if ($container->has('security.token_storage')) {
                        $variables['security'] = $container->get('security.token_storage');
                    }
                    
                    if ($container->has('twig')) {
                        $variables['twig'] = $container->get('twig');
                    }
                    
                    if ($container->has('form.factory')) {
                        $variables['formFactory'] = $container->get('form.factory');
                    }
                    
                    if ($container->has('event_dispatcher')) {
                        $variables['dispatcher'] = $container->get('event_dispatcher');
                    }
                    
                    // Add service names for autocompletion
                    $this->availableVariables = array_keys($variables);
                    
                    $welcomeMessage .= "✅ Kernel loaded, container available\n";
                    $welcomeMessage .= "📦 Available variables: \$kernel, \$container";
                    
                    if (isset($variables['em'])) {
                        $welcomeMessage .= ", \$em";
                    }
                    if (isset($variables['router'])) {
                        $welcomeMessage .= ", \$router";
                    }
                }
            } catch (\Exception $e) {
                $welcomeMessage .= "⚠️  Could not load kernel: " . $e->getMessage();
            }
        }
        
        return [
            'variables' => $variables,
            'welcome_message' => $welcomeMessage,
            'type' => 'symfony',
        ];
    }
    
    /**
     * Find Symfony kernel
     */
    private function findSymfonyKernel(string $root): ?string
    {
        $possiblePaths = [
            '/config/bootstrap.php',
            '/app/bootstrap.php.cache',
            '/var/bootstrap.php.cache',
            '/public/index.php',
            '/web/app.php',
            '/web/app_dev.php',
        ];
        
        foreach ($possiblePaths as $path) {
            if (file_exists($root . $path)) {
                return $root . $path;
            }
        }
        
        return null;
    }
    
    /**
     * Load Laravel context
     */
    private function loadLaravelContext(string $projectRoot): array
    {
        $variables = [];
        $welcomeMessage = "🎸 Laravel Project Detected\n";
        
        try {
            require_once $projectRoot . '/vendor/autoload.php';
            $app = require_once $projectRoot . '/bootstrap/app.php';
            
            if ($app instanceof \Illuminate\Foundation\Application) {
                $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();
                
                $variables['app'] = $app;
                $variables['db'] = $app->make('db');
                $variables['cache'] = $app->make('cache');
                $variables['config'] = $app->make('config');
                
                $welcomeMessage .= "✅ Laravel application loaded\n";
                $welcomeMessage .= "📦 Available variables: \$app, \$db, \$cache, \$config";
            }
        } catch (\Exception $e) {
            $welcomeMessage .= "⚠️  Could not load Laravel: " . $e->getMessage();
        }
        
        return [
            'variables' => $variables,
            'welcome_message' => $welcomeMessage,
            'type' => 'laravel',
        ];
    }
    
    /**
     * Load generic PHP context
     */
    private function loadGenericContext(string $projectRoot): array
    {
        $variables = [
            'projectRoot' => $projectRoot,
        ];
        
        // Load composer autoloader if available
        if (file_exists($projectRoot . '/vendor/autoload.php')) {
            $variables['composerAutoloader'] = require $projectRoot . '/vendor/autoload.php';
        }
        
        $welcomeMessage = "🚀 PsySH Enhanced Shell\n";
        $welcomeMessage .= "📦 Project root: {$projectRoot}\n";
        $welcomeMessage .= "💡 Type 'help' for available commands";
        
        return [
            'variables' => $variables,
            'welcome_message' => $welcomeMessage,
            'type' => 'generic',
        ];
    }
    
    /**
     * Get project context
     */
    public function getProjectContext(): array
    {
        return $this->projectContext;
    }
    
    /**
     * Get available variables
     */
    public function getAvailableVariables(): array
    {
        return $this->availableVariables;
    }
}
