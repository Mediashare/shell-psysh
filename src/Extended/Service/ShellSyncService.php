<?php

namespace Psy\Extended\Service;

use Psy\Shell;

/**
 * Service pour la synchronisation continue entre shell principal et phpunit:code
 */
class ShellSyncService
{
    private ?Shell $mainShell = null;
    private array $lastKnownVariables = [];
    
    public function __construct(?Shell $mainShell = null)
    {
        $this->mainShell = $mainShell;
    }
    
    /**
     * Définit le shell principal
     */
    public function setMainShell(Shell $shell): void
    {
        $this->mainShell = $shell;
    }
    
    /**
     * Capture les variables du shell principal
     */
    public function captureMainShellVariables(): array
    {
        if (!$this->mainShell) {
            return [];
        }
        
        try {
            $currentVariables = $this->mainShell->getScopeVariables();
            
            // Détecter les nouvelles variables
            $newVariables = [];
            foreach ($currentVariables as $name => $value) {
                if (!isset($this->lastKnownVariables[$name]) || 
                    $this->lastKnownVariables[$name] !== $value) {
                    $newVariables[$name] = $value;
                }
            }
            
            // Mettre à jour le cache
            $this->lastKnownVariables = $currentVariables;
            
            // Synchroniser avec les globals
            $GLOBALS['psysh_main_shell_context'] = $currentVariables;
            
            // Sauvegarder dans un fichier pour persistance
            $this->saveVariablesToFile($currentVariables);
            
            return $newVariables;
            
        } catch (\Exception $e) {
            return [];
        }
    }
    
    /**
     * Synchronise les variables vers le shell principal
     */
    public function syncToMainShell(array $variables): bool
    {
        if (!$this->mainShell || empty($variables)) {
            return false;
        }
        
        try {
            // Récupérer les variables actuelles
            $currentVariables = $this->mainShell->getScopeVariables();
            
            // Fusionner avec les nouvelles variables
            $updatedVariables = array_merge($currentVariables, $variables);
            
            // Mettre à jour le scope du shell
            $this->mainShell->setScopeVariables($updatedVariables);
            
            // Mettre à jour le cache
            $this->lastKnownVariables = $updatedVariables;
            
            // Mettre à jour les globals
            $GLOBALS['psysh_main_shell_context'] = $updatedVariables;
            
            // Sauvegarder dans un fichier pour persistance
            $this->saveVariablesToFile($updatedVariables);
            
            return true;
            
        } catch (\Exception $e) {
            return false;
        }
    }
    
    /**
     * Récupère toutes les variables du shell principal
     */
    public function getMainShellVariables(): array
    {
        if (!$this->mainShell) {
            return $GLOBALS['psysh_main_shell_context'] ?? [];
        }
        
        try {
            return $this->mainShell->getScopeVariables();
        } catch (\Exception $e) {
            return $GLOBALS['psysh_main_shell_context'] ?? [];
        }
    }
    
    /**
     * Initialise le service avec les variables existantes
     */
    public function initialize(): void
    {
        if ($this->mainShell) {
            try {
                $this->lastKnownVariables = $this->mainShell->getScopeVariables();
            } catch (\Exception $e) {
                $this->lastKnownVariables = [];
            }
        }
    }
    
    /**
     * Sauvegarde les variables dans un fichier
     */
    private function saveVariablesToFile(array $variables): void
    {
        try {
            $filename = $this->getVariablesFilePath();
            $data = serialize($variables);
            file_put_contents($filename, $data, LOCK_EX);
        } catch (\Exception $e) {
            // Ignore les erreurs de sauvegarde
        }
    }
    
    /**
     * Charge les variables depuis un fichier
     */
    private function loadVariablesFromFile(): array
    {
        try {
            $filename = $this->getVariablesFilePath();
            if (file_exists($filename)) {
                $data = file_get_contents($filename);
                $variables = unserialize($data);
                return is_array($variables) ? $variables : [];
            }
        } catch (\Exception $e) {
            // Ignore les erreurs de chargement
        }
        return [];
    }
    
    /**
     * Obtient le chemin du fichier de variables
     */
    private function getVariablesFilePath(): string
    {
        $tempDir = sys_get_temp_dir();
        return $tempDir . '/psysh_variables_' . getmypid() . '.dat';
    }
    
    /**
     * Charge les variables existantes au démarrage
     */
    public function loadExistingVariables(): array
    {
        return $this->loadVariablesFromFile();
    }
}
