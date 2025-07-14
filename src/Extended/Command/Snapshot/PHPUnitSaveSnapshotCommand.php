<?php

namespace Psy\Extended\Command\Snapshot;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputOption;
use Psy\Extended\Service\PHPUnitSnapshotService;

class PHPUnitSaveSnapshotCommand extends \Psy\Extended\Command\BaseCommand
{

    public function __construct()
    {
        parent::__construct('phpunit:save-snapshot');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Sauvegarder un snapshot permanent dans un fichier')
            ->addArgument('name', InputArgument::REQUIRED, 'Nom du snapshot à sauvegarder')
            ->addOption('path', 'p', InputOption::VALUE_OPTIONAL, 'Chemin personnalisé (défaut: tests/snapshots/)', 'tests/snapshots/');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $name = $input->getArgument('name');
        $path = $input->getOption('path');
        
        // Récupérer le service snapshot
        $snapshotService = $this->snapshot();
        
        try {
            // Vérifier si le snapshot existe
            if (!$snapshotService->hasSnapshot($name)) {
                $output->writeln($this->formatError("Snapshot '{$name}' non trouvé"));
                return 1;
            }
            
            // Créer le répertoire s'il n'existe pas
            $this->createTestDirectory($path);
            
            // Sauvegarder le snapshot
            $filePath = $snapshotService->saveSnapshotToFile($name, $path);
            
            $output->writeln($this->formatSuccess("Snapshot sauvegardé dans {$filePath}"));
            
            // Afficher le contenu du fichier généré
            $fileContent = file_get_contents($filePath);
            $output->writeln($this->formatInfo("Contenu du fichier généré:"));
            $output->writeln($this->formatCode($fileContent));
            
            return 0;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de la sauvegarde: " . $e->getMessage()));
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
    
    private function formatCode(string $code): string
    {
        $lines = explode("\n", $code);
        $numberedLines = [];
        foreach ($lines as $i => $line) {
            $numberedLines[] = sprintf("%2d| %s", $i + 1, $line);
        }
        return implode("\n", $numberedLines);
    }

    public function getComplexHelp(): array
    {
        return [
            "description" => $this->getDescription(),
            "usage" => [$this->getName()],
            "examples" => []
        ];
    }}
