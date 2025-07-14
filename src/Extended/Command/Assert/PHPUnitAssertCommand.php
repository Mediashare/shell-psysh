<?php

namespace Psy\Extended\Command\Assert;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Psy\Extended\Trait\PHPUnitCommandTrait;
use Psy\Extended\Trait\RawExpressionTrait;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputOption;

class PHPUnitAssertCommand extends \Psy\Extended\Command\BaseCommand
{
    use PHPUnitCommandTrait;
    use RawExpressionTrait;

    private ?bool $debug = false;

    public function __construct()
    {
        parent::__construct('phpunit:assert');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Exécuter une assertion PHPUnit avec message personnalisé')
            ->addArgument('expression', InputArgument::REQUIRED, 'Expression à tester (ex: $invoice->getTotal() == 100)')
            ->addOption('message', 'm', InputOption::VALUE_OPTIONAL, 'Message personnalisé en cas d\'échec')
            ->addOption('method', null, InputOption::VALUE_OPTIONAL, 'Méthode de test spécifique où ajouter l\'assertion')
            ->addOption('setup', null, InputOption::VALUE_OPTIONAL, 'Code de configuration à exécuter avant l\'assertion')
            ->addOption('debug', 'd', InputOption::VALUE_NONE, 'Activer le mode debug pour la synchronisation');
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit:assert',
            'description' => 'Système d\'assertions PHPUnit interactif avec validation en temps réel',
            'usage' => [
                'phpunit:assert [type] [value1] [value2]',
                'phpunit:assert equals $actual $expected',
                'phpunit:assert contains $array $needle',
                'phpunit:assert true $condition'
            ],
            'options' => [
                'type' => 'Type d\'assertion (equals, contains, true, false, null, empty, etc.)',
                'value1' => 'Valeur actuelle à tester',
                'value2' => 'Valeur attendue (selon le type d\'assertion)'
            ],
            'examples' => [
                'phpunit:assert equals $user->getName() "John"' => 'Vérifie que le nom de l\'utilisateur est "John"',
                'phpunit:assert true $user->isActive()' => 'Vérifie que l\'utilisateur est actif',
                'phpunit:assert contains $permissions "read"' => 'Vérifie que "read" est dans les permissions',
                'phpunit:assert empty $errors' => 'Vérifie que le tableau d\'erreurs est vide',
                'phpunit:assert instance $obj User' => 'Vérifie que $obj est une instance de User',
                'phpunit:assert count $array 5' => 'Vérifie que le tableau contient 5 éléments',
                'phpunit:assert json $response' => 'Vérifie que la réponse est un JSON valide'
            ],
            'tips' => [
                'Utilisez les variables PsySH directement dans les assertions',
                'Les assertions sont exécutées immédiatement avec retour visuel',
                'Messages d\'erreur détaillés avec comparaison visuelle des valeurs',
                'Auto-complétion disponible pour tous les types d\'assertions',
                'Historique des assertions pour ré-exécution rapide'
            ],
            'advanced' => [
                'Assertions personnalisées avec lambda functions',
                'Comparaison profonde d\'objets et tableaux complexes',
                'Génération automatique de cas de test à partir des assertions',
                'Intégration avec le débogueur pour analyse des échecs',
                'Support des assertions floues pour tests de performance'
            ],
            'workflows' => [
                'Test rapide de valeur' => [
                    '1. Définir une variable: $result = myFunction()',
                    '2. Tester avec assertion: phpunit:assert equals $result expectedValue',
                    '3. Analyser le résultat et ajuster si nécessaire'
                ],
                'Validation d\'objet complexe' => [
                    '1. phpunit:assert instance $obj ExpectedClass',
                    '2. phpunit:assert true $obj->isValid()',
                    '3. phpunit:assert equals $obj->getProperty() expectedValue',
                    '4. phpunit:assert contains $obj->getArray() expectedItem'
                ]
            ],
            'troubleshooting' => [
                'Si assertion échoue: utilisez phpunit:debug vars pour voir les valeurs',
                'Pour objets complexes: utilisez var_dump() avant l\'assertion',
                'En cas d\'erreur de type: vérifiez que les variables sont définies',
                'Pour débogage avancé: activez le mode verbose avec phpunit:debug on'
            ],
            'related' => [
                'phpunit:debug' => 'Débogue les assertions échouées',
                'phpunit:mock' => 'Crée des mocks pour les tests',
                'phpunit:create' => 'Génère un test complet avec assertions',
                'phpunit:explain' => 'Explique pourquoi une assertion a échoué'
            ]
        ]);
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        // Utiliser l'expression brute capturée
        $expression = $this->getRawExpression();
        if (empty($expression)) {
            // Fallback sur l'argument classique
            $expression = $input->getArgument('expression');
        }
        $customMessage = $input->getOption('message');
        $methodName = $input->getOption('method');
        $setupCode = $input->getOption('setup');
        
        // Activer le mode debug si demandé
        $this->debug = $input->getOption('debug');
        if ($this->debug) {
            $unifiedSync = $GLOBALS['psysh_unified_sync_service'] ?? null;
            if ($unifiedSync && $unifiedSync instanceof \Psy\Extended\Service\UnifiedSyncService) {
                $unifiedSync->setDebug(true);
                $output->writeln($this->formatInfo("Mode debug activé pour la synchronisation"));
            }
            
            // Vérifier le test courant
            $service = $this->phpunit();
            $currentTest = $service->getCurrentTest()?->getTestClassName();
            if ($currentTest) {
                $this->displayDebugInfo($expression, $currentTest);
            }
        }
        
        try {
            // Préparer les variables du contexte
            $variables = [];
            if ($this->context) {
                $variables = $this->context->getAll();
            }
            
            // IMPORTANT: Synchroniser le contexte avec les variables globales dès le début
            // pour que toutes les exécutions utilisent le bon contexte
            $oldVars = $GLOBALS['psysh_shell_variables'] ?? [];
            $GLOBALS['psysh_shell_variables'] = $variables;
            
            // Exécuter le code de setup si fourni
            if ($setupCode) {
                // S'assurer que le code de setup se termine par ;
                if (!str_ends_with(trim($setupCode), ';')) {
                    $setupCode .= ';';
                }
                
                $setupResult = $this->executePhpCodeWithContext($setupCode, $variables);
                if (is_string($setupResult) && strpos($setupResult, 'Erreur:') === 0) {
                    $output->writeln($this->formatError("Erreur dans le setup: {$setupResult}"));
                    return 1;
                }
                // Les variables sont mises à jour par référence dans executePhpCodeWithContext
                // IMPORTANT: Mettre à jour aussi les variables globales pour que l'assertion puisse y accéder
                $GLOBALS['psysh_shell_variables'] = $variables;
            }
            
            // Pour les expressions multilignes, on doit traiter différemment
            // Si l'expression contient des ; suivis d'autres caractères, c'est multilignes
            if (preg_match('/;\s*\S/', $expression)) {
                // Pour les expressions multilignes, créer un code complet qui retourne la dernière expression
                // Diviser l'expression en parties
                $parts = explode(';', $expression);
                $parts = array_map('trim', $parts);
                $parts = array_filter($parts); // Retirer les parties vides
                
                if (count($parts) > 1) {
                    // La dernière partie est l'assertion à évaluer
                    $assertionPart = array_pop($parts);
                    // Les autres parties sont le setup
                    $setupPart = implode('; ', $parts) . ';';
                    
                    // Créer un code qui exécute le setup puis retourne l'assertion
                    $fullCode = $setupPart . ' return (' . $assertionPart . ');';
                } else {
                    $fullCode = 'return (' . $expression . ');';
                }
                
                $result = $this->executePhpCodeWithContext($fullCode, $variables);
            } else {
                $result = $this->executePhpCodeWithContext("return ({$expression});", $variables);
            }
            
            // Restaurer les anciennes variables
            $GLOBALS['psysh_shell_variables'] = $oldVars;
            
            if (is_string($result) && strpos($result, 'Erreur:') === 0) {
                $output->writeln($this->formatError("Erreur dans l'expression: {$result}"));
                return 1;
            }
            
            // Analyser le résultat
            $success = (bool) $result;
            
            if ($success) {
                $output->writeln($this->formatSuccess("Assertion réussie"));
                
                // Ajouter l'assertion au test courant pour persistence
                $this->addAssertionToCurrentTest($expression, $customMessage);
                
                if ($methodName) {
                    $output->writeln($this->formatInfo("Assertion ajoutée au test {$methodName}"));
                }
            } else {
                $errorMessage = $customMessage ? $customMessage : "Assertion échouée";
                $output->writeln($this->formatError("❌ {$errorMessage}"));
                
                // Essayer d'analyser l'expression pour donner plus de détails
                $details = $this->analyzeFailedExpression($expression);
                if ($details) {
                    $output->writeln($details);
                }
            }
            
            return $success ? 0 : 1;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de l'assertion: " . $e->getMessage()));
            return 1;
        }
    }
    
    private function generateAssertionCode(string $expression, ?string $message): string
    {
        $messageCode = $message ? ", '{$message}'" : '';
        return "({$expression});";
    }
    
    /**
     * Exécute du code PHP avec le contexte des variables de la commande
     */
    private function executeWithContext(string $code): mixed
    {
        // Utiliser directement executePhpCode qui va chercher les variables dans les globals
        // qui ont été mises à jour après le setup
        return $this->executePhpCode($code);
    }
    private function analyzeFailedExpression(string $expression): ?string
    {
        // Analyser les expressions de comparaison communes - regex améliorée
        if (preg_match('/^(.+?)\s*(===|!==|==|!=|<=|>=|<|>)\s*(.+)$/', $expression, $matches)) {
            $left = trim($matches[1]);
            $operator = trim($matches[2]);
            $right = trim($matches[3]);
            
            try {
                // Exécuter les deux côtés de l'expression séparément avec le contexte
                $leftResult = $this->executeWithContext("return {$left};");
                $rightResult = $this->executeWithContext("return {$right};");
                
                // Vérifier s'il y a des erreurs dans l'exécution
                if (is_string($leftResult) && strpos($leftResult, 'Erreur:') === 0) {
                    return "Erreur dans l'évaluation de '{$left}': {$leftResult}";
                }
                if (is_string($rightResult) && strpos($rightResult, 'Erreur:') === 0) {
                    return "Erreur dans l'évaluation de '{$right}': {$rightResult}";
                }
                
                return sprintf(
                    "Expected: %s %s %s\nActual: %s = %s",
                    $left,
                    $operator,
                    $this->formatValue($rightResult),
                    $left,
                    $this->formatValue($leftResult)
                );
            } catch (\Exception $e) {
                return "Erreur lors de l'analyse: " . $e->getMessage();
            }
        }
        
        // Fallback simple - juste montrer que l'assertion a échoué
        return "Assertion échouée pour l'expression: {$expression}";
    }
    
    private function getActualOperator($leftValue, $rightValue, string $expectedOperator): string
    {
        switch ($expectedOperator) {
            case '==':
                return $leftValue == $rightValue ? '==' : '!=';
            case '===':
                return $leftValue === $rightValue ? '===' : '!==';
            case '!=':
                return $leftValue != $rightValue ? '!=' : '==';
            case '!==':
                return $leftValue !== $rightValue ? '!==' : '===';
            case '<':
                return $leftValue < $rightValue ? '<' : '>=';
            case '>':
                return $leftValue > $rightValue ? '>' : '<=';
            case '<=':
                return $leftValue <= $rightValue ? '<=' : '>';
            case '>=':
                return $leftValue >= $rightValue ? '>=' : '<';
            default:
                return '?';
        }
    }
    
    protected function formatValue($value): string
    {
        if (is_null($value)) {
            return 'null';
        } elseif (is_bool($value)) {
            return $value ? 'true' : 'false';
        } elseif (is_string($value)) {
            return "'" . $value . "'";
        } elseif (is_array($value)) {
            return 'array(' . count($value) . ' items)';
        } elseif (is_object($value)) {
            return get_class($value) . ' object';
        } else {
            return (string) $value;
        }
    }
    
    /**
     * Display debug information for assertions
     */
    private function displayDebugInfo(string $expression, string $testFile): void
    {
        echo "\n" . str_repeat('=', 80) . "\n";
        echo "🐛 MODE DEBUG - PHPUnit Assert Command\n";
        echo str_repeat('=', 80) . "\n";
        
        // Informations sur l'expression
        echo "📝 Expression: $expression\n";
        echo "📄 Test actuel: $testFile\n";
        echo "📍 Mode code: " . ($this->isCodeMode() ? 'ACTIVÉ' : 'DÉSACTIVÉ') . "\n";
        
        // Informations sur les variables disponibles
        $mainShellContext = $this->getMainShellContext();
        $codeContext = $GLOBALS['phpunit_code_context'] ?? [];
        $shellVariables = $GLOBALS['psysh_shell_variables'] ?? [];
        
        echo "\n📊 CONTEXTE VARIABLES:\n";
        echo "   - Variables shell principal: " . count($mainShellContext) . "\n";
        echo "   - Variables contexte code: " . count($codeContext) . "\n";
        echo "   - Variables shell globales: " . count($shellVariables) . "\n";
        
        // Fusionner et afficher les variables
        $allVars = array_merge($shellVariables, $codeContext, $mainShellContext);
        
        if (!empty($allVars)) {
            echo "\n📋 VARIABLES DISPONIBLES POUR L'ASSERTION:\n";
            foreach ($allVars as $name => $value) {
                $type = gettype($value);
                $preview = $this->getVariablePreview($value);
                echo "   - \$$name ($type): $preview\n";
            }
        }
        
        // Analyser l'expression pour détecter les variables utilisées
        $usedVars = $this->extractVariablesFromExpression($expression);
        if (!empty($usedVars)) {
            echo "\n🔍 VARIABLES UTILISÉES DANS L'EXPRESSION:\n";
            foreach ($usedVars as $varName) {
                $varExists = isset($allVars[$varName]);
                $status = $varExists ? '✅ DISPONIBLE' : '❌ MANQUANTE';
                echo "   - \$$varName: $status\n";
                if ($varExists) {
                    $type = gettype($allVars[$varName]);
                    $preview = $this->getVariablePreview($allVars[$varName]);
                    echo "     Valeur: $preview ($type)\n";
                }
            }
        }
        
        // Informations sur les services
        echo "\n🔧 SERVICES DISPONIBLES:\n";
        $unifiedSync = $GLOBALS['psysh_unified_sync_service'] ?? null;
        echo "   - Service synchronisation unifié: " . ($unifiedSync ? 'DISPONIBLE' : 'INDISPONIBLE') . "\n";
        
        $syncService = $GLOBALS['psysh_shell_sync_service'] ?? null;
        echo "   - Service synchronisation shell: " . ($syncService ? 'DISPONIBLE' : 'INDISPONIBLE') . "\n";
        
        // Informations sur le test
        $phpunit = $this->phpunit();
        $test = $phpunit->getTest($testFile);
        
        if ($test) {
            $codeLines = $test->getCodeLines();
            $assertionLines = $test->getAssertions();
            echo "\n🧪 INFORMATIONS SUR LE TEST:\n";
            echo "   - Lignes de code existantes: " . count($codeLines) . "\n";
            echo "   - Assertions existantes: " . count($assertionLines) . "\n";
            
            if (!empty($assertionLines)) {
                echo "   - Aperçu des assertions existantes:\n";
                foreach (array_slice($assertionLines, 0, 3) as $i => $line) {
                    echo "     " . ($i + 1) . ": $line\n";
                }
                if (count($assertionLines) > 3) {
                    echo "     ... (" . (count($assertionLines) - 3) . " assertions supplémentaires)\n";
                }
            }
        }
        
        echo str_repeat('=', 80) . "\n\n";
    }
    
    /**
     * Extract variables from an expression
     */
    private function extractVariablesFromExpression(string $expression): array
    {
        $variables = [];
        // Chercher les variables PHP (\$variableName)
        if (preg_match_all('/\$([a-zA-Z_][a-zA-Z0-9_]*)/', $expression, $matches)) {
            $variables = array_unique($matches[1]);
        }
        return $variables;
    }
    
    /**
     * Add assertion to the current test for persistence
     */
    private function addAssertionToCurrentTest(string $expression, ?string $message): void
    {
        try {
            $service = $this->phpunit();
            $currentTest = $service->getCurrentTest();
            
            if (!$currentTest) {
                // Pas de test actuel, pas d'erreur mais on ne peut pas persister
                return;
            }
            
            // Convertir l'expression en assertion PHPUnit
            $phpunitAssertion = $this->convertToPhpUnitAssertion($expression);
            
            // Ajouter l'assertion au test
            $currentTest->addAssertion($phpunitAssertion);
            
            if ($this->debug) {
                echo "📋 Assertion ajoutée au test: $phpunitAssertion\n";
            }
            
        } catch (\Exception $e) {
            if ($this->debug) {
                echo "⚠️  Erreur lors de l'ajout de l'assertion au test: " . $e->getMessage() . "\n";
            }
        }
    }
    
    /**
     * Convert raw expression to PHPUnit assertion
     */
    private function convertToPhpUnitAssertion(string $expr): string
    {
        // Trim whitespace
        $expr = trim($expr);
        
        // Check for instanceof
        if (preg_match('/^(.+?)\s+instanceof\s+(.+)$/i', $expr, $matches)) {
            $object = trim($matches[1]);
            $class = trim($matches[2]);
            return "assertInstanceOf({$class}::class, {$object})";
        }
        
        // Check for === (identity)
        if (preg_match('/^(.+?)\s*===\s*(.+)$/', $expr, $matches)) {
            $left = trim($matches[1]);
            $right = trim($matches[2]);
            
            // Special case for null
            if ($right === 'null') {
                return "assertNull({$left})";
            }
            if ($left === 'null') {
                return "assertNull({$right})";
            }
            
            // Special case for true/false
            if ($right === 'true') {
                return "assertTrue({$left})";
            }
            if ($right === 'false') {
                return "assertFalse({$left})";
            }
            
            return "assertSame({$right}, {$left})";
        }
        
        // Check for == (equality)
        if (preg_match('/^(.+?)\s*==\s*(.+)$/', $expr, $matches)) {
            $left = trim($matches[1]);
            $right = trim($matches[2]);
            return "assertEquals({$right}, {$left})";
        }
        
        // Check for != or !==
        if (preg_match('/^(.+?)\s*!==?\s*(.+)$/', $expr, $matches)) {
            $left = trim($matches[1]);
            $right = trim($matches[2]);
            return "assertNotEquals({$right}, {$left})";
        }
        
        // Check for > or <
        if (preg_match('/^(.+?)\s*>\s*(.+)$/', $expr, $matches)) {
            $left = trim($matches[1]);
            $right = trim($matches[2]);
            return "assertGreaterThan({$right}, {$left})";
        }
        
        if (preg_match('/^(.+?)\s*<\s*(.+)$/', $expr, $matches)) {
            $left = trim($matches[1]);
            $right = trim($matches[2]);
            return "assertLessThan({$right}, {$left})";
        }
        
        // Check for >= or <=
        if (preg_match('/^(.+?)\s*>=\s*(.+)$/', $expr, $matches)) {
            $left = trim($matches[1]);
            $right = trim($matches[2]);
            return "assertGreaterThanOrEqual({$right}, {$left})";
        }
        
        if (preg_match('/^(.+?)\s*<=\s*(.+)$/', $expr, $matches)) {
            $left = trim($matches[1]);
            $right = trim($matches[2]);
            return "assertLessThanOrEqual({$right}, {$left})";
        }
        
        // Check for negation
        if (preg_match('/^!(.+)$/', $expr, $matches)) {
            $inner = trim($matches[1]);
            return "assertFalse({$inner})";
        }
        
        // Default: treat as boolean assertion
        return "assertTrue({$expr})";
    }
}
