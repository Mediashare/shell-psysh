<?php

namespace Psy\Extended\Service;

class PHPUnitMonitoringService
{
    private array $testHistory = [];
    private static $instance = null;

    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function recordTestResult(string $testName, bool $success, float $time, float $memoryUsage): void
    {
        $this->testHistory[] = [
            'name' => $testName,
            'success' => $success,
            'time' => $time,
            'memory' => $memoryUsage,
            'timestamp' => time()
        ];
    }

    public function getCurrentMetrics(): array
    {
        $totalTests = count($this->testHistory);
        if ($totalTests === 0) {
            return [
                'tests_executed' => 0,
                'average_time' => 0,
                'success_rate' => 0,
                'peak_memory' => 0,
                'recent_tests' => [],
                'performance_trends' => []
            ];
        }

        $totalTime = array_sum(array_column($this->testHistory, 'time'));
        $totalSuccess = count(array_filter($this->testHistory, fn($test) => $test['success']));
        $peakMemory = max(array_column($this->testHistory, 'memory'));

        $recentTests = array_slice($this->testHistory, -5);

        $performanceTrends = $this->calculatePerformanceTrends();

        return [
            'tests_executed' => $totalTests,
            'average_time' => number_format($totalTime / $totalTests, 3),
            'success_rate' => number_format($totalSuccess / $totalTests * 100, 2),
            'peak_memory' => number_format($peakMemory, 2),
            'recent_tests' => $recentTests,
            'performance_trends' => $performanceTrends
        ];
    }

    private function calculatePerformanceTrends(): array
    {
        if (count($this->testHistory) < 2) {
            return [];
        }

        $trends = [];

        $lastTest = end($this->testHistory);
        $prevTest = prev($this->testHistory);

        if ($lastTest['time'] !== $prevTest['time']) {
            $trends['execution_time'] = round((($lastTest['time'] - $prevTest['time']) / $prevTest['time']) * 100, 2);
        }

        if ($lastTest['memory'] !== $prevTest['memory']) {
            $trends['memory_usage'] = round((($lastTest['memory'] - $prevTest['memory']) / $prevTest['memory']) * 100, 2);
        }

        return $trends;
    }
}

