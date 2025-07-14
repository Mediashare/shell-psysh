<?php

namespace Psy\Extended\Command\Runner;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Psy\Extended\Service\PHPUnitProfilingService;

class PHPUnitProfileCommand extends \Psy\Extended\Command\BaseCommand
{
    
    private PHPUnitProfilingService $profilingService;

    public function __construct()
    {
        parent::__construct('phpunit:profile');
        $this->profilingService = new PHPUnitProfilingService();
    }

    protected function configure(): void
    {
        $this
            ->setDefinition([
                new InputArgument('expression', InputArgument::OPTIONAL, 'Code expression to profile'),
            ])
            ->setDescription('Profile code execution performance')
            ->setHelp('This command profiles PHP code execution to identify performance bottlenecks.');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $expression = $input->getArgument('expression');
        
        if (!$expression) {
            $output->writeln('<comment>Usage: phpunit:profile <expression></comment>');
            $output->writeln('<info>Example: phpunit:profile "array_map(function($x) { return $x * 2; }, range(1, 1000))"</info>');
            return 0;
        }

        try {
            $result = $this->profilingService->profileExpression($expression);
            
            $output->writeln('<info>📊 Profiling Results:</info>');
            $output->writeln(sprintf('⏱️  Execution time: %s ms', $result['execution_time']));
            $output->writeln(sprintf('💾 Memory usage: %s', $result['memory_usage']));
            $output->writeln(sprintf('🔝 Peak memory: %s', $result['peak_memory']));
            
            if (!empty($result['bottlenecks'])) {
                $output->writeln('<comment>🚨 Potential bottlenecks:</comment>');
                foreach ($result['bottlenecks'] as $bottleneck) {
                    $output->writeln(sprintf('   • %s', $bottleneck));
                }
            }
            
            return 0;
        } catch (\Exception $e) {
            $output->writeln(sprintf('<error>❌ Profiling failed: %s</error>', $e->getMessage()));
            return 1;
        }
    }

    /**
     * Aide standard pour PsySH shell
     */
    public function getStandardHelp(): string
    {
        return "Profile l'exécution de code PHP pour identifier les goulots d'étranglement.\n" .
               "Usage: phpunit:profile [expression]";
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit',
            'description' => 'profile',
            'usage' => [
                'Profiler une expression'
            ],
            'examples' => [
                'Profiler une expression' => 'Utilisation de base de la commande'
            ],
            'tips' => [
                'phpunit:profile expression:Analysez les goulots d\'etranglement'
            ],
            'related' => [
                'help phpunit' => 'Aide rapide',
                'phpunit:help' => 'Aide générale PHPUnit'
            ]
        ]);
    }
}
