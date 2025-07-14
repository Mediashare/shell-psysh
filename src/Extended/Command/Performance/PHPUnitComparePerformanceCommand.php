<?php

namespace Psy\Extended\Command\Performance;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputOption;use Psy\Extended\Service\PHPUnitPerformanceService;

class PHPUnitComparePerformanceCommand extends \Psy\Extended\Command\BaseCommand
{
    

    public function __construct()
    {
        parent::__construct('phpunit:compare-performance');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Comparer les performances entre deux expressions ou benchmarks')
            ->addArgument('comparison', InputArgument::REQUIRED, 'Comparaison (ex: expr1 vs expr2 ou benchmark1 vs benchmark2)')
            ->addOption('iterations', 'i', InputOption::VALUE_OPTIONAL, 'Nombre d\'itérations pour chaque test', '100');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $comparison = $input->getArgument('comparison');
        $iterations = (int) $input->getOption('iterations');
        
        // Parser la comparaison
        if (!preg_match('/(.+?)\s+vs\s+(.+)/', $comparison, $matches)) {
            $output->writeln($this->formatError("Format de comparaison invalide. Utilisez: 'expr1 vs expr2'"));
            return 1;
        }
        
        $expr1 = trim($matches[1], '\'"');
        $expr2 = trim($matches[2], '\'"');
        
        try {
            $performanceService = $this->performance();
            
            $output->writeln($this->formatTest("📊 Comparaison de performance"));
            $output->writeln("Expression 1: {$expr1}");
            $output->writeln("Expression 2: {$expr2}");
            $output->writeln("Itérations: {$iterations}");
            $output->writeln("");
            
            // Benchmark des deux expressions
            $output->writeln($this->formatInfo("🏃‍♂️ Benchmark de l'expression 1..."));
            $stats1 = $this->benchmarkExpression($expr1, $iterations);
            
            $output->writeln($this->formatInfo("🏃‍♀️ Benchmark de l'expression 2..."));
            $stats2 = $this->benchmarkExpression($expr2, $iterations);
            
            // Sauvegarder les résultats
            $performanceService->saveBenchmarkResult($expr1, $stats1);
            $performanceService->saveBenchmarkResult($expr2, $stats2);
            
            // Afficher la comparaison
            $this->displayComparison($output, $expr1, $stats1, $expr2, $stats2);
            
            return 0;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de la comparaison: " . $e->getMessage()));
            return 1;
        }
    }
    
    private function benchmarkExpression(string $expression, int $iterations): array
    {
        $times = [];
        $memoryUsages = [];
        
        for ($i = 0; $i < $iterations; $i++) {
            $startTime = microtime(true);
            $startMemory = memory_get_usage();
            
            $this->executePhpCode($expression);
            
            $endTime = microtime(true);
            $endMemory = memory_get_usage();
            
            $times[] = $endTime - $startTime;
            $memoryUsages[] = ($endMemory - $startMemory) / 1024 / 1024;
        }
        
        sort($times);
        
        $count = count($times);
        $avgTime = array_sum($times) / $count;
        $medianTime = $times[floor($count / 2)];
        $minTime = min($times);
        $maxTime = max($times);
        
        $avgMemory = array_sum($memoryUsages) / count($memoryUsages);
        
        return [
            'avg_time' => $avgTime,
            'median_time' => $medianTime,
            'min_time' => $minTime,
            'max_time' => $maxTime,
            'avg_memory' => $avgMemory,
            'ops_per_second' => 1 / $avgTime
        ];
    }
    
    private function displayComparison(OutputInterface $output, string $expr1, array $stats1, string $expr2, array $stats2): void
    {
        $output->writeln("");
        $output->writeln(str_repeat("═", 80));
        $output->writeln($this->formatSuccess("📊 Comparaison :"));
        $output->writeln(str_repeat("═", 80));
        
        // Comparaison des temps moyens
        $timeImprovement = (($stats1['avg_time'] - $stats2['avg_time']) / $stats1['avg_time']) * 100;
        $fasterExpression = $timeImprovement > 0 ? $expr2 : $expr1;
        $slowerExpression = $timeImprovement > 0 ? $expr1 : $expr2;
        $improvementPercent = abs($timeImprovement);
        
        $output->writeln("⏱️  Temps d'exécution:");
        $output->writeln("  • {$expr1} : " . number_format($stats1['avg_time'], 6) . "s moyenne");
        $output->writeln("  • {$expr2} : " . number_format($stats2['avg_time'], 6) . "s moyenne");
        
        if ($improvementPercent > 1) {
            if ($timeImprovement > 0) {
                $output->writeln("  🚀 " . $this->formatSuccess("'{$expr2}' est " . number_format($improvementPercent, 1) . "% plus rapide"));
            } else {
                $output->writeln("  🚀 " . $this->formatSuccess("'{$expr1}' est " . number_format($improvementPercent, 1) . "% plus rapide"));
            }
        } else {
            $output->writeln("  ⚡ Performance similaire (différence < 1%)");
        }
        
        // Comparaison mémoire
        $memoryImprovement = (($stats1['avg_memory'] - $stats2['avg_memory']) / $stats1['avg_memory']) * 100;
        
        $output->writeln("");
        $output->writeln("💾 Usage mémoire:");
        $output->writeln("  • {$expr1} : " . number_format($stats1['avg_memory'], 3) . "MB moyenne");
        $output->writeln("  • {$expr2} : " . number_format($stats2['avg_memory'], 3) . "MB moyenne");
        
        if (abs($memoryImprovement) > 5) {
            if ($memoryImprovement > 0) {
                $output->writeln("  💚 " . $this->formatSuccess("'{$expr2}' utilise " . number_format(abs($memoryImprovement), 1) . "% moins de mémoire"));
            } else {
                $output->writeln("  💚 " . $this->formatSuccess("'{$expr1}' utilise " . number_format(abs($memoryImprovement), 1) . "% moins de mémoire"));
            }
        } else {
            $output->writeln("  📊 Usage mémoire similaire");
        }
        
        // Comparaison throughput
        $output->writeln("");
        $output->writeln("🚀 Throughput:");
        $output->writeln("  • {$expr1} : " . number_format($stats1['ops_per_second'], 0) . " ops/sec");
        $output->writeln("  • {$expr2} : " . number_format($stats2['ops_per_second'], 0) . " ops/sec");
        
        // Recommandations
        $this->displayRecommendations($output, $expr1, $stats1, $expr2, $stats2, $timeImprovement, $memoryImprovement);
        
        $output->writeln(str_repeat("═", 80));
    }
    
    private function displayRecommendations(OutputInterface $output, string $expr1, array $stats1, string $expr2, array $stats2, float $timeImprovement, float $memoryImprovement): void
    {
        $output->writeln("");
        $output->writeln("💡 Recommandations:");
        
        if (abs($timeImprovement) < 1 && abs($memoryImprovement) < 5) {
            $output->writeln("  ⚡ Les performances sont similaires - choisir selon la lisibilité du code");
        } elseif ($timeImprovement > 10 && $memoryImprovement > 0) {
            $betterExpr = $timeImprovement > 0 ? $expr2 : $expr1;
            $output->writeln("  🏆 " . $this->formatSuccess("Utiliser '{$betterExpr}' - meilleur en temps ET en mémoire"));
        } elseif (abs($timeImprovement) > abs($memoryImprovement)) {
            $fasterExpr = $timeImprovement > 0 ? $expr2 : $expr1;
            $output->writeln("  🚀 " . $this->formatSuccess("Privilégier '{$fasterExpr}' pour la vitesse d'exécution"));
        } elseif (abs($memoryImprovement) > abs($timeImprovement)) {
            $memoryEfficientExpr = $memoryImprovement > 0 ? $expr2 : $expr1;
            $output->writeln("  💚 " . $this->formatSuccess("Privilégier '{$memoryEfficientExpr}' pour l'efficacité mémoire"));
        }
        
        // Analyse de la stabilité
        $cv1 = ($this->calculateStdDev($stats1) / $stats1['avg_time']) * 100;
        $cv2 = ($this->calculateStdDev($stats2) / $stats2['avg_time']) * 100;
        
        if (abs($cv1 - $cv2) > 5) {
            $moreStable = $cv1 < $cv2 ? $expr1 : $expr2;
            $output->writeln("  📊 '{$moreStable}' est plus stable dans ses performances");
        }
    }
    
    private function calculateStdDev(array $stats): float
    {
        // Approximation basée sur les min/max pour simplifier
        return ($stats['max_time'] - $stats['min_time']) / 4;
    }
    
    private function getPerformanceService(): PHPUnitPerformanceService
    {
        if (!isset($GLOBALS['phpunit_performance_service'])) {
            $GLOBALS['phpunit_performance_service'] = new PHPUnitPerformanceService();
        }
        return $GLOBALS['phpunit_performance_service'];
    }

    public function getComplexHelp(): array
    {
        return [
            "description" => $this->getDescription(),
            "usage" => [$this->getName()],
            "examples" => []
        ];
    }}
