<?php

namespace Psy\Extended\Command\Config;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Psy\Extended\Trait\PHPUnitCommandTrait;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;

class PHPUnitCreateCommand extends \Psy\Extended\Command\BaseCommand
{
    use PHPUnitCommandTrait;

    public function __construct()
    {
        parent::__construct('phpunit:create');
    }

    /**
     * Aide standard pour PsySH shell
     */
    public function getStandardHelp(): string
    {
        return "Crée un nouveau test PHPUnit pour un service spécifié.\n" .
               "Usage: phpunit:create [service]";
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit:create',
            'description' => 'Générateur intelligent de tests PHPUnit pour services et classes avec auto-détection des dépendances',
            'usage' => [
                'phpunit:create [service_class]',
                'phpunit:create App\\Service\\UserService',
                'phpunit:create My\\Domain\\Calculator'
            ],
            'options' => [
                'service' => 'Nom complet de la classe ou service à tester (avec namespace)'
            ],
            'examples' => [
                'phpunit:create App\\Service\\UserService' => 'Crée UserServiceTest avec méthodes de base et setup',
                'phpunit:create App\\Repository\\ProductRepository' => 'Génère un test de repository avec mocks de base de données',
                'phpunit:create App\\Controller\\ApiController' => 'Crée un test de contrôleur avec mocks de requêtes',
                'phpunit:create My\\Util\\Calculator' => 'Génère un test simple pour une classe utilitaire'
            ],
            'tips' => [
                'Vérifiez que le namespace correspond exactement à votre structure de projet',
                'La classe doit être autoloadée correctement via composer',
                'Utilisez des noms de classe complets avec namespace pour éviter les ambiguités',
                'Le test généré inclut automatiquement les mocks des dépendances détectées'
            ],
            'advanced' => [
                'Détection automatique des dépendances via le constructeur',
                'Génération de mocks pour les services injectés',
                'Template personnalisable selon le type de classe (Service, Repository, Controller)',
                'Intégration avec les conteneurs de dépendances (Symfony, Laravel)',
                'Support des annotations et attributs PHP 8 pour la génération'
            ],
            'workflows' => [
                'Création TDD' => [
                    '1. phpunit:create YourService pour générer le squelette',
                    '2. Écrire les cas de test dans le fichier généré',
                    '3. phpunit:run YourServiceTest pour valider',
                    '4. Implémenter la logique jusqu\'à validation des tests'
                ],
                'Test de service existant' => [
                    '1. Analyser les dépendances avec phpunit:create ServiceName',
                    '2. Personnaliser les mocks générés si nécessaire',
                    '3. Ajouter des cas de test spécifiques avec phpunit:assert',
                    '4. Exécuter et raffiner les tests'
                ]
            ],
            'troubleshooting' => [
                'Si "Classe non trouvée": vérifiez l\'autoload et le namespace dans composer.json',
                'Si "Erreur de génération": vérifiez les permissions d\'écriture dans tests/',
                'Si "Dépendances non détectées": assurez-vous que les types sont déclarés dans le constructeur',
                'Pour debug: activez le mode verbose avec phpunit:debug on'
            ],
            'related' => [
                'phpunit:mock' => 'Crée des mocks personnalisés pour les dépendances',
                'phpunit:run' => 'Exécute le test nouvellement créé',
                'phpunit:assert' => 'Ajoute des assertions au test généré',
                'phpunit:list' => 'Liste tous les tests disponibles'
            ]
        ]);
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Création d\'un nouveau test PHPUnit de manière interactive')
            ->addArgument('service', InputArgument::REQUIRED, 'Le service pour lequel créer le test.');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $serviceClass = $input->getArgument('service');
        $className = $this->extractClassName($serviceClass);
        
        // S'assurer que le nom de classe commence par une majuscule
        $className = ucfirst($className);
        
        $service = $this->phpunit();
        $test = $service->createTest($className);
        
        // Définir la classe cible avec le namespace complet
        if ($test && method_exists($test, 'setTargetClass')) {
            // Si c'est un nom de classe simple (pas de namespace), capitaliser
            $targetClass = strpos($serviceClass, '\\') === false ? ucfirst($serviceClass) : $serviceClass;
            $test->setTargetClass($targetClass);
        }
        
        $this->setCurrentTest($className);
        
        $output->writeln($this->formatSuccess("Test créé : {$className}Test (mode interactif)"));
        
        return 0;
    }
}

