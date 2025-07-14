<?php

namespace Psy\Extended\Command\Config;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Psy\Extended\Trait\PHPUnitCommandTrait;

class PHPUnitCodeCommand extends \Psy\Extended\Command\BaseCommand
{
    use PHPUnitCommandTrait;

    /**
     * Aide standard pour PsySH shell
     */
    public function getStandardHelp(): string
    {
        return "CodeCommand aide à gérer les fragments de code PHPUnit.\n" .
               "Usage: phpunit:code [options]";
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'description' => 'Commande de gestion de code pour PHPUnit',
            'usage' => ['phpunit:code --generate', 'phpunit:code --list'],
            'examples' => [
                'phpunit:code --generate' => 'Génère un nouveau fragment de code PHPUnit',
                'phpunit:code --list' => 'Liste tous les fragments de code disponibles'
            ],
        ]);
    }

    public function __construct()
    {
        parent::__construct('phpunit:code');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Entrer en mode code interactif pour développer le test');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $currentTest = $this->getCurrentTest();
        
        if (!$currentTest) {
            $output->writeln($this->formatError('Aucun test actuel. Créez d\'abord un test avec phpunit:create'));
            return 1;
        }
        
        $this->setCodeMode(true);
        $output->writeln($this->formatTest("Mode code activé pour le test: {$currentTest}"));
        $output->writeln($this->formatInfo("Variables disponibles: \$em (EntityManager), \$container (Container)"));
        $output->writeln($this->formatInfo("Utilisation du shell PsySH natif avec auto-complétion et historique."));
        
        // Démarrer le mode interactif utilisant un shell PsySH natif
        $this->startInteractiveCodeMode();
        
        $this->setCodeMode(false);
        $output->writeln($this->formatSuccess("Mode code terminé."));
        
        return 0;
    }
}
