<?php

namespace Psy\Extended\Service\Monitoring;

/**
 * Service pour le tracking détaillé en mode debug
 * Gère le suivi des lignes, les traces d'exécution et les statistiques
 */
class DebugTrackingService
{
    private bool $debugMode = false;
    private array $executionTrace = [];
    private array $lineStats = [];
    private array $functionCalls = [];
    private array $variableChanges = [];
    private int $currentLine = 0;
    private array $codeLines = [];
    private float $lastTickTime = 0;
    private array $memoryByLine = [];
    private array $loopIterations = [];
    
    /**
     * Active/désactive le mode debug
     */
    public function setDebugMode(bool $debug): void
    {
        $this->debugMode = $debug;
    }
    
    /**
     * Définit les lignes de code à tracker
     */
    public function setCodeLines(array $lines): void
    {
        $this->codeLines = $lines;
        // Initialiser les statistiques par ligne
        foreach (array_keys($lines) as $lineNum) {
            $this->lineStats[$lineNum] = [
                'count' => 0,
                'total_time' => 0,
                'min_time' => PHP_FLOAT_MAX,
                'max_time' => 0,
                'memory_usage' => []
            ];
        }
    }
    
    /**
     * Enregistre une exécution de ligne
     */
    public function recordLineExecution(int $lineNumber, float $time, int $memory): void
    {
        if (!$this->debugMode) {
            return;
        }
        
        $this->currentLine = $lineNumber;
        
        // Calculer le temps depuis le dernier tick
        $tickTime = $this->lastTickTime > 0 ? $time - $this->lastTickTime : 0;
        $this->lastTickTime = $time;
        
        // Mettre à jour les statistiques
        if (isset($this->lineStats[$lineNumber])) {
            $this->lineStats[$lineNumber]['count']++;
            $this->lineStats[$lineNumber]['total_time'] += $tickTime;
            $this->lineStats[$lineNumber]['min_time'] = min($this->lineStats[$lineNumber]['min_time'], $tickTime);
            $this->lineStats[$lineNumber]['max_time'] = max($this->lineStats[$lineNumber]['max_time'], $tickTime);
            $this->lineStats[$lineNumber]['memory_usage'][] = $memory;
        }
        
        // Ajouter à la trace
        $this->executionTrace[] = [
            'line' => $lineNumber,
            'time' => $time,
            'memory' => $memory,
            'tick_time' => $tickTime
        ];
        
        // Enregistrer l'utilisation mémoire par ligne
        $this->memoryByLine[$lineNumber] = $memory;
        
        // Détecter les boucles
        $this->detectLoops($lineNumber);
    }
    
    /**
     * Détecte les boucles en cours d'exécution
     */
    private function detectLoops(int $lineNumber): void
    {
        // Chercher des patterns de répétition dans la trace
        $traceLength = count($this->executionTrace);
        if ($traceLength < 3) {
            return;
        }
        
        // Vérifier les 10 dernières exécutions pour des patterns
        $recent = array_slice($this->executionTrace, -10);
        $lines = array_column($recent, 'line');
        
        // Compter les occurrences
        $counts = array_count_values($lines);
        foreach ($counts as $line => $count) {
            if ($count >= 3) {
                if (!isset($this->loopIterations[$line])) {
                    $this->loopIterations[$line] = 0;
                }
                $this->loopIterations[$line] = $count;
            }
        }
    }
    
    /**
     * Enregistre un appel de fonction
     */
    public function recordFunctionCall(string $function, array $args, float $time): void
    {
        if (!$this->debugMode) {
            return;
        }
        
        if (!isset($this->functionCalls[$function])) {
            $this->functionCalls[$function] = [
                'count' => 0,
                'total_time' => 0,
                'args' => []
            ];
        }
        
        $this->functionCalls[$function]['count']++;
        $this->functionCalls[$function]['args'][] = $args;
    }
    
    /**
     * Enregistre un changement de variable
     */
    public function recordVariableChange(string $variable, $oldValue, $newValue, float $time): void
    {
        if (!$this->debugMode) {
            return;
        }
        
        $this->variableChanges[] = [
            'variable' => $variable,
            'old_value' => $this->formatValue($oldValue),
            'new_value' => $this->formatValue($newValue),
            'time' => $time,
            'line' => $this->currentLine
        ];
    }
    
    /**
     * Formate une valeur pour l'affichage
     */
    private function formatValue($value): string
    {
        if (is_null($value)) {
            return 'null';
        }
        if (is_bool($value)) {
            return $value ? 'true' : 'false';
        }
        if (is_string($value)) {
            return strlen($value) > 50 ? substr($value, 0, 50) . '...' : $value;
        }
        if (is_array($value)) {
            return 'array(' . count($value) . ')';
        }
        if (is_object($value)) {
            return get_class($value);
        }
        return (string) $value;
    }
    
    /**
     * Obtient la ligne de code actuelle
     */
    public function getCurrentCodeLine(): ?string
    {
        if (!$this->debugMode || !isset($this->codeLines[$this->currentLine - 1])) {
            return null;
        }
        return $this->codeLines[$this->currentLine - 1];
    }
    
    /**
     * Obtient les informations de debug pour l'affichage
     */
    public function getDebugInfo(): array
    {
        if (!$this->debugMode) {
            return [];
        }
        
        return [
            'current_line' => $this->currentLine,
            'code_line' => $this->getCurrentCodeLine(),
            'execution_count' => $this->lineStats[$this->currentLine]['count'] ?? 0,
            'loop_iteration' => $this->loopIterations[$this->currentLine] ?? null,
            'memory_at_line' => $this->memoryByLine[$this->currentLine] ?? 0,
            'recent_changes' => array_slice($this->variableChanges, -3)
        ];
    }
    
    /**
     * Génère un rapport de trace pour les erreurs
     */
    public function getErrorTrace(int $errorLine): array
    {
        if (!$this->debugMode) {
            return [];
        }
        
        // Obtenir les 10 dernières lignes exécutées avant l'erreur
        $recentTrace = array_slice($this->executionTrace, -10);
        
        $trace = [];
        foreach ($recentTrace as $entry) {
            $trace[] = [
                'line' => $entry['line'],
                'code' => $this->codeLines[$entry['line'] - 1] ?? 'Unknown',
                'time' => sprintf('%.4f', $entry['time']),
                'memory' => $this->formatBytes($entry['memory'])
            ];
        }
        
        return $trace;
    }
    
    /**
     * Obtient les statistiques complètes
     */
    public function getFullStats(): array
    {
        if (!$this->debugMode) {
            return [];
        }
        
        $stats = [
            'line_stats' => [],
            'hot_spots' => [],
            'function_calls' => $this->functionCalls,
            'variable_changes' => $this->variableChanges,
            'loop_analysis' => []
        ];
        
        // Analyser les lignes
        foreach ($this->lineStats as $line => $data) {
            if ($data['count'] > 0) {
                $avgTime = $data['total_time'] / $data['count'];
                $avgMemory = !empty($data['memory_usage']) 
                    ? array_sum($data['memory_usage']) / count($data['memory_usage']) 
                    : 0;
                
                $stats['line_stats'][$line] = [
                    'code' => trim($this->codeLines[$line - 1] ?? 'Unknown'),
                    'executions' => $data['count'],
                    'total_time' => sprintf('%.4f', $data['total_time']),
                    'avg_time' => sprintf('%.4f', $avgTime),
                    'avg_memory' => $this->formatBytes((int)$avgMemory)
                ];
                
                // Identifier les hot spots (lignes qui prennent plus de 10% du temps total)
                if ($data['total_time'] > 0.1) {
                    $stats['hot_spots'][] = [
                        'line' => $line,
                        'time' => $data['total_time'],
                        'executions' => $data['count']
                    ];
                }
            }
        }
        
        // Analyser les boucles
        foreach ($this->loopIterations as $line => $iterations) {
            $stats['loop_analysis'][] = [
                'line' => $line,
                'code' => trim($this->codeLines[$line - 1] ?? 'Unknown'),
                'iterations' => $iterations
            ];
        }
        
        return $stats;
    }
    
    /**
     * Formate les bytes en unité lisible
     */
    private function formatBytes(int $bytes): string
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        $i = 0;
        while ($bytes >= 1024 && $i < count($units) - 1) {
            $bytes /= 1024;
            $i++;
        }
        return round($bytes, 2) . ' ' . $units[$i];
    }
    
    /**
     * Réinitialise le tracking
     */
    public function reset(): void
    {
        $this->executionTrace = [];
        $this->lineStats = [];
        $this->functionCalls = [];
        $this->variableChanges = [];
        $this->currentLine = 0;
        $this->lastTickTime = 0;
        $this->memoryByLine = [];
        $this->loopIterations = [];
    }
}
