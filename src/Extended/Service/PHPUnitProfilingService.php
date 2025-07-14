<?php

namespace Psy\Extended\Service;

/**
 * Service for profiling code execution in tests
 */
class PHPUnitProfilingService
{
    private float $startTime;
    private int $startMemory;
    private int $peakMemory;

    public function profileExpression(string $expression): array
    {
        // Start profiling
        $this->startProfiling();
        
        try {
            // Execute the expression
            $result = eval($expression);
            
            // Stop profiling
            $metrics = $this->stopProfiling();
            
            return [
                'result' => $result,
                'execution_time' => $metrics['execution_time'],
                'memory_usage' => $this->formatBytes($metrics['memory_used']),
                'peak_memory' => $this->formatBytes($metrics['peak_memory']),
                'bottlenecks' => $this->analyzeBottlenecks($metrics)
            ];
        } catch (\Throwable $e) {
            throw new \Exception('Failed to profile expression: ' . $e->getMessage());
        }
    }

    private function startProfiling(): void
    {
        $this->startTime = microtime(true);
        $this->startMemory = memory_get_usage(true);
        $this->peakMemory = memory_get_peak_usage(true);
    }

    private function stopProfiling(): array
    {
        $endTime = microtime(true);
        $endMemory = memory_get_usage(true);
        $currentPeak = memory_get_peak_usage(true);
        
        return [
            'execution_time' => round(($endTime - $this->startTime) * 1000, 2), // in milliseconds
            'memory_used' => $endMemory - $this->startMemory,
            'peak_memory' => max($currentPeak, $this->peakMemory),
            'start_memory' => $this->startMemory,
            'end_memory' => $endMemory
        ];
    }

    private function formatBytes(int $bytes): string
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        
        $bytes /= pow(1024, $pow);
        
        return round($bytes, 2) . ' ' . $units[$pow];
    }

    private function analyzeBottlenecks(array $metrics): array
    {
        $bottlenecks = [];
        
        // Check execution time
        if ($metrics['execution_time'] > 100) {
            $bottlenecks[] = 'Execution time exceeds 100ms - consider optimization';
        }
        
        // Check memory usage
        if ($metrics['memory_used'] > 10 * 1024 * 1024) { // 10MB
            $bottlenecks[] = 'High memory usage detected - check for memory leaks';
        }
        
        // Check peak memory
        if ($metrics['peak_memory'] > 50 * 1024 * 1024) { // 50MB
            $bottlenecks[] = 'Peak memory usage is high - consider memory optimization';
        }
        
        return $bottlenecks;
    }
}
