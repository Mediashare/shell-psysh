<?php

namespace Psy\Extended\Command\Other;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;/**
 * Commande PHPUnit avec évaluation directe d'expressions
 * Utilise la syntaxe : phpunit:eval '$result === 42'
 */
class PHPUnitEvalCommand extends \Psy\Extended\Command\BaseCommand
{

    public function __construct()
    {
        parent::__construct('phpunit:eval');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Évalue une expression PHP et l\'ajoute comme assertion PHPUnit')
            ->addArgument('expression', InputArgument::REQUIRED, 'Expression PHP à évaluer')
            ->setHelp('Évalue une expression PHP et génère l\'assertion PHPUnit appropriée');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $expression = $input->getArgument('expression');
        
        if (empty($expression)) {
            $output->writeln($this->formatError('Aucune expression fournie'));
            return 1;
        }

        try {
            // Analyser l'expression
            $analysis = $this->analyzeExpression($expression);
            
            // Exécuter l'expression
            $result = $this->executePhpCode("return ($expression);");
            
            if (is_string($result) && strpos($result, 'Erreur:') === 0) {
                $output->writeln($this->formatError("Erreur d'exécution: {$result}"));
                return 1;
            }
            
            $success = (bool) $result;
            
            if ($success) {
                $output->writeln($this->formatSuccess("✅ Expression évaluée avec succès: {$expression}"));
                $output->writeln($this->formatInfo("Résultat: " . ($success ? 'true' : 'false')));
                
                // Ajouter au test courant
                $this->addAssertionToCurrentTest($expression, $analysis);
                
                return 0;
            } else {
                $output->writeln($this->formatError("❌ Expression évaluée à false: {$expression}"));
                
                // Donner plus de détails sur l'échec
                $details = $this->analyzeFailure($expression, $analysis);
                if ($details) {
                    $output->writeln($details);
                }
                
                return 1;
            }
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de l'évaluation: " . $e->getMessage()));
            return 1;
        }
    }
    
    /**
     * Analyse l'expression pour comprendre sa structure
     */
    private function analyzeExpression(string $expression): array
    {
        $analysis = [
            'type' => 'boolean',
            'raw' => $expression
        ];
        
        // Détecter les opérateurs de comparaison
        if (preg_match('/(.+?)\s*(===|==|!=|!==|>=|<=|>|<)\s*(.+)/', $expression, $matches)) {
            $analysis['type'] = 'comparison';
            $analysis['left'] = trim($matches[1]);
            $analysis['operator'] = $matches[2];
            $analysis['right'] = trim($matches[3]);
        }
        // Détecter instanceof
        elseif (preg_match('/(.+?)\s+instanceof\s+(.+)/', $expression, $matches)) {
            $analysis['type'] = 'instanceof';
            $analysis['object'] = trim($matches[1]);
            $analysis['class'] = trim($matches[2]);
        }
        // Détecter les fonctions communes
        elseif (preg_match('/^(empty|isset|is_null|is_array|is_object|is_string|is_int|is_bool)\s*\((.+)\)$/', $expression, $matches)) {
            $analysis['type'] = 'function';
            $analysis['function'] = $matches[1];
            $analysis['argument'] = trim($matches[2]);
        }
        
        return $analysis;
    }
    
    /**
     * Analyse les détails d'un échec
     */
    private function analyzeFailure(string $expression, array $analysis): ?string
    {
        if ($analysis['type'] === 'comparison') {
            try {
                $leftValue = $this->executePhpCode("return {$analysis['left']};");
                $rightValue = $this->executePhpCode("return {$analysis['right']};");
                
                return sprintf(
                    "Comparaison détaillée:\n" .
                    "  Gauche: %s = %s\n" .
                    "  Droite: %s = %s\n" .
                    "  Opérateur: %s",
                    $analysis['left'],
                    $this->formatValue($leftValue),
                    $analysis['right'],
                    $this->formatValue($rightValue),
                    $analysis['operator']
                );
            } catch (\Exception $e) {
                return "Impossible d'analyser les valeurs: " . $e->getMessage();
            }
        }
        
        if ($analysis['type'] === 'instanceof') {
            try {
                $object = $this->executePhpCode("return {$analysis['object']};");
                
                return sprintf(
                    "Test instanceof détaillé:\n" .
                    "  Objet: %s\n" .
                    "  Type actuel: %s\n" .
                    "  Classe attendue: %s",
                    $analysis['object'],
                    is_object($object) ? get_class($object) : gettype($object),
                    $analysis['class']
                );
            } catch (\Exception $e) {
                return "Impossible d'analyser l'objet: " . $e->getMessage();
            }
        }
        
        return null;
    }
    
    /**
     * Formate une valeur pour l'affichage
     */
    protected function formatValue($value): string
    {
        if (is_null($value)) {
            return 'null';
        } elseif (is_bool($value)) {
            return $value ? 'true' : 'false';
        } elseif (is_string($value)) {
            return '"' . addslashes($value) . '"';
        } elseif (is_array($value)) {
            return 'array(' . count($value) . ' items)';
        } elseif (is_object($value)) {
            return get_class($value) . ' object';
        } else {
            return (string) $value;
        }
    }
    
    /**
     * Ajoute l'assertion au test courant (version spécifique pour eval)
     */
    private function addAssertionToCurrentTest(string $expression, array $analysis): void
    {
        $currentTest = $this->getCurrentTest();
        if (!$currentTest) {
            return;
        }
        
        $service = $this->phpunit();
        $phpunitCode = $this->generatePhpunitCode($analysis);
        
        if ($phpunitCode) {
            $service->addAssertionToTest($currentTest, $phpunitCode);
        }
    }
    
    /**
     * Génère le code PHPUnit approprié
     */
    private function generatePhpunitCode(array $analysis): string
    {
        switch ($analysis['type']) {
            case 'comparison':
                return $this->generateComparisonAssertion($analysis);
            case 'instanceof':
                return $this->generateInstanceofAssertion($analysis);
            case 'function':
                return $this->generateFunctionAssertion($analysis);
            default:
                return "\$this->assertTrue({$analysis['raw']});";
        }
    }
    
    /**
     * Génère une assertion de comparaison
     */
    private function generateComparisonAssertion(array $analysis): string
    {
        $left = $analysis['left'];
        $right = $analysis['right'];
        $operator = $analysis['operator'];
        
        switch ($operator) {
            case '===':
                return "\$this->assertSame({$right}, {$left});";
            case '==':
                return "\$this->assertEquals({$right}, {$left});";
            case '!=':
                return "\$this->assertNotEquals({$right}, {$left});";
            case '!==':
                return "\$this->assertNotSame({$right}, {$left});";
            case '>':
                return "\$this->assertGreaterThan({$right}, {$left});";
            case '<':
                return "\$this->assertLessThan({$right}, {$left});";
            case '>=':
                return "\$this->assertGreaterThanOrEqual({$right}, {$left});";
            case '<=':
                return "\$this->assertLessThanOrEqual({$right}, {$left});";
            default:
                return "\$this->assertTrue({$left} {$operator} {$right});";
        }
    }
    
    /**
     * Génère une assertion instanceof
     */
    private function generateInstanceofAssertion(array $analysis): string
    {
        $object = $analysis['object'];
        $class = $analysis['class'];
        
        // Gérer les classes sans namespace
        if (!str_contains($class, '\\') && !str_contains($class, '::')) {
            $class = $class . '::class';
        }
        
        return "\$this->assertInstanceOf({$class}, {$object});";
    }
    
    /**
     * Génère une assertion de fonction
     */
    private function generateFunctionAssertion(array $analysis): string
    {
        $function = $analysis['function'];
        $argument = $analysis['argument'];
        
        switch ($function) {
            case 'empty':
                return "\$this->assertEmpty({$argument});";
            case 'isset':
                // isset est plus complexe, on utilise une assertion générique
                return "\$this->assertTrue(isset({$argument}));";
            case 'is_null':
                return "\$this->assertNull({$argument});";
            case 'is_array':
                return "\$this->assertIsArray({$argument});";
            case 'is_object':
                return "\$this->assertIsObject({$argument});";
            case 'is_string':
                return "\$this->assertIsString({$argument});";
            case 'is_int':
                return "\$this->assertIsInt({$argument});";
            case 'is_bool':
                return "\$this->assertIsBool({$argument});";
            default:
                return "\$this->assertTrue({$function}({$argument}));";
        }
    }
    
    /**
     * Aide standard pour PsySH shell
     */
    public function getStandardHelp(): string
    {
        return "Évalue une expression PHP et l'ajoute comme assertion PHPUnit.\n" .
               "Usage: phpunit:eval '\$result === 42'";
    }
    
    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit:eval',
            'description' => 'Évalue une expression PHP et génère l\'assertion PHPUnit appropriée',
            'usage' => [
                'phpunit:eval \'$variable === expected_value\'',
                'phpunit:eval \'$user->getName() == "John"\'',
                'phpunit:eval \'count($array) > 0\'',
                'phpunit:eval \'$result instanceof User\'',
                'phpunit:eval \'empty($errors)\'',
                'phpunit:eval \'isset($data["key"])\''
            ],
            'examples' => [
                'phpunit:eval \'$result === 42\'' => 'Vérifie que $result est strictement égal à 42',
                'phpunit:eval \'$user->isActive()\'' => 'Vérifie que l\'utilisateur est actif (expression booléenne)',
                'phpunit:eval \'!empty($data)\'' => 'Vérifie que $data n\'est pas vide',
                'phpunit:eval \'$obj instanceof User\'' => 'Vérifie que $obj est une instance de User',
                'phpunit:eval \'count($items) >= 3\'' => 'Vérifie que $items contient au moins 3 éléments'
            ],
            'operators' => [
                '===' => 'Comparaison stricte → assertSame()',
                '==' => 'Comparaison souple → assertEquals()',
                '!=' => 'Différent (souple) → assertNotEquals()',
                '!==' => 'Différent (strict) → assertNotSame()',
                '>' => 'Supérieur → assertGreaterThan()',
                '<' => 'Inférieur → assertLessThan()',
                '>=' => 'Supérieur ou égal → assertGreaterThanOrEqual()',
                '<=' => 'Inférieur ou égal → assertLessThanOrEqual()',
                'instanceof' => 'Instance de classe → assertInstanceOf()'
            ],
            'functions' => [
                'empty()' => 'Vide → assertEmpty()',
                'isset()' => 'Défini → assertTrue(isset())',
                'is_null()' => 'Null → assertNull()',
                'is_array()' => 'Tableau → assertIsArray()',
                'is_object()' => 'Objet → assertIsObject()',
                'is_string()' => 'Chaîne → assertIsString()',
                'is_int()' => 'Entier → assertIsInt()',
                'is_bool()' => 'Booléen → assertIsBool()'
            ],
            'tips' => [
                'Utilisez des guillemets simples pour éviter l\'interprétation du shell',
                'L\'expression est évaluée dans le contexte du shell PsySH',
                'Génère automatiquement l\'assertion PHPUnit appropriée',
                'Analyse les échecs avec des détails sur les valeurs',
                'Intégration automatique au test courant'
            ]
        ]);
    }
}
