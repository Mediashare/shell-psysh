<?php

namespace Psy\Extended\Service;

use Psy\Shell;

/**
 * Unified synchronization service for variables across all contexts
 * (main shell, sub-shells, eval, phpunit:code, etc.)
 */
class UnifiedSyncService
{
    private static ?self $instance = null;
    private ?Shell $mainShell = null;
    private array $variableStore = [];
    private array $shellHistory = [];
    private bool $debug = false;
    
    private function __construct()
    {
        $this->initializeStorage();
    }
    
    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /**
     * Initializes variable storage
     */
    private function initializeStorage(): void
    {
        // Load variables from all existing sources
        $this->variableStore = array_merge(
            $this->loadFromFile(),
            $GLOBALS['psysh_shell_variables'] ?? [],
            $GLOBALS['psysh_main_shell_context'] ?? [],
            $GLOBALS['phpunit_code_context'] ?? []
        );
        
        // Create singleton service in globals
        $GLOBALS['psysh_unified_sync_service'] = $this;
    }
    
    /**
     * Sets the main shell
     */
    public function setMainShell(Shell $shell): void
    {
        $this->mainShell = $shell;
        $GLOBALS['psysh_main_shell_instance'] = $shell;
        
        // Synchronize existing variables to shell
        if (!empty($this->variableStore)) {
            $this->syncToShell($shell, $this->variableStore);
        }
    }
    
    /**
     * Enables/disables debug mode
     */
    public function setDebug(bool $debug): void
    {
        $this->debug = $debug;
        $GLOBALS['psysh_sync_debug'] = $debug;
        
        if ($debug) {
            echo "\n" . str_repeat('=', 60) . "\n";
            echo "🐛 MODE DEBUG ACTIVÉ - Synchronisation Unifiée\n";
            echo str_repeat('=', 60) . "\n";
            echo "📊 Variables actuelles dans le store: " . count($this->variableStore) . "\n";
            if (!empty($this->variableStore)) {
                echo "📋 Liste des variables:\n";
                foreach ($this->variableStore as $name => $value) {
                    $type = gettype($value);
                    $preview = $this->getVariablePreview($value);
                    echo "   - \$$name ($type): $preview\n";
                }
            }
            echo str_repeat('=', 60) . "\n\n";
        }
    }
    
    /**
     * Retrieves all variables from the unified store
     */
    public function getAllVariables(): array
    {
        return $this->variableStore;
    }
    
    /**
     * Updates a variable in the unified store
     */
    public function setVariable(string $name, $value): void
    {
        $this->variableStore[$name] = $value;
        $this->syncToAllContexts([$name => $value]);
        
        if ($this->debug) {
            echo "[DEBUG] Variable '$name' updated in the unified store\n";
        }
    }
    
    /**
     * Updates multiple variables in the unified store
     */
    public function setVariables(array $variables): void
    {
        $this->variableStore = array_merge($this->variableStore, $variables);
        $this->syncToAllContexts($variables);
        
        if ($this->debug) {
            echo "[DEBUG] " . count($variables) . " variables updated in the unified store\n";
        }
    }
    
    /**
     * Synchronizes variables to all contexts
     */
    private function syncToAllContexts(array $variables): void
    {
        // 1. Synchronize to the main shell
        if ($this->mainShell) {
            $this->syncToShell($this->mainShell, $variables);
        }
        
        // 2. Synchronize to globals
        $this->syncToGlobals($variables);
        
        // 3. Synchronize to persistent file
        $this->saveToFile($this->variableStore);
        
        // 4. Synchronize to specialized contexts
        $this->syncToSpecializedContexts($variables);
    }
    
    /**
     * Synchronizes to a specific shell
     */
    private function syncToShell(Shell $shell, array $variables): void
    {
        try {
            $currentVars = $shell->getScopeVariables();
            $updatedVars = array_merge($currentVars, $variables);
            $shell->setScopeVariables($updatedVars);
            
            if ($this->debug) {
                echo "[DEBUG] Variables synchronized to the main shell\n";
            }
        } catch (\Exception $e) {
            if ($this->debug) {
                echo "[DEBUG] Error synchronizing to the shell: " . $e->getMessage() . "\n";
            }
        }
    }
    
    /**
     * Synchronizes to globals
     */
    private function syncToGlobals(array $variables): void
    {
        $GLOBALS['psysh_shell_variables'] = array_merge(
            $GLOBALS['psysh_shell_variables'] ?? [],
            $variables
        );
        
        $GLOBALS['psysh_main_shell_context'] = array_merge(
            $GLOBALS['psysh_main_shell_context'] ?? [],
            $variables
        );
        
        $GLOBALS['phpunit_code_context'] = array_merge(
            $GLOBALS['phpunit_code_context'] ?? [],
            $variables
        );
    }
    
    /**
     * Synchronizes to specialized contexts
     */
    private function syncToSpecializedContexts(array $variables): void
    {
        // Synchronize to the existing ShellSyncService if present
        if (isset($GLOBALS['psysh_shell_sync_service'])) {
            $syncService = $GLOBALS['psysh_shell_sync_service'];
            if ($syncService instanceof ShellSyncService) {
                $syncService->syncToMainShell($variables);
            }
        }
    }
    
    /**
     * Captures variables from the main shell
     */
    public function captureFromMainShell(): array
    {
        if (!$this->mainShell) {
            return [];
        }
        
        try {
            $currentVars = $this->mainShell->getScopeVariables();
            
            // Detect new variables
            $newVars = [];
            foreach ($currentVars as $name => $value) {
                if (!isset($this->variableStore[$name]) || $this->variableStore[$name] !== $value) {
                    $newVars[$name] = $value;
                }
            }
            
            // Update the store with new variables
            if (!empty($newVars)) {
                $this->variableStore = array_merge($this->variableStore, $newVars);
                $this->syncToAllContexts($newVars);
                
                if ($this->debug) {
                    echo "[DEBUG] " . count($newVars) . " new variables captured from the main shell\n";
                }
            }
            
            return $newVars;
        } catch (\Exception $e) {
            if ($this->debug) {
                echo "[DEBUG] Error capturing from the main shell: " . $e->getMessage() . "\n";
            }
            return [];
        }
    }
    
    /**
     * Executes PHP code with automatic synchronization
     */
    public function executeWithSync(string $code, array &$context = []): mixed
    {
        // Merge context with unified store
        $allVars = array_merge($this->variableStore, $context);
        
        // Extract variables to local context
        extract($allVars);
        
        try {
            // Execute code
            $result = eval($code);
            
            // Capture new variables
            $newVars = get_defined_vars();
            
            // Filter system variables
            $systemVars = ['code', 'context', 'allVars', 'newVars', 'result'];
            foreach ($systemVars as $var) {
                unset($newVars[$var]);
            }
            
            // Detect changed variables
            $changedVars = [];
            foreach ($newVars as $name => $value) {
                if (!isset($allVars[$name]) || $allVars[$name] !== $value) {
                    $changedVars[$name] = $value;
                }
            }
            
            // Update context and store
            if (!empty($changedVars)) {
                $context = array_merge($context, $changedVars);
                $this->setVariables($changedVars);
            }
            
            return $result;
        } catch (\Throwable $e) {
            if ($this->debug) {
                echo "[DEBUG] Error during execution: " . $e->getMessage() . "\n";
            }
            return "Erreur: " . $e->getMessage();
        }
    }
    
    /**
     * Creates a sub-shell with automatic synchronization
     */
    public function createSyncedSubShell(string $prompt = 'sub> '): Shell
    {
        $config = new \Psy\Configuration();
        $config->setPrompt($prompt);
        
        $shell = new Shell($config);
        
        // Inject all variables from the unified store
        $shell->setScopeVariables($this->variableStore);
        
        if ($this->debug) {
            echo "[DEBUG] Sub-shell created with " . count($this->variableStore) . " variables\n";
        }
        
        return $shell;
    }
    
    /**
     * Synchronizes from a sub-shell to the unified store
     */
    public function syncFromSubShell(Shell $shell): void
    {
        try {
            $shellVars = $shell->getScopeVariables();
            
            // Detect changed variables
            $changedVars = [];
            foreach ($shellVars as $name => $value) {
                if (!isset($this->variableStore[$name]) || $this->variableStore[$name] !== $value) {
                    $changedVars[$name] = $value;
                }
            }
            
            // Update store with changes
            if (!empty($changedVars)) {
                $this->setVariables($changedVars);
            }
            
            if ($this->debug) {
                echo "[DEBUG] " . count($changedVars) . " variables synchronized from the sub-shell\n";
            }
        } catch (\Exception $e) {
            if ($this->debug) {
                echo "[DEBUG] Error synchronizing from the sub-shell: " . $e->getMessage() . "\n";
            }
        }
    }
    
    /**
     * Saves variables to a file
     */
    private function saveToFile(array $variables): void
    {
        try {
            $filename = $this->getFilePath();
            $data = serialize($variables);
            file_put_contents($filename, $data, LOCK_EX);
        } catch (\Exception $e) {
            if ($this->debug) {
                echo "[DEBUG] Error saving to file: " . $e->getMessage() . "\n";
            }
        }
    }
    
    /**
     * Loads variables from a file
     */
    private function loadFromFile(): array
    {
        try {
            $filename = $this->getFilePath();
            if (file_exists($filename)) {
                $data = file_get_contents($filename);
                $variables = unserialize($data);
                return is_array($variables) ? $variables : [];
            }
        } catch (\Exception $e) {
            if ($this->debug) {
                echo "[DEBUG] Error loading from file: " . $e->getMessage() . "\n";
            }
        }
        return [];
    }
    
    /**
     * Returns the file path for persistence
     */
    private function getFilePath(): string
    {
        $tempDir = sys_get_temp_dir();
        return $tempDir . '/psysh_unified_variables_' . getmypid() . '.dat';
    }
    
    /**
     * Cleans up resources
     */
    public function cleanup(): void
    {
        $filename = $this->getFilePath();
        if (file_exists($filename)) {
            unlink($filename);
        }
        
        if ($this->debug) {
            echo "[DEBUG] Cleanup completed\n";
        }
    }
    
    /**
     * Gets stats on the store
     */
    public function getStats(): array
    {
        return [
            'total_variables' => count($this->variableStore),
            'has_main_shell' => $this->mainShell !== null,
            'debug_enabled' => $this->debug,
            'file_path' => $this->getFilePath(),
            'file_exists' => file_exists($this->getFilePath())
        ];
    }
    
    /**
     * Get a preview of a variable for debug output
     */
    private function getVariablePreview($value): string
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
    
    /**
     * Debug output for sync operations
     */
    public function debugOutput(string $message, array $context = []): void
    {
        if (!$this->debug) {
            return;
        }
        
        $timestamp = date('H:i:s');
        echo "[DEBUG $timestamp] $message\n";
        
        if (!empty($context)) {
            foreach ($context as $key => $value) {
                $preview = $this->getVariablePreview($value);
                echo "   - $key: $preview\n";
            }
        }
    }
}
