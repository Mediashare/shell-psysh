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
        
        try {
            // Load the autoloader
            require_once $projectRoot . '/vendor/autoload.php';
            
            // Try different approaches to create the kernel
            $kernel = null;
            
            // Modern Symfony approach (5.3+)
            if (file_exists($projectRoot . '/src/Kernel.php')) {
                // Load environment variables
                $env = $_ENV['APP_ENV'] ?? $_SERVER['APP_ENV'] ?? 'dev';
                $debug = (bool) ($_ENV['APP_DEBUG'] ?? $_SERVER['APP_DEBUG'] ?? ('prod' !== $env));
                
                // Detect the correct namespace from composer.json
                $kernelClass = $this->detectKernelClass($projectRoot);
                
                if ($kernelClass && class_exists($kernelClass)) {
                    $kernel = new $kernelClass($env, $debug);
                }
            }
            
            // Legacy Symfony approach
            if (!$kernel && file_exists($projectRoot . '/app/AppKernel.php')) {
                require_once $projectRoot . '/app/AppKernel.php';
                $env = $_ENV['SYMFONY_ENV'] ?? $_SERVER['SYMFONY_ENV'] ?? 'dev';
                $debug = (bool) ($_ENV['SYMFONY_DEBUG'] ?? $_SERVER['SYMFONY_DEBUG'] ?? ('prod' !== $env));
                
                if (class_exists('AppKernel')) {
                    $kernel = new \AppKernel($env, $debug);
                }
            }
            
            if ($kernel instanceof \Symfony\Component\HttpKernel\KernelInterface) {
                $kernel->boot();
                $container = $kernel->getContainer();
                
                $variables['kernel'] = $kernel;
                $variables['container'] = $container;
                
                // Common Symfony services
                $services = [
                    'em' => ['doctrine.orm.entity_manager', 'doctrine.orm.default_entity_manager'],
                    'router' => ['router', 'router.default'],
                    'logger' => ['logger', 'monolog.logger'],
                    'security' => ['security.token_storage'],
                    'twig' => ['twig'],
                    'formFactory' => ['form.factory'],
                    'dispatcher' => ['event_dispatcher'],
                    'cache' => ['cache.app'],
                    'translator' => ['translator'],
                    'validator' => ['validator'],
                    'serializer' => ['serializer'],
                    'mailer' => ['mailer', 'mailer.mailer'],
                ];
                
                foreach ($services as $varName => $serviceIds) {
                    foreach ((array) $serviceIds as $serviceId) {
                        if ($container->has($serviceId)) {
                            try {
                                $variables[$varName] = $container->get($serviceId);
                                break;
                            } catch (\Exception $e) {
                                // Service might be private, skip it
                            }
                        }
                    }
                }
                
                // Add service names for autocompletion
                $this->availableVariables = array_keys($variables);
                
                $welcomeMessage .= "✅ Kernel loaded, container available\n";
                $welcomeMessage .= "📦 Available variables: \$kernel, \$container";
                
                $availableServices = array_filter(array_keys($services), function($key) use ($variables) {
                    return isset($variables[$key]);
                });
                
                if (!empty($availableServices)) {
                    $welcomeMessage .= ", \$" . implode(", \$", $availableServices);
                }
                
                $welcomeMessage .= "\n";
                $welcomeMessage .= "📝 Environment: {$kernel->getEnvironment()} | Debug: " . ($kernel->isDebug() ? 'on' : 'off');
            } else {
                $welcomeMessage .= "⚠️  Could not create Symfony kernel\n";
                $welcomeMessage .= "💡 Make sure you're in the root of a Symfony project";
            }
        } catch (\Exception $e) {
            $welcomeMessage .= "⚠️  Could not load kernel: " . $e->getMessage() . "\n";
            $welcomeMessage .= "💡 Try running 'composer install' first";
        } catch (\Throwable $e) {
            $welcomeMessage .= "⚠️  Error: " . $e->getMessage();
        }
        
        return [
            'variables' => $variables,
            'welcome_message' => $welcomeMessage,
            'type' => 'symfony',
        ];
    }
    
    /**
     * Detect kernel class from composer.json PSR-4 autoload
     */
    private function detectKernelClass(string $projectRoot): ?string
    {
        $composerFile = $projectRoot . '/composer.json';
        if (!file_exists($composerFile)) {
            return 'App\\Kernel'; // Default fallback
        }
        
        try {
            $composerData = json_decode(file_get_contents($composerFile), true);
            
            // Check PSR-4 autoload
            if (isset($composerData['autoload']['psr-4'])) {
                foreach ($composerData['autoload']['psr-4'] as $namespace => $path) {
                    // Look for namespaces that map to 'src/'
                    if ($path === 'src/' || $path === 'src') {
                        $namespace = rtrim($namespace, '\\');
                        $kernelClass = $namespace . '\\Kernel';
                        
                        // Verify the kernel file exists
                        $kernelFile = $projectRoot . '/src/Kernel.php';
                        if (file_exists($kernelFile)) {
                            return $kernelClass;
                        }
                    }
                }
            }
            
            // Also check autoload-dev
            if (isset($composerData['autoload-dev']['psr-4'])) {
                foreach ($composerData['autoload-dev']['psr-4'] as $namespace => $path) {
                    if ($path === 'src/' || $path === 'src') {
                        $namespace = rtrim($namespace, '\\');
                        $kernelClass = $namespace . '\\Kernel';
                        
                        if (file_exists($projectRoot . '/src/Kernel.php')) {
                            return $kernelClass;
                        }
                    }
                }
            }
        } catch (\Exception $e) {
            // Ignore JSON parsing errors
        }
        
        // Fallback to common namespace
        return 'App\\Kernel';
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
