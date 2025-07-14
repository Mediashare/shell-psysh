<?php

namespace Psy\Extended\Service;

class PHPUnitPerformanceService
{
    private array $benchmarkResults = [];
    private static $instance = null;

    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function saveBenchmarkResult(string $name, array $stats): void
    {
        $this->benchmarkResults[$name] = [
            'stats' => $stats,
            'timestamp' => time(),
            'id' => uniqid()
        ];
    }

    public function getBenchmarkResult(string $name): ?array
    {
        return $this->benchmarkResults[$name] ?? null;
    }

    public function getAllBenchmarks(): array
    {
        return $this->benchmarkResults;
    }

    public function compareBenchmarks(string $name1, string $name2): array
    {
        $benchmark1 = $this->getBenchmarkResult($name1);
        $benchmark2 = $this->getBenchmarkResult($name2);

        if (!$benchmark1 || !$benchmark2) {
            throw new \InvalidArgumentException("Un ou plusieurs benchmarks non trouvés");
        }

        $stats1 = $benchmark1['stats'];
        $stats2 = $benchmark2['stats'];

        $timeImprovement = (($stats1['avg_time'] - $stats2['avg_time']) / $stats1['avg_time']) * 100;
        $memoryImprovement = (($stats1['avg_memory'] - $stats2['avg_memory']) / $stats1['avg_memory']) * 100;

        return [
            'name1' => $name1,
            'name2' => $name2,
            'time_improvement' => $timeImprovement,
            'memory_improvement' => $memoryImprovement,
            'stats1' => $stats1,
            'stats2' => $stats2
        ];
    }

    public function clearBenchmarks(): void
    {
        $this->benchmarkResults = [];
    }

    public function removeBenchmark(string $name): bool
    {
        if (isset($this->benchmarkResults[$name])) {
            unset($this->benchmarkResults[$name]);
            return true;
        }
        return false;
    }
}
