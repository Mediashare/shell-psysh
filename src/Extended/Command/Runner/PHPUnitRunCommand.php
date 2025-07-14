<?php

namespace Psy\Extended\Command\Runner;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;

class PHPUnitRunCommand extends \Psy\Extended\Command\BaseCommand
{
    public function __construct()
    {
        parent::__construct('phpunit:run');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Exécuter le test actuel')
            ->addArgument('test', InputArgument::OPTIONAL, 'Test à exécuter');
    }

    /**
     * Aide standard pour PsySH shell
     */
    public function getStandardHelp(): string
    {
        return "Exécute un test PHPUnit spécifique ou le test actuel.\n" .
               "Usage: phpunit:run [test_name]\n" .
               "Exemple: phpunit:run UserTest::testLogin";
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit:run',
            'description' => 'Exécute des tests PHPUnit de manière interactive avec options avancées',
            'usage' => [
                'phpunit:run [test_name]',
                'phpunit:run UserTest::testLogin',
                'phpunit:run --filter=testLogin',
                'phpunit:run tests/Unit/UserTest.php'
            ],
            'options' => [
                'test' => 'Nom du test, classe, méthode ou fichier à exécuter'
            ],
            'examples' => [
                'phpunit:run' => 'Exécute le test défini dans le contexte actuel',
                'phpunit:run UserTest' => 'Exécute tous les tests de la classe UserTest',
                'phpunit:run UserTest::testLogin' => 'Exécute uniquement la méthode testLogin',
                'phpunit:run tests/Unit/UserTest.php' => 'Exécute tous les tests du fichier spécifié',
                'phpunit:run --filter="testUser"' => 'Exécute tous les tests contenant "testUser" dans leur nom'
            ],
            'tips' => [
                'Utilisez la touche Tab pour l\'auto-complétion des noms de tests et fichiers',
                'Les résultats sont affichés en temps réel avec coloration syntaxique',
                'Les erreurs sont automatiquement capturées et formatées pour faciliter le débogage',
                'Vous pouvez interrompre l\'exécution avec Ctrl+C sans perdre les résultats déjà obtenus'
            ],
            'advanced' => [
                'Configuration automatique du chemin PHPUnit selon l\'environnement du projet',
                'Support des filtres de tests avancés avec expressions régulières',
                'Intégration avec le système de débogage pour capture automatique des erreurs',
                'Mémorisation du dernier test exécuté pour re-exécution rapide',
                'Support des groupes de tests et annotations PHPUnit'
            ],
            'workflows' => [
                'Développement TDD' => [
                    '1. Créer un nouveau test avec phpunit:create',
                    '2. Exécuter le test avec phpunit:run',
                    '3. Déboguer avec phpunit:debug si nécessaire',
                    '4. Répéter jusqu\'à validation'
                ],
                'Debug d\'erreur' => [
                    '1. Exécuter phpunit:run pour identifier l\'erreur',
                    '2. Utiliser phpunit:trace pour analyser la stack trace',
                    '3. Examiner les variables avec phpunit:debug vars',
                    '4. Corriger et re-tester'
                ]
            ],
            'troubleshooting' => [
                'Si "Test non trouvé": vérifiez l\'orthographe et que le fichier existe',
                'Si "Erreur de configuration": vérifiez phpunit.xml et autoload.php',
                'Pour plus de détails: utilisez phpunit:debug on avant d\'exécuter',
                'Si les tests sont lents: désactivez le profiling avec phpunit:debug off',
                'En cas de timeout: augmentez la limite avec ini_set("max_execution_time", 0)'
            ],
            'related' => [
                'phpunit:debug' => 'Active le mode débogage pour plus d\'informations',
                'phpunit:trace' => 'Affiche la stack trace du dernier échec',
                'phpunit:create' => 'Crée un nouveau test',
                'phpunit:list' => 'Liste tous les tests disponibles',
                'phpunit:watch' => 'Surveille les fichiers et re-exécute automatiquement'
            ]
        ]);
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $service = $this->phpunit();
        $testName = $input->getArgument('test') ?? $service->getCurrentTest()?->getTestClassName();
        
        if (!$testName) {
            $output->writeln($this->formatError('Aucun test à exécuter. Créez d\'abord un test avec phpunit:create'));
            return 1;
        }
        
        $activeTests = $service->getActiveTests();
        
        if (!isset($activeTests[$testName])) {
            $output->writeln($this->formatError("Test {$testName} non trouvé"));
            return 1;
        }
        
        $test = $activeTests[$testName];
        
        // Affichage détaillé de l'exécution
        $this->displayTestHeader($output, $test);
        $result = $this->executeTestWithDetails($output, $test);
        $this->displayTestSummary($output, $test, $result);
        
        return $result['success'] ? 0 : 1;
    }
    
    private function displayTestHeader(OutputInterface $output, $test): void
    {
        $output->writeln("\n" . str_repeat("═", 80));
        $output->writeln($this->formatTest("🧪 EXÉCUTION DU TEST: {$test->getTestName()}"));
        $output->writeln("📂 Classe: {$test->getTargetClass()}");
        $output->writeln("📄 Lignes de code: " . count($test->getCodeLines()));
        $output->writeln("🔍 Assertions: " . count($test->getAssertions()));
        $output->writeln(str_repeat("═", 80));
    }
    
    private function executeTestWithDetails(OutputInterface $output, $test): array
    {
        $startTime = microtime(true);
        $success = true;
        $errors = [];
        $passedAssertions = 0;
        $totalAssertions = count($test->getAssertions());
        $codeExecutionResults = [];
        $assertionResults = [];
        
        // Exécution du code ligne par ligne
        $output->writeln("\n🔧 EXÉCUTION DU CODE:");
        $codeLines = $test->getCodeLines();
        
        if (!empty($codeLines)) {
            foreach ($codeLines as $index => $line) {
                $lineNumber = $index + 1;
                $output->writeln("\n📝 Ligne {$lineNumber}: {$line}");
                
                try {
                    $result = $this->executePhpCode($line);
                    $codeExecutionResults[] = [
                        'line' => $line,
                        'success' => true,
                        'result' => $result
                    ];
                    
                    if ($result !== null && !is_bool($result)) {
                        $output->writeln("   ✅ Résultat: " . $this->formatValue($result));
                    } else {
                        $output->writeln("   ✅ Exécutée avec succès");
                    }
                } catch (\Throwable $e) {
                    $success = false;
                    $error = "Erreur ligne {$lineNumber}: " . $e->getMessage();
                    $errors[] = $error;
                    $codeExecutionResults[] = [
                        'line' => $line,
                        'success' => false,
                        'error' => $e->getMessage()
                    ];
                    $output->writeln("   ❌ Erreur: " . $e->getMessage());
                }
            }
        } else {
            $output->writeln("   📋 Aucun code à exécuter");
        }
        
        // Exécution des assertions
        $output->writeln("\n🔍 EXÉCUTION DES ASSERTIONS:");
        $assertions = $test->getAssertions();
        
        if (!empty($assertions)) {
            foreach ($assertions as $index => $assertion) {
                $assertionNumber = $index + 1;
                $output->writeln("\n🧮 Assertion {$assertionNumber}/{$totalAssertions}: {$assertion}");
                
                try {
                    $result = $this->executePhpUnitAssertion($assertion);
                    
                    if ($result === true) {
                        $passedAssertions++;
                        $assertionResults[] = [
                            'assertion' => $assertion,
                            'success' => true,
                            'result' => $result
                        ];
                        $output->writeln("   ✅ SUCCÈS - Assertion validée");
                    } elseif ($result === false) {
                        $success = false;
                        $error = "Assertion échouée: {$assertion}";
                        $errors[] = $error;
                        $assertionResults[] = [
                            'assertion' => $assertion,
                            'success' => false,
                            'result' => $result
                        ];
                        $output->writeln("   ❌ ÉCHEC - Assertion false");
                    } else {
                        $success = false;
                        $error = "Assertion retourne une valeur non-booléenne: " . $this->formatValue($result);
                        $errors[] = $error;
                        $assertionResults[] = [
                            'assertion' => $assertion,
                            'success' => false,
                            'result' => $result
                        ];
                        $output->writeln("   ⚠️  ERREUR - Valeur non-booléenne: " . $this->formatValue($result));
                    }
                } catch (\Throwable $e) {
                    $success = false;
                    $error = "Erreur dans l'assertion {$assertionNumber}: " . $e->getMessage();
                    $errors[] = $error;
                    $assertionResults[] = [
                        'assertion' => $assertion,
                        'success' => false,
                        'error' => $e->getMessage()
                    ];
                    $output->writeln("   💥 EXCEPTION - " . $e->getMessage());
                }
            }
        } else {
            $output->writeln("   📋 Aucune assertion à vérifier");
        }
        
        $executionTime = (microtime(true) - $startTime) * 1000; // en millisecondes
        
        return [
            'success' => $success,
            'passedAssertions' => $passedAssertions,
            'totalAssertions' => $totalAssertions,
            'errors' => $errors,
            'executionTime' => $executionTime,
            'codeResults' => $codeExecutionResults,
            'assertionResults' => $assertionResults
        ];
    }
    
    private function displayTestSummary(OutputInterface $output, $test, array $result): void
    {
        $output->writeln("\n" . str_repeat("═", 80));
        $output->writeln("📊 RÉSUMÉ D'EXÉCUTION");
        $output->writeln(str_repeat("═", 80));
        
        // Statut général
        if ($result['success']) {
            $output->writeln($this->formatSuccess("✅ TEST RÉUSSI"));
        } else {
            $output->writeln($this->formatError("❌ TEST ÉCHOUÉ"));
        }
        
        // Statistiques détaillées
        $output->writeln("\n📈 STATISTIQUES:");
        $output->writeln("   📝 Lignes de code exécutées: " . count($test->getCodeLines()));
        $output->writeln("   🧮 Assertions passées: {$result['passedAssertions']}/{$result['totalAssertions']}");
        $output->writeln("   ⏱️  Temps d'exécution: " . number_format($result['executionTime'], 2) . " ms");
        
        // Taux de réussite
        if ($result['totalAssertions'] > 0) {
            $successRate = ($result['passedAssertions'] / $result['totalAssertions']) * 100;
            $output->writeln("   📊 Taux de réussite: " . number_format($successRate, 1) . "%");
        }
        
        // Affichage des erreurs
        if (!empty($result['errors'])) {
            $output->writeln("\n💥 ERREURS DÉTECTÉES:");
            foreach ($result['errors'] as $index => $error) {
                $output->writeln("   " . ($index + 1) . ". " . $error);
            }
        }
        
        // Barre de progression visuelle
        $this->displayProgressBar($output, $result['passedAssertions'], $result['totalAssertions']);
        
        $output->writeln(str_repeat("═", 80));
    }
    
    private function displayProgressBar(OutputInterface $output, int $passed, int $total): void
    {
        if ($total === 0) {
            return;
        }
        
        $output->writeln("\n📊 PROGRESSION DES ASSERTIONS:");
        
        $barWidth = 50;
        $progress = ($passed / $total);
        $filledWidth = (int) ($progress * $barWidth);
        $emptyWidth = $barWidth - $filledWidth;
        
        $bar = "[" . str_repeat("█", $filledWidth) . str_repeat("░", $emptyWidth) . "]";
        $percentage = number_format($progress * 100, 1);
        
        if ($passed === $total) {
            $output->writeln("   ✅ {$bar} {$percentage}% ({$passed}/{$total})");
        } elseif ($passed > 0) {
            $output->writeln("   ⚠️  {$bar} {$percentage}% ({$passed}/{$total})");
        } else {
            $output->writeln("   ❌ {$bar} {$percentage}% ({$passed}/{$total})");
        }
    }
    
    /**
     * Execute a PHPUnit assertion by simulating PHPUnit methods
     */
    private function executePhpUnitAssertion(string $assertion): bool
    {
        // Remove $this-> prefix and semicolon
        $assertion = str_replace('$this->', '', $assertion);
        $assertion = rtrim($assertion, ';');
        
        // Parse the assertion method and arguments
        if (preg_match('/^(\w+)\((.*)\)$/', $assertion, $matches)) {
            $method = $matches[1];
            $argsString = $matches[2];
            
            // Parse arguments - simple implementation for common cases
            $args = $this->parseAssertionArguments($argsString);
            
            return $this->executeAssertionMethod($method, $args);
        }
        
        return false;
    }
    
    /**
     * Parse assertion arguments from string
     */
    private function parseAssertionArguments(string $argsString): array
    {
        if (empty(trim($argsString))) {
            return [];
        }
        
        $args = [];
        $parts = explode(',', $argsString);
        
        foreach ($parts as $part) {
            $part = trim($part);
            
            // Evaluate the argument in the current context
            try {
                $value = $this->executePhpCode("return {$part};");
                $args[] = $value;
            } catch (\Throwable $e) {
                // If evaluation fails, treat as string literal
                $args[] = $part;
            }
        }
        
        return $args;
    }
    
    /**
     * Execute assertion method with arguments
     */
    private function executeAssertionMethod(string $method, array $args): bool
    {
        switch ($method) {
            case 'assertTrue':
                return count($args) >= 1 && $args[0] === true;
                
            case 'assertFalse':
                return count($args) >= 1 && $args[0] === false;
                
            case 'assertSame':
                return count($args) >= 2 && $args[0] === $args[1];
                
            case 'assertEquals':
                return count($args) >= 2 && $args[0] == $args[1];
                
            case 'assertNotEquals':
                return count($args) >= 2 && $args[0] != $args[1];
                
            case 'assertNotSame':
                return count($args) >= 2 && $args[0] !== $args[1];
                
            case 'assertNull':
                return count($args) >= 1 && $args[0] === null;
                
            case 'assertNotNull':
                return count($args) >= 1 && $args[0] !== null;
                
            case 'assertEmpty':
                return count($args) >= 1 && empty($args[0]);
                
            case 'assertNotEmpty':
                return count($args) >= 1 && !empty($args[0]);
                
            case 'assertGreaterThan':
                return count($args) >= 2 && $args[1] > $args[0];
                
            case 'assertGreaterThanOrEqual':
                return count($args) >= 2 && $args[1] >= $args[0];
                
            case 'assertLessThan':
                return count($args) >= 2 && $args[1] < $args[0];
                
            case 'assertLessThanOrEqual':
                return count($args) >= 2 && $args[1] <= $args[0];
                
            case 'assertInstanceOf':
                if (count($args) >= 2) {
                    $expectedClass = $args[0];
                    $actualObject = $args[1];
                    
                    // Handle "::class" syntax
                    if (is_string($expectedClass) && str_ends_with($expectedClass, '::class')) {
                        $expectedClass = str_replace('::class', '', $expectedClass);
                    }
                    
                    return $actualObject instanceof $expectedClass;
                }
                return false;
                
            case 'assertCount':
                return count($args) >= 2 && count($args[1]) === $args[0];
                
            case 'assertStringContains':
                return count($args) >= 2 && str_contains($args[1], $args[0]);
                
            case 'assertStringNotContains':
                return count($args) >= 2 && !str_contains($args[1], $args[0]);
                
            case 'assertArrayHasKey':
                return count($args) >= 2 && array_key_exists($args[0], $args[1]);
                
            case 'assertArrayNotHasKey':
                return count($args) >= 2 && !array_key_exists($args[0], $args[1]);
                
            default:
                // Unknown assertion method
                return false;
        }
    }
    
    protected function formatValue($value): string
    {
        if (is_null($value)) {
            return 'null';
        }
        if (is_bool($value)) {
            return $value ? 'true' : 'false';
        }
        if (is_string($value)) {
            return '"' . addslashes($value) . '"';
        }
        if (is_array($value)) {
            return 'array(' . count($value) . ' éléments)';
        }
        if (is_object($value)) {
            return get_class($value) . ' object';
        }
        return (string) $value;
    }
}
