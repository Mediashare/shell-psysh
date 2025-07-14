<?php

namespace Psy\Extended\Command\Config;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputOption;use Psy\Extended\Service\PHPUnitProjectService;

class PHPUnitListProjectCommand extends \Psy\Extended\Command\BaseCommand
{
    

    public function __construct()
    {
        parent::__construct('phpunit:list-project');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Lister les tests du projet')
            ->addOption('path', 'p', InputOption::VALUE_OPTIONAL, 'Chemin vers les tests', 'tests')
            ->addOption('filter', 'f', InputOption::VALUE_OPTIONAL, 'Filtrer par nom de fichier')
            ->addOption('type', 't', InputOption::VALUE_OPTIONAL, 'Type de test (Unit|Integration|Functional)', null);
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $testsPath = $input->getOption('path');
        $filter = $input->getOption('filter');
        $type = $input->getOption('type');
        
        try {
            $projectService = $this->project();
            $testFiles = $projectService->scanTestFiles($testsPath, $filter, $type);
            
            if (empty($testFiles)) {
                $output->writeln($this->formatError("❌ Aucun test trouvé dans {$testsPath}"));
                return 1;
            }
            
            $output->writeln($this->formatTest("📋 Tests du projet :"));
            $output->writeln("");
            
            $totalTests = 0;
            $testsByType = [];
            
            foreach ($testFiles as $file) {
                $testCount = $file['test_count'];
                $totalTests += $testCount;
                
                $type = $file['type'];
                if (!isset($testsByType[$type])) {
                    $testsByType[$type] = 0;
                }
                $testsByType[$type] += $testCount;
                
                $output->writeln("📁 " . $file['relative_path']);
                $output->writeln("   🧪 {$testCount} test(s) • Type: {$type} • Taille: " . $this->formatFileSize($file['size']));
                
                if (!empty($file['test_methods'])) {
                    foreach ($file['test_methods'] as $method) {
                        $output->writeln("     • {$method}");
                    }
                }
                $output->writeln("");
            }
            
            // Résumé
            $this->displaySummary($output, $totalTests, $testsByType, count($testFiles));
            
            return 0;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de la lecture des tests: " . $e->getMessage()));
            return 1;
        }
    }
    
    private function displaySummary(OutputInterface $output, int $totalTests, array $testsByType, int $fileCount): void
    {
        $output->writeln(str_repeat("─", 60));
        $output->writeln($this->formatInfo("📊 Résumé :"));
        $output->writeln("• Fichiers de test : {$fileCount}");
        $output->writeln("• Tests total : {$totalTests}");
        
        if (!empty($testsByType)) {
            $output->writeln("• Répartition par type :");
            foreach ($testsByType as $type => $count) {
                $percentage = round(($count / $totalTests) * 100, 1);
                $output->writeln("  - {$type} : {$count} ({$percentage}%)");
            }
        }
    }
    
    
    private function getProjectService(): PHPUnitProjectService
    {
        if (!isset($GLOBALS['phpunit_project_service'])) {
            $GLOBALS['phpunit_project_service'] = new PHPUnitProjectService();
        }
        return $GLOBALS['phpunit_project_service'];
    }

    public function getComplexHelp(): array
    {
        return [
            "description" => $this->getDescription(),
            "usage" => [$this->getName()],
            "examples" => []
        ];
    }}
