<?php

namespace Psy\Extended\Command\Runner;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputOption;use Psy\Extended\Service\PHPUnitConfigService;

class PHPUnitRunProjectCommand extends \Psy\Extended\Command\BaseCommand
{

    /**
     * Aide standard pour PsySH shell
     */
    public function getStandardHelp(): string
    {
        return "Exécute des tests PHPUnit pour un projet spécifique.\n" .
               "Usage: phpunit:run-project [projectName]";
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'description' => 'Exécute les tests pour un projet donné',
            'usage' => ['phpunit:run-project myProject'],
            'examples' => [
                'phpunit:run-project myProject' => 'Exécute les tests pour projet nommé myProject'
            ],
        ]);
    }

    public function __construct()
    {
        parent::__construct('phpunit:run-project');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Exécuter les tests du projet avec PHPUnit')
            ->addOption('coverage', null, InputOption::VALUE_NONE, 'Générer le rapport de coverage')
            ->addOption('filter', null, InputOption::VALUE_OPTIONAL, 'Filtrer les tests à exécuter')
            ->addOption('testsuite', null, InputOption::VALUE_OPTIONAL, 'Test suite spécifique à exécuter');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        try {
            $configService = $this->config();
            $command = $this->buildPhpUnitCommand($input, $configService);
            
            $output->writeln($this->formatTest("🧪 Exécution des tests du projet :"));
            $output->writeln($this->formatInfo("Commande: {$command}"));
            $output->writeln("");
            
            // Exécuter PHPUnit
            $startTime = microtime(true);
            $exitCode = $this->executeShellCommand($command, $output);
            $executionTime = microtime(true) - $startTime;
            
            // Analyser les résultats
            $this->displayTestSummary($output, $exitCode, $executionTime);
            
            return $exitCode;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de l'exécution: " . $e->getMessage()));
            return 1;
        }
    }
    
    private function buildPhpUnitCommand(InputInterface $input, PHPUnitConfigService $configService): string
    {
        $config = $configService->getCurrentConfig();
        $command = 'vendor/bin/phpunit';
        
        // Configuration file
        if (!empty($config['config_file'])) {
            $command .= ' --configuration=' . escapeshellarg($config['config_file']);
        }
        
        // Test suite
        $testsuite = $input->getOption('testsuite') ?: $config['testsuite'];
        if ($testsuite) {
            $command .= ' --testsuite=' . escapeshellarg($testsuite);
        }
        
        // Coverage
        if ($input->getOption('coverage') || $config['coverage']['enabled']) {
            $coverageType = $config['coverage']['type'] ?: 'html';
            $coverageDir = $config['coverage']['dir'] ?: 'var/coverage';
            
            switch ($coverageType) {
                case 'html':
                    $command .= ' --coverage-html=' . escapeshellarg($coverageDir);
                    break;
                case 'text':
                    $command .= ' --coverage-text';
                    break;
                case 'clover':
                    $command .= ' --coverage-clover=' . escapeshellarg($coverageDir . '/clover.xml');
                    break;
            }
        }
        
        // Filter
        if ($filter = $input->getOption('filter')) {
            $command .= ' --filter=' . escapeshellarg($filter);
        }
        
        // Bootstrap
        if (!empty($config['bootstrap'])) {
            $command .= ' --bootstrap=' . escapeshellarg($config['bootstrap']);
        }
        
        // Output format
        $command .= ' --verbose';
        
        return $command;
    }
    
    private function executeShellCommand(string $command, OutputInterface $output): int
    {
        // Rediriger la sortie vers la console
        $descriptorSpec = [
            0 => ["pipe", "r"],  // stdin
            1 => ["pipe", "w"],  // stdout
            2 => ["pipe", "w"]   // stderr
        ];
        
        $process = proc_open($command, $descriptorSpec, $pipes, getcwd());
        
        if (!is_resource($process)) {
            throw new \RuntimeException("Impossible d'exécuter la commande PHPUnit");
        }
        
        // Fermer stdin
        fclose($pipes[0]);
        
        // Lire stdout et stderr en temps réel
        stream_set_blocking($pipes[1], false);
        stream_set_blocking($pipes[2], false);
        
        while (true) {
            $stdout = fgets($pipes[1]);
            $stderr = fgets($pipes[2]);
            
            if ($stdout !== false) {
                $output->write($stdout);
            }
            
            if ($stderr !== false) {
                $output->write($this->formatError($stderr));
            }
            
            // Vérifier si le processus est toujours en cours
            $status = proc_get_status($process);
            if (!$status['running']) {
                // Lire les dernières données
                while (!feof($pipes[1])) {
                    $output->write(fgets($pipes[1]));
                }
                while (!feof($pipes[2])) {
                    $output->write($this->formatError(fgets($pipes[2])));
                }
                break;
            }
            
            usleep(10000); // 10ms
        }
        
        fclose($pipes[1]);
        fclose($pipes[2]);
        
        $exitCode = proc_close($process);
        return $exitCode;
    }
    
    private function displayTestSummary(OutputInterface $output, int $exitCode, float $executionTime): void
    {
        $output->writeln("");
        $output->writeln(str_repeat("═", 60));
        
        if ($exitCode === 0) {
            $output->writeln($this->formatSuccess("✅ Tests du projet réussis"));
        } else {
            $output->writeln($this->formatError("❌ Tests du projet échoués"));
        }
        
        $output->writeln($this->formatInfo("⏱️  Temps d'exécution: " . number_format($executionTime, 2) . "s"));
        $output->writeln($this->formatInfo("📊 Code de sortie: {$exitCode}"));
        
        $output->writeln(str_repeat("═", 60));
    }
    
    protected function getConfigService(): PHPUnitConfigService
    {
        if (!isset($GLOBALS['phpunit_config_service'])) {
            $GLOBALS['phpunit_config_service'] = new PHPUnitConfigService();
        }
        return $GLOBALS['phpunit_config_service'];
    }
}
