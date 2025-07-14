<?php

namespace Psy\Extended\Command\Runner;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
class PHPUnitRunAllCommand extends \Psy\Extended\Command\BaseCommand
{

    /**
     * Aide standard pour PsySH shell
     */
    public function getStandardHelp(): string
    {
        return "Exécute tous les tests PHPUnit de manière interactive.\n" .
               "Usage: phpunit:run-all";
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'description' => 'Exécute tous les tests dans le projet',
            'usage' => ['phpunit:run-all'],
            'examples' => [
                'phpunit:run-all' => 'Lance tous les tests de l\'ensemble du projet en une seule fois'
            ],
        ]);
    }

    public function __construct()
    {
        parent::__construct('phpunit:run-all');
    }

    protected function configure(): void
    {
        $this->setDescription('Exécuter tous les tests interactifs');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        try {
            $service = $this->phpunit();
            $activeTests = $service->getActiveTests();
            dump($activeTests);
            
            if (empty($activeTests)) {
                $output->writeln($this->formatError("❌ Aucun test interactif trouvé"));
                return 1;
            }
            
            $totalTests = count($activeTests);
            $passedTests = 0;
            $failedTests = 0;
            $totalTime = 0;
            
            $output->writeln($this->formatTest("🧪 Exécution de {$totalTests} tests interactifs :"));
            $output->writeln("");
            
            foreach ($activeTests as $testName => $test) {
                $startTime = microtime(true);
                
                $output->write("  • {$testName} ... ");
                
                try {
                    $result = $service->runTest($testName);
                    $executionTime = microtime(true) - $startTime;
                    $totalTime += $executionTime;
                    
                    if ($result['success']) {
                        $passedTests++;
                        $output->writeln($this->formatSuccess("✅ ({$this->formatTime($executionTime)})"));
                    } else {
                        $failedTests++;
                        $output->writeln($this->formatError("❌ ({$this->formatTime($executionTime)})"));
                        
                        // Afficher les erreurs pour ce test
                        foreach ($result['errors'] as $error) {
                            $output->writeln("    └─ " . $error);
                        }
                    }
                } catch (\Exception $e) {
                    $failedTests++;
                    $executionTime = microtime(true) - $startTime;
                    $totalTime += $executionTime;
                    $output->writeln($this->formatError("💥 Exception: " . $e->getMessage()));
                }
            }
            
            // Résumé final
            $output->writeln("");
            $output->writeln(str_repeat("─", 60));
            $output->writeln($this->formatInfo("📊 RÉSUMÉ D'EXÉCUTION:"));
            $output->writeln("  • Tests total: {$totalTests}");
            $output->writeln("  • Tests réussis: " . $this->formatSuccess($passedTests));
            $output->writeln("  • Tests échoués: " . $this->formatError($failedTests));
            $output->writeln("  • Temps total: " . $this->formatTime($totalTime));
            
            if ($passedTests === $totalTests) {
                $output->writeln("");
                $output->writeln($this->formatSuccess("🎉 Tous les tests sont passés!"));
            }
            
            return $failedTests === 0 ? 0 : 1;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de l'exécution des tests: " . $e->getMessage()));
            return 1;
        }
    }
    
    private function formatTime(float $seconds): string
    {
        if ($seconds < 1) {
            return number_format($seconds * 1000, 0) . "ms";
        }
        return number_format($seconds, 2) . "s";
    }
}
