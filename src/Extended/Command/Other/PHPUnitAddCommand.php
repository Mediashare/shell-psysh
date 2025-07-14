<?php

namespace Psy\Extended\Command\Other;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;

class PHPUnitAddCommand extends \Psy\Extended\Command\BaseCommand
{

    public function __construct()
    {
        parent::__construct('phpunit:add');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Ajouter une méthode de test au test actuel')
            ->addArgument('method', InputArgument::REQUIRED, 'Nom de la méthode à ajouter');
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit:add',
            'description' => 'Ajouter une méthode de test au test actuel en cours de développement',
            'usage' => [
                'phpunit:add testMethodName',
                'phpunit:add testCalculateTotal',
                'phpunit:add testValidateInput'
            ],
            'options' => [
                'method (requis)' => 'Nom de la méthode de test à ajouter (doit commencer par "test")'
            ],
            'examples' => [
                'phpunit:add testCreateUser' => 'Ajoute une méthode testCreateUser() au test actuel',
                'phpunit:add testValidateEmail' => 'Ajoute une méthode testValidateEmail() au test actuel',
                'phpunit:add testCalculateDiscount' => 'Ajoute une méthode pour tester le calcul de remise'
            ],
            'tips' => [
                'Le nom de méthode doit commencer par "test" pour être reconnu par PHPUnit',
                'Utilisez des noms descriptifs qui expliquent ce qui est testé',
                'Après avoir ajouté une méthode, utilisez "phpunit:code" pour la développer',
                'Une méthode de test = un comportement spécifique à tester'
            ],
            'workflows' => [
                'Développement TDD' => [
                    'phpunit:create ServiceClass',
                    'phpunit:add testFirstBehavior',
                    'phpunit:code (développer le test)',
                    'phpunit:run (vérifier échec)',
                    'Implémenter le code',
                    'phpunit:run (vérifier succès)'
                ]
            ],
            'troubleshooting' => [
                'Si "Aucun test actuel": utilisez d\'abord "phpunit:create"',
                'Si le nom ne commence pas par "test": PHPUnit ne reconnaîtra pas la méthode',
                'Les méthodes sont ajoutées en mémoire, utilisez "phpunit:export" pour sauvegarder'
            ],
            'related' => [
                'phpunit:create' => 'Créer un nouveau test',
                'phpunit:code' => 'Développer le code de test',
                'phpunit:run' => 'Exécuter le test',
                'phpunit:export' => 'Exporter vers un fichier'
            ]
        ]);
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $methodName = $input->getArgument('method');
        $currentTest = $this->getCurrentTest();
        
        if (!$currentTest) {
            $output->writeln($this->formatError('Aucun test actuel. Créez d\'abord un test avec phpunit:create'));
            return 1;
        }
        
        $service = $this->phpunit();
        $service->addMethodToTest($currentTest, $methodName);
        
        $output->writeln($this->formatSuccess("Méthode {$methodName} ajoutée"));
        
        return 0;
    }
}
