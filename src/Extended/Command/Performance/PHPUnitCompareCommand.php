<?php

namespace Psy\Extended\Command\Performance;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;use Psy\Extended\Service\PHPUnitSnapshotService;

class PHPUnitCompareCommand extends \Psy\Extended\Command\BaseCommand
{

    public function __construct()
    {
        parent::__construct('phpunit:compare');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Comparer un résultat avec un snapshot existant')
            ->addArgument('name', InputArgument::REQUIRED, 'Nom du snapshot')
            ->addArgument('expression', InputArgument::REQUIRED, 'Expression à comparer (ex: $newResult)');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $name = $input->getArgument('name');
        $expression = $input->getArgument('expression');
        
        // Récupérer le service snapshot
        $snapshotService = $this->snapshot();
        
        try {
            // Vérifier si le snapshot existe
            if (!$snapshotService->hasSnapshot($name)) {
                $output->writeln($this->formatError("Snapshot '{$name}' non trouvé"));
                return 1;
            }
            
            // Exécuter l'expression et capturer le résultat
            $newResult = $this->executePhpCode("return {$expression};");
            
            if (is_string($newResult) && strpos($newResult, 'Erreur:') === 0) {
                $output->writeln($this->formatError("Impossible d'évaluer l'expression: {$newResult}"));
                return 1;
            }
            
            // Comparer avec le snapshot
            $comparison = $snapshotService->compareWithSnapshot($name, $newResult);
            
            if ($comparison['identical']) {
                $output->writeln($this->formatSuccess("✅ Résultat identique au snapshot '{$name}'"));
            } else {
                $output->writeln($this->formatError("❌ Différence détectée avec le snapshot '{$name}':"));
                $output->writeln($this->formatDifferences($comparison['differences']));
                
                // Ajouter une assertion de comparaison au test courant si disponible
                $service = $this->phpunit();
                $currentTest = $service->getCurrentTest()?->getTestClassName();
                if ($currentTest) {
                    $assertionCode = $snapshotService->getSnapshot($name)['assertion'];
                    $service->addAssertionToTest($currentTest, $assertionCode . " // Snapshot comparison");
                    $output->writeln($this->formatInfo("Assertion de comparaison ajoutée au test {$currentTest}"));
                }
            }
            
            return 0;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de la comparaison: " . $e->getMessage()));
            return 1;
        }
    }
    
    private function getSnapshotService(): PHPUnitSnapshotService
    {
        if (!isset($GLOBALS['phpunit_snapshot_service'])) {
            $GLOBALS['phpunit_snapshot_service'] = new PHPUnitSnapshotService();
        }
        return $GLOBALS['phpunit_snapshot_service'];
    }
    
    private function formatDifferences(array $differences): string
    {
        $output = "";
        foreach ($differences as $diff) {
            $output .= "- Expected: {$diff['expected']}\n";
            $output .= "+ Actual: {$diff['actual']}\n";
        }
        return $output;
    }

    public function getComplexHelp(): array
    {
        return [
            "description" => $this->getDescription(),
            "usage" => [$this->getName()],
            "examples" => []
        ];
    }}
