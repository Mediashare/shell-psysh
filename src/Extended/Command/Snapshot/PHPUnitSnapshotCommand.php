<?php

namespace Psy\Extended\Command\Snapshot;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputOption;
use Psy\Extended\Service\PHPUnitSnapshotService;

class PHPUnitSnapshotCommand extends \Psy\Extended\Command\BaseCommand
{

    public function __construct()
    {
        parent::__construct('phpunit:snapshot');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Créer un snapshot du résultat d\'une expression')
            ->addArgument('expression', InputArgument::REQUIRED, 'Expression à capturer (ex: $result)')
            ->addArgument('name', InputArgument::OPTIONAL, 'Nom du snapshot')
            ->addOption('name', null, InputOption::VALUE_OPTIONAL, 'Nom du snapshot (alternative à l\'argument)')
            ->addOption('desc', null, InputOption::VALUE_OPTIONAL, 'Description du snapshot');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $expression = $input->getArgument('expression');
        
        // Gérer le nom (priorité: option --name > argument name > auto-généré)
        $nameOption = $input->getOption('name');
        $nameArg = $input->getArgument('name');
        
        // Si aucun nom n'est fourni, utiliser un nom séquentiel
        if (!$nameOption && !$nameArg) {
            $name = $this->generateSequentialSnapshotName();
        } else {
            $name = $nameOption ?: $nameArg;
        }
        
        $description = $input->getOption('desc');
        
        try {
            // Préparer le contexte avec les variables existantes
            $contextVars = $this->getContext()->getAll();
            
            // Exécuter l'expression avec le contexte des variables
            $result = $this->executePhpCodeWithContext("return {$expression};", $contextVars);
            
            if (is_string($result) && strpos($result, 'Erreur:') === 0) {
                $output->writeln($this->formatError("Impossible d'évaluer l'expression: {$result}"));
                return 1;
            }
            
            // Stocker le snapshot dans le contexte du shell
            $this->setContextVariable($name, $result);
            
            // Créer le snapshot avec le service ou fallback
            $snapshot = $this->createSnapshotData($name, $result);
            
            // Afficher le résultat
            $output->writeln("📸 Snapshot créé : {$name}");
            $output->writeln("$" . $name);
            
            // Afficher la description si fournie
            if ($description) {
                $output->writeln($this->formatInfo($description));
            }
            
            $output->writeln($this->formatTestCode($snapshot['assertion']));
            
            // Ajouter l'assertion au test courant si disponible
            try {
                $service = $this->phpunit();
                $currentTest = $service->getCurrentTest()?->getTestClassName();
                if ($currentTest) {
                    $service->addAssertionToTest($currentTest, $snapshot['assertion']);
                    $output->writeln($this->formatInfo("Assertion ajoutée au test {$currentTest}"));
                }
            } catch (\Exception $e) {
                // Service not available, that's okay for tests
            }
            
            return 0;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de la création du snapshot: " . $e->getMessage()));
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
    
    /**
     * Génère un nom séquentiel pour le snapshot
     */
    private function generateSequentialSnapshotName(): string
    {
        // Chercher les snapshots existants pour déterminer le prochain numéro
        $context = $this->getContext();
        $vars = $context->getAll();
        $count = 1;
        
        while (isset($vars["snapshot_{$count}"])) {
            $count++;
        }
        
        return "snapshot_{$count}";
    }
    
    /**
     * Génère un nom pour le snapshot basé sur l'expression
     */
    private function generateSnapshotName(string $expression): string
    {
        // Simplifier l'expression pour en faire un nom valide
        $name = preg_replace('/[^a-zA-Z0-9_]/', '_', $expression);
        $name = preg_replace('/_+/', '_', $name);
        $name = trim($name, '_');
        
        // Limiter la longueur
        if (strlen($name) > 30) {
            $name = substr($name, 0, 30);
        }
        
        // Ajouter un suffix unique si nécessaire
        return 'snapshot_' . $name . '_' . time();
    }
    
    /**
     * Créer les données de snapshot avec ou sans service
     */
    private function createSnapshotData(string $name, $result): array
    {
        try {
            // Essayer d'utiliser le service s'il est disponible
            $snapshotService = $this->snapshot();
            return $snapshotService->createSnapshot($name, $result);
        } catch (\Exception $e) {
            // Fallback: créer les données directement
            return $this->createSnapshotDataFallback($name, $result);
        }
    }
    
    /**
     * Créer les données de snapshot sans service (fallback)
     */
    private function createSnapshotDataFallback(string $name, $result): array
    {
        return [
            'name' => $name,
            'data' => $result,
            'created_at' => date('Y-m-d H:i:s'),
            'assertion' => $this->generateAssertion($result)
        ];
    }
    
    /**
     * Générer une assertion PHPUnit
     */
    private function generateAssertion($data): string
    {
        if (is_array($data)) {
            return '$this->assertEquals(' . var_export($data, true) . ', $actualResult);';
        } elseif (is_object($data)) {
            return '$this->assertInstanceOf(' . get_class($data) . '::class, $actualResult);';
        } elseif (is_bool($data)) {
            return '$this->assert' . ($data ? 'True' : 'False') . '($actualResult);';
        } elseif (is_null($data)) {
            return '$this->assertNull($actualResult);';
        } elseif (is_string($data)) {
            return '$this->assertEquals(' . var_export($data, true) . ', $actualResult);';
        } elseif (is_numeric($data)) {
            return '$this->assertEquals(' . $data . ', $actualResult);';
        } else {
            return '$this->assertEquals(' . var_export($data, true) . ', $actualResult);';
        }
    }
    
    /**
     * Aide complexe pour commande help dédiée
     */
    protected function getRequiredArguments(): array
    {
        return ['expression'];
    }
    
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit:snapshot',
            'description' => 'Système de capture et validation de résultats pour tests PHPUnit',
            'usage' => [
                'phpunit:snapshot [expression] [name]',
                'phpunit:snapshot $result',
                'phpunit:snapshot $user->toArray() userSnapshot',
                'phpunit:snapshot $api->getResponse() --name=apiResponse'
            ],
            'options' => [
                'expression' => 'Expression PHP à capturer',
                'name' => 'Nom du snapshot (optionnel, auto-généré si omis)',
                '--name' => 'Alternative pour spécifier le nom',
                '--desc' => 'Description du snapshot'
            ],
            'examples' => [
                'phpunit:snapshot $result' => 'Capture avec nom auto-généré',
                'phpunit:snapshot $data myData' => 'Capture avec nom spécifique',
                'phpunit:snapshot $response --name=apiCall' => 'Utilise l\'option --name',
                'phpunit:snapshot $obj --desc="User object state"' => 'Ajoute une description',
                'phpunit:snapshot $api->getResponse() apiResponse' => 'Capture une réponse API',
                'phpunit:snapshot array_map(\'strtoupper\', [\'a\', \'b\'])' => 'Capture le résultat d\'array_map'
            ],
            'tips' => [
                'Les snapshots capturent l\'état complet des objets et tableaux',
                'Utilisez des noms descriptifs pour faciliter la maintenance',
                'Les assertions générées peuvent être copiées dans vos tests',
                'Les snapshots sont automatiquement ajoutés au test courant'
            ],
            'related' => [
                'phpunit:assert' => 'Crée des assertions simples',
                'phpunit:create' => 'Génère un test complet',
                'phpunit:mock' => 'Crée des mocks pour les tests'
            ]
        ]);
    }
}
