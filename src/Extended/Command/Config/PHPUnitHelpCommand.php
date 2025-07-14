<?php

namespace Psy\Extended\Command\Config;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;

class PHPUnitHelpCommand extends \Psy\Extended\Command\BaseCommand
{
    public function __construct()
    {
        parent::__construct('phpunit:help');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Obtenir de l\'aide contextuelle pour une classe')
            ->addArgument('className', InputArgument::REQUIRED, 'Nom de la classe pour laquelle obtenir l\'aide');
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit:help',
            'description' => 'Obtenir une aide contextuelle détaillée pour une classe PHP spécifique',
            'usage' => [
                'phpunit:help ClassName',
                'phpunit:help App\\Service\\UserService',
                'phpunit:help App\\Entity\\Product'
            ],
            'options' => [
                'className (requis)' => 'Nom complet de la classe (avec namespace si nécessaire)'
            ],
            'examples' => [
                'phpunit:help DateTime' => 'Affiche l\'aide pour la classe DateTime native',
                'phpunit:help App\\Service\\UserService' => 'Aide pour une classe de service Symfony',
                'phpunit:help PDO' => 'Documentation de la classe PDO avec méthodes disponibles'
            ],
            'tips' => [
                'Utilisez le nom complet avec namespace pour les classes personnalisées',
                'L\'aide inclut toutes les méthodes publiques et leur signature',
                'Les constantes et propriétés de classe sont également affichées',
                'Très utile pour découvrir l\'API d\'une classe inconnue'
            ],
            'advanced' => [
                'Détection automatique des interfaces implémentées',
                'Affichage de la hiérarchie d\'héritage de classe',
                'Extraction automatique de la documentation PHPDoc',
                'Support des traits et de leurs méthodes'
            ],
            'workflows' => [
                'Exploration d\'API' => [
                    'phpunit:help App\\Service\\ApiService',
                    'Analyser les méthodes disponibles',
                    'phpunit:create App\\Service\\ApiService',
                    'Utiliser les méthodes découvertes dans les tests'
                ]
            ],
            'troubleshooting' => [
                'Si "Classe introuvable": vérifiez le namespace et l\'autoloading',
                'Pour les classes dans vendor/: assurez-vous que Composer est chargé',
                'Respectez la casse exacte du nom de classe',
                'Utilisez des antislashs doubles (\\\\) dans le shell pour les namespaces'
            ],
            'related' => [
                'phpunit:create' => 'Créer un test pour la classe analysée',
                'ls' => 'Lister les variables et fonctions disponibles dans PsySH',
                'doc' => 'Documentation PsySH native pour les fonctions'
            ]
        ]);
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $className = $input->getArgument('className');
        
        $help = $this->getClassHelp($className);
        $output->writeln($help);
        
        return 0;
    }
}
