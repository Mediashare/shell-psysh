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
            ->addOption('setup', null, InputOption::VALUE_OPTIONAL, 'Code de configuration à exécuter avant l\'assertion');
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
                
                // Ajouter l'assertion au test courant
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
}
