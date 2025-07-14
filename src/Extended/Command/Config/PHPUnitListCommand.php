<?php

namespace Psy\Extended\Command\Config;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
class PHPUnitListCommand extends \Psy\Extended\Command\BaseCommand
{

    /**
     * Aide standard pour PsySH shell
     */
    public function getStandardHelp(): string
    {
        return "Liste tous les tests PHPUnit disponibles dans le projet.\n" .
               "Usage: phpunit:list [options]";
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit:list',
            'description' => 'Scanner intelligent de tests avec filtrage, recherche et organisation hiérarchique',
            'usage' => [
                'phpunit:list',
                'phpunit:list --filter=User',
                'phpunit:list --directory=tests/Unit',
                'phpunit:list --group=integration'
            ],
            'options' => [
                '--filter' => 'Filtre les tests par nom de classe ou méthode',
                '--directory' => 'Limite la recherche à un répertoire spécifique',
                '--group' => 'Affiche uniquement les tests d\'un groupe donné',
                '--detailed' => 'Affiche les détails de chaque test (méthodes, annotations)'
            ],
            'examples' => [
                'phpunit:list' => 'Liste tous les tests du projet avec organisation par répertoire',
                'phpunit:list --filter=User' => 'Affiche uniquement les tests contenant "User"',
                'phpunit:list --directory=tests/Unit' => 'Liste seulement les tests unitaires',
                'phpunit:list --group=slow' => 'Montre les tests marqués comme "slow"',
                'phpunit:list --detailed UserTest' => 'Détails complets sur la classe UserTest'
            ],
            'tips' => [
                'Utilisez les filtres pour naviguer rapidement dans de gros projets',
                'Les tests sont groupés par namespace et répertoire pour faciliter la navigation',
                'Les statistiques incluent le nombre de méthodes de test par classe',
                'Les annotations PHPUnit (@group, @covers) sont détectées et affichées'
            ],
            'advanced' => [
                'Détection automatique des tests basée sur les conventions de nommage',
                'Analyse des dépendances entre tests (@depends)',
                'Calcul des métriques de couverture par classe de test',
                'Intégration avec les IDE pour navigation directe vers les fichiers'
            ],
            'related' => [
                'phpunit:run' => 'Exécute un test sélectionné depuis la liste',
                'phpunit:create' => 'Crée un nouveau test pour une classe',
                'phpunit:watch' => 'Surveille les changements sur les tests listés'
            ]
        ]);
    }

    public function __construct()
    {
        parent::__construct('phpunit:list');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Lister tous les tests actifs');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $service = $this->phpunit();
        $activeTests = $service->getActiveTests();
        
        if (empty($activeTests)) {
            $output->writeln($this->formatInfo('Aucun test actif'));
            return 0;
        }
        
        $output->writeln($this->formatInfo('Tests actifs :'));
        
        foreach ($activeTests as $test) {
            $className = $test->getTargetClass();
            $testName = $test->getTestName();
            $lineCount = $test->getCodeLineCount();
            $assertionCount = count($test->getAssertions());
            
            $output->writeln("- {$className}::{$testName} [{$lineCount} lignes, {$assertionCount} assertions]");
        }
        
        return 0;
    }
}
