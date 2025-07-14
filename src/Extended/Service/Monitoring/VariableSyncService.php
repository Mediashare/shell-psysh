<?php

namespace Psy\Extended\Service\Monitoring;

use Psy\Shell;
use Symfony\Component\Console\Output\OutputInterface;

/**
 * Service pour synchroniser les variables avec le shell PsySH
 * Gère la capture et la propagation des nouvelles variables, fonctions et classes
 */
class VariableSyncService
{
    private ?Shell $shell = null;
    private bool $debug = false;
    private ?OutputInterface $output = null;
    
    public function __construct(?Shell $shell = null)
    {
        $this->shell = $shell;
    }
    
    /**
     * Configure le shell PsySH
     */
    public function setShell(Shell $shell): void
    {
        $this->shell = $shell;
    }
    
    /**
     * Configure le mode debug et la sortie
     */
    public function configure(bool $debug = false, ?OutputInterface $output = null): void
    {
        $this->debug = $debug;
        $this->output = $output;
    }
    
    // Ces méthodes ne sont plus nécessaires avec la nouvelle approche
    // mais on les garde pour compatibilité
    
    /**
     * Synchronise les variables avec le shell PsySH
     */
    public function syncVariables(array $variables): void
    {
        if (!$this->shell || empty($variables)) {
            return;
        }
        
        try {
            // Récupérer les variables actuelles du shell
            $currentVars = $this->shell->getScopeVariables();
            
            // Fusionner avec les nouvelles variables
            $updatedVars = array_merge($currentVars, $variables);
            
            // Mettre à jour les variables du scope dans le shell
            $this->shell->setScopeVariables($updatedVars);
            
            // Désactivé pour un affichage plus propre
            // if ($this->debug && $this->output) {
            //     foreach ($variables as $name => $value) {
            //         $this->logVariableSync($name, $value);
            //     }
            // }
        } catch (\Exception $e) {
            if ($this->debug && $this->output) {
                $this->output->writeln(sprintf(
                    "<comment>Debug: Erreur lors de la synchronisation: %s</comment>",
                    $e->getMessage()
                ));
            }
        }
    }
    
    /**
     * Synchronise l'état complet (variables, fonctions, classes)
     */
    public function syncState(array $changes): void
    {
        // Synchroniser les variables
        if (!empty($changes['variables'])) {
            $this->syncVariables($changes['variables']);
        }
        
        // Ne plus afficher les nouvelles fonctions et classes définies
    }
    
    /**
     * Log la synchronisation d'une variable
     */
    private function logVariableSync(string $name, $value): void
    {
        $type = gettype($value);
        if (is_object($value)) {
            $type = get_class($value);
        }
        
        $this->output->writeln(sprintf(
            "<comment>Debug: Variable '%s' (%s) synchronisée avec PsySH</comment>",
            $name,
            $type
        ));
    }
}
