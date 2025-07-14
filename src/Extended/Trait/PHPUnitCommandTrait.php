<?php

namespace Psy\Extended\Trait;

use Psy\Extended\Service\CommandServiceManager;

/**
 * Trait PHPUnit compatible avec l'ancienne et nouvelle architecture
 */
trait PHPUnitCommandTrait
{
    use RawExpressionTrait;
    
    /**
     * @deprecated Utilisez $this->phpunit() à la place
     */
    protected function getPhpunitService()
    {
        return CommandServiceManager::getInstance()->getService('phpunit');
    }
    
    /**
     * @deprecated Utilisez $this->mock() à la place
     */
    protected function getMockService()
    {
        return CommandServiceManager::getInstance()->getService('mock');
    }
    
    /**
     * @deprecated Utilisez $this->config() à la place
     */
    protected function getConfigService()
    {
        return CommandServiceManager::getInstance()->getService('config');
    }

    protected function isCodeMode(): bool
    {
        return $GLOBALS['phpunit_code_mode'] ?? false;
    }

    protected function setCodeMode(bool $mode): void
    {
        $GLOBALS['phpunit_code_mode'] = $mode;
    }

    protected function formatSuccess(string $message): string
    {
        return "✅ {$message}";
    }

    protected function formatError(string $message): string
    {
        return "❌ {$message}";
    }

    protected function formatInfo(string $message): string
    {
        return "📋 {$message}";
    }

    protected function formatTest(string $message): string
    {
        return "🧪 {$message}";
    }

    protected function extractClassName(string $serviceClass): string
    {
        $parts = explode('\\', $serviceClass);
        return end($parts);
    }

    protected function createTestDirectory(string $path): void
    {
        if (!is_dir($path)) {
            mkdir($path, 0755, true);
        }
    }

    protected function validatePhpCode(string $code): bool
    {
        // Validation basique du code PHP
        return !empty(trim($code)) && !str_contains($code, '<?php');
    }

    protected function executePhpCode(string $code): mixed
    {
        try {
            // Utiliser le service de synchronisation unifié
            $unifiedSync = $GLOBALS['psysh_unified_sync_service'] ?? null;
            if ($unifiedSync && $unifiedSync instanceof \Psy\Extended\Service\UnifiedSyncService) {
                $context = [];
                return $unifiedSync->executeWithSync($code, $context);
            }
            
            // Fallback sur l'ancienne méthode
            $syncService = $GLOBALS['psysh_shell_sync_service'] ?? null;
            if ($syncService && $syncService instanceof \Psy\Extended\Service\ShellSyncService) {
                $syncService->autoSync();
                $shellVariables = $syncService->getMainShellVariables();
            } else {
                $shellVariables = $GLOBALS['psysh_shell_variables'] ?? [];
            }
            
            // Récupérer le contexte du mode code s'il existe
            $codeContext = $GLOBALS['phpunit_code_context'] ?? [];
            
            // Fusionner les contextes
            $allVariables = array_merge($shellVariables, $codeContext);
            
            // Extraire les variables dans le contexte local
            extract($allVariables);
            
            return eval($code);
        } catch (\Throwable $e) {
            return "Erreur: " . $e->getMessage();
        }
    }

    protected function executePhpCodeWithContext(string $code, array &$context = []): mixed
    {
        try {
            // Utiliser le service de synchronisation unifié
            $unifiedSync = $GLOBALS['psysh_unified_sync_service'] ?? null;
            if ($unifiedSync && $unifiedSync instanceof \Psy\Extended\Service\UnifiedSyncService) {
                return $unifiedSync->executeWithSync($code, $context);
            }
            
            // Fallback sur l'ancienne méthode
            $syncService = $GLOBALS['psysh_shell_sync_service'] ?? null;
            if ($syncService && $syncService instanceof \Psy\Extended\Service\ShellSyncService) {
                $shellVariables = $syncService->getMainShellVariables();
            } else {
                $shellVariables = $GLOBALS['psysh_shell_variables'] ?? [];
            }
            
            // Fusionner avec le contexte persistant
            $allVariables = array_merge($shellVariables, $context);
            
            // Extraire les variables dans le contexte local
            extract($allVariables);
            
            // Exécuter le code
            $result = eval($code);
            
            // Capturer les nouvelles variables créées
            $newVariables = get_defined_vars();
            
            // Exclure les variables techniques de la fonction uniquement
            // Ne pas exclure 'result' car cela pourrait être une variable créée par le code de l'utilisateur
            $excludeVars = ['code', 'context', 'shellVariables', 'allVariables', 'newVariables', 'unifiedSync', 'syncService'];
            foreach ($excludeVars as $var) {
                unset($newVariables[$var]);
            }
            
            // Ne pas supprimer les variables créées par le code utilisateur
            // Le code peut créer des variables comme $result, $data, etc.
            // Ces variables doivent être conservées dans le contexte
            
            // Mettre à jour le contexte persistant
            $context = array_merge($context, $newVariables);
            
            // Sauvegarder le contexte dans les globals pour persistance
            $GLOBALS['phpunit_code_context'] = $context;
            
            return $result;
        } catch (\ParseError $e) {
            return "Erreur: Parse error - " . $e->getMessage();
        } catch (\Error $e) {
            return "Erreur: " . $e->getMessage();
        } catch (\Exception $e) {
            return "Erreur: " . $e->getMessage();
        }
    }

    protected function createSubShell(): \Psy\Shell
    {
        // Utiliser le service de synchronisation unifié
        $unifiedSync = $GLOBALS['psysh_unified_sync_service'] ?? null;
        if ($unifiedSync && $unifiedSync instanceof \Psy\Extended\Service\UnifiedSyncService) {
            return $unifiedSync->createSyncedSubShell('phpunit:code> ');
        }
        
        // Fallback sur l'ancienne méthode
        $config = new \Psy\Configuration();
        $config->setPrompt('phpunit:code> ');
        $config->setStartupMessage('🧪 Mode code PHPUnit activé - Le code sera automatiquement ajouté au test');
        
        $shell = new \Psy\Shell($config);
        
        // Récupérer le contexte partagé depuis toutes les sources
        $syncService = $GLOBALS['psysh_shell_sync_service'] ?? null;
        if ($syncService && $syncService instanceof \Psy\Extended\Service\ShellSyncService) {
            $shellVariables = $syncService->getMainShellVariables();
        } else {
            $shellVariables = $GLOBALS['psysh_shell_variables'] ?? [];
        }
        
        $codeContext = $GLOBALS['phpunit_code_context'] ?? [];
        $mainShellContext = $this->getMainShellContext();
        
        // Fusionner tous les contextes (main shell a priorité)
        $allVariables = array_merge($shellVariables, $codeContext, $mainShellContext);
        
        // Sauvegarder l'état des variables avant d'entrer en mode code
        $GLOBALS['phpunit_code_context_before'] = $allVariables;
        
        // Injecter les variables dans le shell
        $shell->setScopeVariables($allVariables);
        
        return $shell;
    }

    protected function startInteractiveCodeMode(): void
    {
        echo "🧪 Démarrage du mode code interactif PHPUnit...\n";
        echo "💡 Toutes les variables du shell principal sont disponibles\n";
        echo "📋 Tapez 'exit' ou Ctrl+D pour quitter\n\n";
        
        try {
            $shell = $this->createSubShell();
            
            // Démarrer le shell interactif
            $shell->run();
            
            // Synchroniser le contexte après la sortie du shell
            $this->syncContextFromShell($shell);
            
        } catch (\Exception $e) {
            echo "❌ Erreur lors du démarrage du mode code: " . $e->getMessage() . "\n";
        }
        
        echo "\n✅ Mode code interactif terminé\n";
    }
    
    protected function syncContextFromShell(\Psy\Shell $shell): void
    {
        try {
            // Utiliser le service de synchronisation unifié
            $unifiedSync = $GLOBALS['psysh_unified_sync_service'] ?? null;
            if ($unifiedSync && $unifiedSync instanceof \Psy\Extended\Service\UnifiedSyncService) {
                $unifiedSync->syncFromSubShell($shell);
                
                // Obtenir les variables pour l'ajout au test
                $variables = $shell->getScopeVariables();
                $existingVars = $GLOBALS['phpunit_code_context'] ?? [];
                
                // Filtrer les variables système
                $filteredVariables = [];
                $systemVars = ['_', '__', '___', '_e', '_ex', '_err', '__psysh__', '__psysh_shell__'];
                foreach ($variables as $name => $value) {
                    if (!in_array($name, $systemVars)) {
                        $filteredVariables[$name] = $value;
                    }
                }
                
                // Détecter les nouvelles variables et modifications
                $newVars = [];
                $modifiedVars = [];
                foreach ($filteredVariables as $name => $value) {
                    if (!isset($existingVars[$name])) {
                        $newVars[$name] = $value;
                    } elseif ($existingVars[$name] !== $value) {
                        $modifiedVars[$name] = $value;
                    }
                }
                
                // Mise à jour des globals
                $GLOBALS['phpunit_code_context'] = array_merge($existingVars, $filteredVariables);
                
                // Debug détaillé
                if ($this->debug) {
                    echo "\n" . str_repeat('=', 60) . "\n";
                    echo "🔄 SYNCHRONISATION SHELL phpunit:code → CONTEXTE GLOBAL\n";
                    echo str_repeat('=', 60) . "\n";
                    echo "📊 Variables totales dans le shell: " . count($variables) . "\n";
                    echo "📊 Variables filtrées: " . count($filteredVariables) . "\n";
                    echo "📊 Variables existantes: " . count($existingVars) . "\n";
                    echo "📊 Nouvelles variables: " . count($newVars) . "\n";
                    echo "📊 Variables modifiées: " . count($modifiedVars) . "\n";
                    
                    if (!empty($newVars)) {
                        echo "\n✅ NOUVELLES VARIABLES CAPTURÉES:\n";
                        foreach ($newVars as $name => $value) {
                            $type = gettype($value);
                            $preview = $this->getVariablePreview($value);
                            echo "   + \$$name ($type): $preview\n";
                        }
                    }
                    
                    if (!empty($modifiedVars)) {
                        echo "\n🔄 VARIABLES MODIFIÉES:\n";
                        foreach ($modifiedVars as $name => $value) {
                            $type = gettype($value);
                            $preview = $this->getVariablePreview($value);
                            echo "   ~ \$$name ($type): $preview\n";
                        }
                    }
                    
                    if (!empty($filteredVariables)) {
                        echo "\n📋 TOUTES LES VARIABLES SYNCHRONISÉES:\n";
                        foreach ($filteredVariables as $name => $value) {
                            $type = gettype($value);
                            $preview = $this->getVariablePreview($value);
                            echo "   - \$$name ($type): $preview\n";
                        }
                    }
                    
                    echo str_repeat('=', 60) . "\n\n";
                }
                
                // Ajouter le code exécuté dans le shell au test
                $addedLines = $this->addCapturedCodeToTest($filteredVariables);
                if ($addedLines > 0) {
                    echo "✅ {$addedLines} ligne(s) de code ajoutée(s) au test\n";
                }
                
                return;
            }
            
            // Fallback sur l'ancienne méthode
            $reflection = new \ReflectionClass($shell);
            $contextProperty = $reflection->getProperty('context');
            $contextProperty->setAccessible(true);
            $context = $contextProperty->getValue($shell);
            
            if ($context && method_exists($context, 'getAll')) {
                $variables = $context->getAll();
                
                // Filtrer les variables système
                $filteredVariables = [];
                foreach ($variables as $name => $value) {
                    if (!in_array($name, ['_', '__', '___', '_e', '_ex', '_err'])) {
                        $filteredVariables[$name] = $value;
                    }
                }
                
                // Sauvegarder dans le contexte phpunit
                $GLOBALS['phpunit_code_context'] = array_merge(
                    $GLOBALS['phpunit_code_context'] ?? [],
                    $filteredVariables
                );
                
                // Ajouter le code exécuté dans le shell au test
                $addedLines = $this->addCapturedCodeToTest($filteredVariables);
                if ($addedLines > 0) {
                    echo "✅ {$addedLines} ligne(s) de code ajoutée(s) au test\n";
                }
                
                // SYNCHRONISATION BIDIRECTIONNELLE: Mettre à jour le contexte du shell principal
                $this->syncToMainShell($filteredVariables);
            }
        } catch (\Exception $e) {
            if ($this->debug) {
                echo "❌ [ERREUR] Impossible de synchroniser le contexte: " . $e->getMessage() . "\n";
            }
        }
    }
    
    /**
     * Get a preview of a variable for debug output
     */
    protected function getVariablePreview($value): string
    {
        if (is_null($value)) {
            return 'null';
        } elseif (is_bool($value)) {
            return $value ? 'true' : 'false';
        } elseif (is_string($value)) {
            return strlen($value) > 50 ? '"' . substr($value, 0, 47) . '..."' : '"' . $value . '"';
        } elseif (is_numeric($value)) {
            return (string) $value;
        } elseif (is_array($value)) {
            return 'array(' . count($value) . ' elements)';
        } elseif (is_object($value)) {
            return get_class($value) . ' object';
        } else {
            return gettype($value);
        }
    }

    protected function addCapturedCodeToTest(array $filteredVariables): int
    {
        $service = $this->phpunit();
        $test = $service->getCurrentTest();
        if (!$test) {
            return 0;
        }

        // Obtenir les variables qui existaient avant le mode code
        $previousVariables = $GLOBALS['phpunit_code_context_before'] ?? [];
        
        $existingCodeLines = $test->getCodeLines();
        $addedCount = 0;

        // Générer le code seulement pour les nouvelles variables
        foreach ($filteredVariables as $variable => $value) {
            // Ignorer les variables qui existaient déjà ou qui sont des variables système
            if ($this->shouldIgnoreVariable($variable, $value, $previousVariables)) {
                continue;
            }
            
            // Créer une ligne de code représentative
            $codeLine = $this->generateCodeLine($variable, $value);
            
            if ($codeLine && !in_array($codeLine, $existingCodeLines)) {
                $test->addCodeLine($codeLine);
                $addedCount++;
            }
        }

        return $addedCount;
    }
    
    protected function shouldIgnoreVariable(string $variable, $value, array $previousVariables): bool
    {
        // Variables système à ignorer
        $systemVariables = [
            'projectRoot',
            'composerAutoloader', 
            'phpunitService',
            'env',
            'server',
            'composer',
            'container',
            'em',
            '_REQUEST',
            '_POST',
            '_GET',
            '_SESSION',
            '_COOKIE',
            '_FILES',
            '_ENV',
            '_SERVER'
        ];
        
        if (in_array($variable, $systemVariables)) {
            return true;
        }
        
        // Ignorer si la variable existait déjà avec la même valeur
        if (isset($previousVariables[$variable]) && $previousVariables[$variable] === $value) {
            return true;
        }
        
        // Ignorer les objets complexes (services, etc.)
        if (is_object($value) && !($value instanceof \stdClass)) {
            return true;
        }
        
        return false;
    }
    
    protected function generateCodeLine(string $variable, $value): ?string
    {
        // Générer une ligne de code représentative selon le type de valeur
        if (is_null($value)) {
            return "$" . $variable . " = null;";
        }
        
        if (is_bool($value)) {
            return "$" . $variable . " = " . ($value ? 'true' : 'false') . ";";
        }
        
        if (is_numeric($value)) {
            return "$" . $variable . " = " . $value . ";";
        }
        
        if (is_string($value)) {
            // Limiter la longueur des chaînes pour la lisibilité
            if (strlen($value) > 100) {
                $value = substr($value, 0, 97) . '...';
            }
            return "$" . $variable . " = " . var_export($value, true) . ";";
        }
        
        if (is_array($value)) {
            $count = count($value);
            return "$" . $variable . " = [/* array with {$count} elements */];";
        }
        
        if (is_object($value)) {
            // Ne pas générer de code pour les objets complexes
            // car ils ne peuvent pas être recréés facilement
            return null;
        }
        
        return null;
    }
    
    /**
     * Récupère le contexte du shell principal
     */
    protected function getMainShellContext(): array
    {
        // Priorité 1: Récupérer directement depuis le shell principal
        $shell = $this->getApplication();
        if ($shell instanceof \Psy\Shell) {
            try {
                return $shell->getScopeVariables();
            } catch (\Exception $e) {
                // Continuer avec les fallbacks
            }
        }
        
        // Priorité 2: Utiliser le service de synchronisation si disponible
        $syncService = $GLOBALS['psysh_shell_sync_service'] ?? null;
        if ($syncService && $syncService instanceof \Psy\Extended\Service\ShellSyncService) {
            return $syncService->getMainShellVariables();
        }
        
        // Priorité 3: Fallback sur les globals
        $mainShellContext = $GLOBALS['psysh_shell_variables'] ?? [];
        $globalContext = $GLOBALS['psysh_main_shell_context'] ?? [];
        
        // Priorité 4: Récupérer depuis le fichier de persistance
        $tempDir = sys_get_temp_dir();
        $filename = $tempDir . '/psysh_variables_' . getmypid() . '.dat';
        if (file_exists($filename)) {
            try {
                $data = file_get_contents($filename);
                $fileVars = unserialize($data);
                if (is_array($fileVars)) {
                    $mainShellContext = array_merge($mainShellContext, $fileVars);
                }
            } catch (\Exception $e) {
                // Ignore les erreurs de lecture
            }
        }
        
        return array_merge($mainShellContext, $globalContext);
    }
    
    /**
     * Synchronise les variables vers le shell principal
     */
    protected function syncToMainShell(array $variables): void
    {
        if (empty($variables)) {
            return;
        }
        
        try {
            // Utiliser le service de synchronisation si disponible
            $syncService = $GLOBALS['psysh_shell_sync_service'] ?? null;
            if ($syncService && $syncService instanceof \Psy\Extended\Service\ShellSyncService) {
                $success = $syncService->syncToMainShell($variables);
                if ($success) {
                    echo "✅ Variables synchronisées avec le shell principal\n";
                    return;
                }
            }
            
            // Fallback: synchronisation manuelle
            $this->manualSyncToMainShell($variables);
            
        } catch (\Exception $e) {
            echo "⚠️  Attention: Impossible de synchroniser avec le shell principal: " . $e->getMessage() . "\n";
        }
    }
    
    /**
     * Synchronisation manuelle vers le shell principal (fallback)
     */
    protected function manualSyncToMainShell(array $variables): void
    {
        // Mettre à jour le contexte global du shell principal
        $GLOBALS['psysh_main_shell_context'] = array_merge(
            $GLOBALS['psysh_main_shell_context'] ?? [],
            $variables
        );
        
        // Mettre à jour le fichier de persistance
        try {
            $tempDir = sys_get_temp_dir();
            $filename = $tempDir . '/psysh_variables_' . getmypid() . '.dat';
            $existingVars = [];
            if (file_exists($filename)) {
                $data = file_get_contents($filename);
                $existingVars = unserialize($data);
                if (!is_array($existingVars)) {
                    $existingVars = [];
                }
            }
            $updatedVars = array_merge($existingVars, $variables);
            file_put_contents($filename, serialize($updatedVars), LOCK_EX);
        } catch (\Exception $e) {
            // Ignore les erreurs de sauvegarde
        }
        
        // Essayer de synchroniser avec le shell principal si possible
        $this->tryUpdateMainShellDirectly($variables);
    }
    
    /**
     * Tente de mettre à jour directement le shell principal
     */
    protected function tryUpdateMainShellDirectly(array $variables): void
    {
        try {
            // Vérifier si on peut accéder au shell principal
            if (isset($GLOBALS['psysh_main_shell_instance'])) {
                $mainShell = $GLOBALS['psysh_main_shell_instance'];
                
                if ($mainShell instanceof \Psy\Shell) {
                    // Récupérer les variables actuelles du shell principal
                    $currentVars = $mainShell->getScopeVariables();
                    
                    // Fusionner avec les nouvelles variables
                    $updatedVars = array_merge($currentVars, $variables);
                    
                    // Mettre à jour le scope du shell principal
                    $mainShell->setScopeVariables($updatedVars);
                    
                    echo "✅ Variables synchronisées avec le shell principal\n";
                }
            }
        } catch (\Exception $e) {
            // Échec silencieux - la synchronisation via globals/session devrait suffire
        }
    }

    protected function getClassMethods(string $className): array
    {
        if (class_exists($className)) {
            $reflection = new \ReflectionClass($className);
            return array_map(fn($method) => $method->getName(), $reflection->getMethods(\ReflectionMethod::IS_PUBLIC));
        }
        return [];
    }

    protected function getClassHelp(string $className): string
    {
        if (class_exists($className)) {
            $reflection = new \ReflectionClass($className);
            $methods = $reflection->getMethods(\ReflectionMethod::IS_PUBLIC);
            
            $help = "📋 {$className} - Méthodes disponibles :\n";
            foreach ($methods as $method) {
                $params = array_map(fn($param) => $param->getName(), $method->getParameters());
                $paramStr = implode(', ', $params);
                $help .= "- {$method->getName()}({$paramStr})\n";
            }
            return $help;
        }
        return "❌ Classe {$className} non trouvée";
    }
    
    /**
     * Obtient l'expression complète à partir de l'input
     */
    protected function getExpressionFromInput(\Symfony\Component\Console\Input\InputInterface $input, string $argumentName = 'expression'): string
    {
        // Utiliser l'expression brute capturée si disponible
        $rawExpression = $this->getRawExpression();
        
        if (!empty($rawExpression)) {
            return $rawExpression;
        }
        
        // Fallback sur les arguments classiques
        $args = $input->getArgument($argumentName);
        if (is_array($args)) {
            return implode(' ', $args);
        }
        
        return (string) $args;
    }
    
    /**
     * Évalue une expression PHP et retourne le résultat avec des détails
     */
    protected function evaluateExpression(string $expression): array
    {
        try {
            $result = $this->executePhpCode("return ($expression);");
            
            if (is_string($result) && strpos($result, 'Erreur:') === 0) {
                return [
                    'success' => false,
                    'result' => null,
                    'error' => $result
                ];
            }
            
            return [
                'success' => true,
                'result' => $result,
                'error' => null
            ];
            
        } catch (\Exception $e) {
            return [
                'success' => false,
                'result' => null,
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Validate required arguments
     */
    protected function validateArguments(\Symfony\Component\Console\Input\InputInterface $input, \Symfony\Component\Console\Output\OutputInterface $output): bool
    {
        if (!method_exists($this, 'getRequiredArguments')) {
            return true;
        }
        
        $requiredArgs = $this->getRequiredArguments();
        foreach ($requiredArgs as $arg) {
            if (!$input->getArgument($arg)) {
                $output->writeln($this->formatError("Argument requis manquant: {$arg}"));
                return false;
            }
        }
        return true;
    }

    /**
     * Get required arguments for the command
     */
    protected function getRequiredArguments(): array
    {
        return [];
    }
    
    /**
     * Get shell variables
     */
    protected function getShellVariables(): array
    {
        return $GLOBALS['psysh_shell_variables'] ?? [];
    }
    
    /**
     * Set shell variable
     */
    protected function setShellVariable(string $name, $value): void
    {
        // Try to set in actual shell context first
        $shell = $this->getApplication();
        if ($shell instanceof \Psy\Shell) {
            $currentVars = $shell->getScopeVariables();
            $currentVars[$name] = $value;
            $shell->setScopeVariables($currentVars);
        }
        
        // Also maintain in globals for backward compatibility
        if (!isset($GLOBALS['psysh_shell_variables'])) {
            $GLOBALS['psysh_shell_variables'] = [];
        }
        $GLOBALS['psysh_shell_variables'][$name] = $value;
    }
    
    /**
     * Format test code
     */
    protected function formatTestCode(string $code): string
    {
        return "```php\n" . $code . "\n```";
    }
}
