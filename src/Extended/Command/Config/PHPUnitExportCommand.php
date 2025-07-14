<?php

namespace Psy\Extended\Command\Config;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;

class PHPUnitExportCommand extends \Psy\Extended\Command\BaseCommand
{

    public function __construct()
    {
        parent::__construct('phpunit:export');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Exporter un test vers un fichier')
            ->addArgument('testName', InputArgument::REQUIRED, 'Nom du test à exporter')
            ->addArgument('path', InputArgument::OPTIONAL, 'Chemin du fichier (optionnel)', null);
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit:export',
            'description' => 'Exporter le test actuel vers un fichier',
            'usage' => [
                'phpunit:export TestClassName',
                'phpunit:export MyTest --path=/path/to/dir'
            ],
            'examples' => [
                'phpunit:export CalculatorTest' => 'Exporte CalculatorTest vers un fichier',
                'phpunit:export ApiTest --path=tests/Api/' => 'Exporte ApiTest vers le répertoire spécifié'
            ],
            'tips' => [
                'Le chemin par défaut est tests/Generated/',
                'Assurez-vous que le répertoire est accessible en écriture',
                'Utilisez des noms de fichiers explicites pour éviter les conflits'
            ],
            'troubleshooting' => [
                'Vérifier l\'existence du test dans les tests actifs',
                'Le répertoire de destination doit être accessible en écriture',
                'Vérifier les permissions sur le répertoire de sortie'
            ],
            'related' => [
                'phpunit:list' => 'Lister les tests actifs disponibles pour exportation',
                'phpunit:create' => 'Créer un nouveau test pour développer du code'
            ]
        ]);
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $testName = $input->getArgument('testName');
        $path = $input->getArgument('path');
        
        $service = $this->phpunit();
        $activeTests = $service->getActiveTests();
        
        if (!isset($activeTests[$testName])) {
            $output->writeln($this->formatError("Test {$testName} non trouvé"));
            return 1;
        }
        
        // Générer le chemin par défaut si non spécifié
        if (!$path) {
            $path = "tests/Generated/{$testName}.php";
        }
        
        // Créer le répertoire si nécessaire
        $directory = dirname($path);
        $this->createTestDirectory($directory);
        
        // Exporter le test
        $success = $service->exportTest($testName, $path);
        
        if ($success) {
            $output->writeln($this->formatSuccess("Test exporté vers {$path}"));
        } else {
            $output->writeln($this->formatError("Erreur lors de l'exportation"));
        }
        
        return $success ? 0 : 1;
    }
}
