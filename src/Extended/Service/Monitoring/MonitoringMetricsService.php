<?php

namespace Psy\Extended\Service\Monitoring;

/**
 * Service pour gérer les métriques de monitoring
 * Collecte et calcule les statistiques de performance
 */
class MonitoringMetricsService
{
    private float $startTime;
    private int $startMemory;
    private int $tickCount = 0;
    private array $metrics = [];
    private float $lastTickTime;
    
    /**
     * Initialise les métriques de monitoring
     */
    public function initialize(): void
    {
        $this->startTime = microtime(true);
        $this->startMemory = memory_get_usage(true);
        $this->tickCount = 0;
        $this->metrics = [];
        $this->lastTickTime = $this->startTime;
    }
    
    /**
     * Enregistre une métrique à un instant donné
     */
    public function recordMetric(): void
    {
        $currentTime = microtime(true);
        $currentMemory = memory_get_usage(true);
        
        $this->metrics[] = [
            'time' => $currentTime - $this->startTime,
            'memory' => $currentMemory - $this->startMemory,
            'tick' => $this->tickCount,
        ];
    }
    
    /**
     * Incrémente le compteur de ticks
     */
    public function incrementTick(): void
    {
        $this->tickCount++;
        $this->lastTickTime = microtime(true);
    }
    
    /**
     * Retourne le temps total d'exécution
     */
    public function getTotalTime(): float
    {
        return microtime(true) - $this->startTime;
    }
    
    /**
     * Retourne la mémoire totale utilisée
     */
    public function getTotalMemoryUsage(): int
    {
        return memory_get_usage(true) - $this->startMemory;
    }
    
    /**
     * Retourne le pic de mémoire utilisée
     */
    public function getPeakMemoryUsage(): int
    {
        return memory_get_peak_usage(true) - $this->startMemory;
    }
    
    /**
     * Retourne le nombre total de ticks
     */
    public function getTotalTicks(): int
    {
        return $this->tickCount;
    }
    
    /**
     * Retourne les ticks par seconde
     */
    public function getTicksPerSecond(): float
    {
        $totalTime = $this->getTotalTime();
        return $totalTime > 0 ? $this->tickCount / $totalTime : 0;
    }
    
    /**
     * Retourne toutes les métriques collectées
     */
    public function getMetrics(): array
    {
        return $this->metrics;
    }
    
    /**
     * Retourne un résumé des métriques
     */
    public function getSummary(): array
    {
        return [
            'total_time' => $this->getTotalTime(),
            'total_memory' => $this->getTotalMemoryUsage(),
            'peak_memory' => $this->getPeakMemoryUsage(),
            'total_ticks' => $this->getTotalTicks(),
            'ticks_per_second' => $this->getTicksPerSecond(),
            'metrics_count' => count($this->metrics),
        ];
    }
    
    /**
     * Formate les bytes en unité lisible
     */
    public function formatBytes(int $bytes): string
    {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        
        $bytes /= (1 << (10 * $pow));
        
        return round($bytes, 2) . ' ' . $units[$pow];
    }
    
    /**
     * Parse une chaîne de bytes (ex: "128M") en entier
     */
    public function parseBytes(string $val): int
    {
        $val = trim($val);
        if (empty($val)) {
            return 0;
        }
        
        $last = strtolower($val[strlen($val)-1]);
        $val = (int) $val;
        
        switch($last) {
            case 'g':
                $val *= 1024;
            case 'm':
                $val *= 1024;
            case 'k':
                $val *= 1024;
        }
        
        return $val;
    }
}
