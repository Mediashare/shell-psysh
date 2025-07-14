<?php

namespace Psy\Extended\Command\Assert;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;

class PHPUnitTypedAssertCommand extends \Psy\Extended\Command\BaseCommand
{

    private array $commands = [
        'phpunit:assert-type' => 'assertType',
        'phpunit:assert-instance' => 'assertInstance', 
        'phpunit:assert-count' => 'assertCount',
        'phpunit:assert-empty' => 'assertEmpty',
        'phpunit:assert-not-empty' => 'assertNotEmpty',
        'phpunit:assert-true' => 'assertTrue',
        'phpunit:assert-false' => 'assertFalse',
        'phpunit:assert-null' => 'assertNull',
        'phpunit:assert-not-null' => 'assertNotNull'
    ];

    public function __construct(?string $name = null)
    {
        // Si aucun nom n'est fourni, utiliser le premier
        if ($name === null) {
            $name = array_key_first($this->commands);
        }
        parent::__construct($name);
    }

    protected function configure(): void
    {
        $commandName = $this->getName();
        
        switch ($commandName) {
            case 'phpunit:assert-type':
                $this->setDescription('Vérifier le type d\'une variable')
                     ->addArgument('type', InputArgument::REQUIRED, 'Type attendu (string, array, object, etc.)')
                     ->addArgument('expression', InputArgument::REQUIRED, 'Expression à tester');
                break;
                
            case 'phpunit:assert-instance':
                $this->setDescription('Vérifier qu\'un objet est une instance d\'une classe')
                     ->addArgument('class', InputArgument::REQUIRED, 'Nom de la classe attendue')
                     ->addArgument('expression', InputArgument::REQUIRED, 'Expression à tester');
                break;
                
            case 'phpunit:assert-count':
                $this->setDescription('Vérifier le nombre d\'éléments dans un tableau/collection')
                     ->addArgument('count', InputArgument::REQUIRED, 'Nombre attendu')
                     ->addArgument('expression', InputArgument::REQUIRED, 'Expression à tester');
                break;
                
            case 'phpunit:assert-empty':
                $this->setDescription('Vérifier qu\'une variable est vide')
                     ->addArgument('expression', InputArgument::REQUIRED, 'Expression à tester');
                break;
                
            case 'phpunit:assert-not-empty':
                $this->setDescription('Vérifier qu\'une variable n\'est pas vide')
                     ->addArgument('expression', InputArgument::REQUIRED, 'Expression à tester');
                break;
                
            case 'phpunit:assert-true':
                $this->setDescription('Vérifier qu\'une expression est vraie')
                     ->addArgument('expression', InputArgument::REQUIRED, 'Expression à tester');
                break;
                
            case 'phpunit:assert-false':
                $this->setDescription('Vérifier qu\'une expression est fausse')
                     ->addArgument('expression', InputArgument::REQUIRED, 'Expression à tester');
                break;
                
            case 'phpunit:assert-null':
                $this->setDescription('Vérifier qu\'une variable est null')
                     ->addArgument('expression', InputArgument::REQUIRED, 'Expression à tester');
                break;
                
            case 'phpunit:assert-not-null':
                $this->setDescription('Vérifier qu\'une variable n\'est pas null')
                     ->addArgument('expression', InputArgument::REQUIRED, 'Expression à tester');
                break;
        }
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        $commandName = $this->getName();
        
        switch ($commandName) {
            case 'phpunit:assert-type':
                return $this->formatComplexHelp([
                    'name' => 'phpunit:assert-type',
                    'description' => 'Vérification du type d\'une variable avec support des types PHP natifs',
                    'usage' => [
                        'phpunit:assert-type <type> <expression>'
                    ],
                    'arguments' => [
                        'type' => 'Type attendu (string, int, array, object, bool, null, etc.)',
                        'expression' => 'Expression à évaluer'
                    ],
                    'examples' => [
                        'phpunit:assert-type string $user->getName()' => 'Vérifie que getName() retourne une chaîne',
                        'phpunit:assert-type array $permissions' => 'Vérifie que $permissions est un tableau',
                        'phpunit:assert-type object $entity' => 'Vérifie que $entity est un objet',
                        'phpunit:assert-type int $count' => 'Vérifie que $count est un entier',
                        'phpunit:assert-type bool $isActive' => 'Vérifie que $isActive est un booléen'
                    ],
                    'tips' => [
                        'Types supportés: string, int, array, object, bool, null, float, resource, callable',
                        'Utilise gettype() en interne pour la vérification',
                        'Supporte les alias: integer/int, boolean/bool, double/float'
                    ]
                ]);
                
            case 'phpunit:assert-instance':
                return $this->formatComplexHelp([
                    'name' => 'phpunit:assert-instance',
                    'description' => 'Vérification qu\'un objet est une instance d\'une classe ou interface',
                    'usage' => [
                        'phpunit:assert-instance <class> <expression>'
                    ],
                    'examples' => [
                        'phpunit:assert-instance User $user' => 'Vérifie que $user est une instance de User',
                        'phpunit:assert-instance DateTime $date' => 'Vérifie que $date est une instance de DateTime',
                        'phpunit:assert-instance \App\Entity\Product $product' => 'Avec namespace complet'
                    ],
                    'tips' => [
                        'Utilise instanceof pour la vérification',
                        'Supporte les namespaces et les classes pleinement qualifiées',
                        'Fonctionne avec les interfaces et classes abstraites'
                    ]
                ]);
                
            case 'phpunit:assert-count':
                return $this->formatComplexHelp([
                    'name' => 'phpunit:assert-count',
                    'description' => 'Vérification du nombre d\'éléments dans un tableau ou objet Countable',
                    'usage' => [
                        'phpunit:assert-count <count> <expression>'
                    ],
                    'examples' => [
                        'phpunit:assert-count 5 $users' => 'Vérifie que $users contient 5 éléments',
                        'phpunit:assert-count 0 $errors' => 'Vérifie que $errors est vide',
                        'phpunit:assert-count 3 $collection->getItems()' => 'Avec méthode de collection'
                    ],
                    'tips' => [
                        'Fonctionne avec les tableaux PHP et les objets implémentant Countable',
                        'Utilise count() en interne',
                        'Parfait pour vérifier les collections et listes'
                    ]
                ]);
                
            case 'phpunit:assert-empty':
                return $this->formatComplexHelp([
                    'name' => 'phpunit:assert-empty',
                    'description' => 'Vérification qu\'une variable est vide selon les règles PHP',
                    'usage' => [
                        'phpunit:assert-empty <expression>'
                    ],
                    'examples' => [
                        'phpunit:assert-empty $errors' => 'Vérifie que $errors est vide',
                        'phpunit:assert-empty $user->getComments()' => 'Vérifie qu\'il n\'y a pas de commentaires',
                        'phpunit:assert-empty trim($input)' => 'Vérifie qu\'après trim, la chaîne est vide'
                    ],
                    'tips' => [
                        'Utilise empty() : vrai pour "", 0, "0", null, false, array(), variable non définie',
                        'Plus permissif que l\'égalité stricte',
                        'Utile pour valider les formulaires et entrées utilisateur'
                    ]
                ]);
                
            case 'phpunit:assert-not-empty':
                return $this->formatComplexHelp([
                    'name' => 'phpunit:assert-not-empty',
                    'description' => 'Vérification qu\'une variable n\'est pas vide',
                    'usage' => [
                        'phpunit:assert-not-empty <expression>'
                    ],
                    'examples' => [
                        'phpunit:assert-not-empty $user->getName()' => 'Vérifie que le nom n\'est pas vide',
                        'phpunit:assert-not-empty $products' => 'Vérifie qu\'il y a des produits',
                        'phpunit:assert-not-empty $result->getData()' => 'Vérifie que des données sont présentes'
                    ],
                    'tips' => [
                        'Inverse de assert-empty',
                        'Utile pour vérifier la présence de données obligatoires',
                        'Combine bien avec les autres assertions'
                    ]
                ]);
                
            case 'phpunit:assert-true':
                return $this->formatComplexHelp([
                    'name' => 'phpunit:assert-true',
                    'description' => 'Vérification stricte qu\'une expression est exactement true',
                    'usage' => [
                        'phpunit:assert-true <expression>'
                    ],
                    'examples' => [
                        'phpunit:assert-true $user->isActive()' => 'Vérifie que l\'utilisateur est actif',
                        'phpunit:assert-true $result === true' => 'Comparaison stricte',
                        'phpunit:assert-true in_array("admin", $roles)' => 'Vérifie la présence d\'un rôle'
                    ],
                    'tips' => [
                        'Vérification stricte avec === true',
                        'Différent de assert() qui accepte les valeurs "truthy"',
                        'Idéal pour les valeurs booléennes explicites'
                    ]
                ]);
                
            case 'phpunit:assert-false':
                return $this->formatComplexHelp([
                    'name' => 'phpunit:assert-false',
                    'description' => 'Vérification stricte qu\'une expression est exactement false',
                    'usage' => [
                        'phpunit:assert-false <expression>'
                    ],
                    'examples' => [
                        'phpunit:assert-false $user->isDeleted()' => 'Vérifie que l\'utilisateur n\'est pas supprimé',
                        'phpunit:assert-false $result === false' => 'Comparaison stricte',
                        'phpunit:assert-false empty($data)' => 'Vérifie que $data n\'est pas vide'
                    ],
                    'tips' => [
                        'Vérification stricte avec === false',
                        'Utile pour les drapeaux booléens',
                        'Complémentaire de assert-true'
                    ]
                ]);
                
            case 'phpunit:assert-null':
                return $this->formatComplexHelp([
                    'name' => 'phpunit:assert-null',
                    'description' => 'Vérification qu\'une variable est exactement null',
                    'usage' => [
                        'phpunit:assert-null <expression>'
                    ],
                    'examples' => [
                        'phpunit:assert-null $user->getDeletedAt()' => 'Vérifie que l\'utilisateur n\'est pas supprimé',
                        'phpunit:assert-null $cache->get("key")' => 'Vérifie qu\'une clé n\'est pas en cache',
                        'phpunit:assert-null $result' => 'Vérifie qu\'aucun résultat n\'est retourné'
                    ],
                    'tips' => [
                        'Vérification stricte avec === null',
                        'Différent de empty() qui accepte plusieurs valeurs',
                        'Utile pour les valeurs optionnelles'
                    ]
                ]);
                
            case 'phpunit:assert-not-null':
                return $this->formatComplexHelp([
                    'name' => 'phpunit:assert-not-null',
                    'description' => 'Vérification qu\'une variable n\'est pas null',
                    'usage' => [
                        'phpunit:assert-not-null <expression>'
                    ],
                    'examples' => [
                        'phpunit:assert-not-null $user->getId()' => 'Vérifie que l\'ID est défini',
                        'phpunit:assert-not-null $result->getData()' => 'Vérifie que des données sont présentes',
                        'phpunit:assert-not-null $service->getConnection()' => 'Vérifie qu\'une connexion existe'
                    ],
                    'tips' => [
                        'Inverse de assert-null',
                        'Utile pour vérifier l\'initialisation des objets',
                        'Combine bien avec assert-instance pour vérifier les objets'
                    ]
                ]);
                
            default:
                return 'Aide non disponible pour cette commande.';
        }
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $commandName = $this->getName();
        
        try {
            switch ($commandName) {
                case 'phpunit:assert-type':
                    return $this->executeTypeAssertion($input, $output);
                    
                case 'phpunit:assert-instance':
                    return $this->executeInstanceAssertion($input, $output);
                    
                case 'phpunit:assert-count':
                    return $this->executeCountAssertion($input, $output);
                    
                case 'phpunit:assert-empty':
                    return $this->executeEmptyAssertion($input, $output);
                    
                case 'phpunit:assert-not-empty':
                    return $this->executeNotEmptyAssertion($input, $output);
                    
                case 'phpunit:assert-true':
                    return $this->executeTrueAssertion($input, $output);
                    
                case 'phpunit:assert-false':
                    return $this->executeFalseAssertion($input, $output);
                    
                case 'phpunit:assert-null':
                    return $this->executeNullAssertion($input, $output);
                    
                case 'phpunit:assert-not-null':
                    return $this->executeNotNullAssertion($input, $output);
                    
                default:
                    $output->writeln($this->formatError("Commande non reconnue: {$commandName}"));
                    return 1;
            }
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de l'assertion: " . $e->getMessage()));
            return 1;
        }
    }
    
    private function executeTypeAssertion(InputInterface $input, OutputInterface $output): int
    {
        $expectedType = $input->getArgument('type');
        $expression = $input->getArgument('expression');
        
        $value = $this->executePhpCode("return {$expression};");
        if (is_string($value) && strpos($value, 'Erreur:') === 0) {
            $output->writeln($this->formatError("Erreur dans l'expression: {$value}"));
            return 1;
        }
        
        $actualType = gettype($value);
        $success = $actualType === $expectedType || $this->isCompatibleType($value, $expectedType);
        
        if ($success) {
            $output->writeln($this->formatSuccess("✅ Type correct: {$actualType}"));
        } else {
            $output->writeln($this->formatError("❌ Type incorrect"));
            $output->writeln("Expected: {$expectedType}");
            $output->writeln("Actual: {$actualType}");
        }
        
        $this->addAssertionToTest($expression, "assertInternalType", [$expectedType]);
        return $success ? 0 : 1;
    }
    
    private function executeInstanceAssertion(InputInterface $input, OutputInterface $output): int
    {
        $expectedClass = $input->getArgument('class');
        $expression = $input->getArgument('expression');
        
        $value = $this->executePhpCode("return {$expression};");
        if (is_string($value) && strpos($value, 'Erreur:') === 0) {
            $output->writeln($this->formatError("Erreur dans l'expression: {$value}"));
            return 1;
        }
        
        $success = is_object($value) && $value instanceof $expectedClass;
        
        if ($success) {
            $actualClass = get_class($value);
            $output->writeln($this->formatSuccess("✅ Instance correcte: {$actualClass}"));
        } else {
            $output->writeln($this->formatError("❌ Instance incorrecte"));
            $output->writeln("Expected: {$expectedClass}");
            $output->writeln("Actual: " . (is_object($value) ? get_class($value) : gettype($value)));
        }
        
        $this->addAssertionToTest($expression, "assertInstanceOf", [$expectedClass]);
        return $success ? 0 : 1;
    }
    
    private function executeCountAssertion(InputInterface $input, OutputInterface $output): int
    {
        $expectedCount = (int) $input->getArgument('count');
        $expression = $input->getArgument('expression');
        
        $value = $this->executePhpCode("return {$expression};");
        if (is_string($value) && strpos($value, 'Erreur:') === 0) {
            $output->writeln($this->formatError("Erreur dans l'expression: {$value}"));
            return 1;
        }
        
        if (is_array($value) || $value instanceof \Countable) {
            $actualCount = count($value);
            $success = $actualCount === $expectedCount;
            
            if ($success) {
                $output->writeln($this->formatSuccess("✅ Nombre correct: {$actualCount}"));
            } else {
                $output->writeln($this->formatError("❌ Nombre incorrect"));
                $output->writeln("Expected: {$expectedCount}");
                $output->writeln("Actual: {$actualCount}");
            }
        } else {
            $success = false;
            $output->writeln($this->formatError("❌ La valeur n'est pas dénombrable"));
            $output->writeln("Type: " . gettype($value));
        }
        
        $this->addAssertionToTest($expression, "assertCount", [$expectedCount]);
        return $success ? 0 : 1;
    }
    
    private function executeEmptyAssertion(InputInterface $input, OutputInterface $output): int
    {
        $expression = $input->getArgument('expression');
        
        $value = $this->executePhpCode("return {$expression};");
        if (is_string($value) && strpos($value, 'Erreur:') === 0) {
            $output->writeln($this->formatError("Erreur dans l'expression: {$value}"));
            return 1;
        }
        
        $success = empty($value);
        
        if ($success) {
            $output->writeln($this->formatSuccess("✅ Valeur vide"));
        } else {
            $output->writeln($this->formatError("❌ Valeur non vide"));
            $output->writeln("Actual: " . $this->formatValue($value));
        }
        
        $this->addAssertionToTest($expression, "assertEmpty", []);
        return $success ? 0 : 1;
    }
    
    private function executeNotEmptyAssertion(InputInterface $input, OutputInterface $output): int
    {
        $expression = $input->getArgument('expression');
        
        $value = $this->executePhpCode("return {$expression};");
        if (is_string($value) && strpos($value, 'Erreur:') === 0) {
            $output->writeln($this->formatError("Erreur dans l'expression: {$value}"));
            return 1;
        }
        
        $success = !empty($value);
        
        if ($success) {
            $output->writeln($this->formatSuccess("✅ Valeur non vide"));
        } else {
            $output->writeln($this->formatError("❌ Valeur vide"));
        }
        
        $this->addAssertionToTest($expression, "assertNotEmpty", []);
        return $success ? 0 : 1;
    }
    
    private function executeTrueAssertion(InputInterface $input, OutputInterface $output): int
    {
        $expression = $input->getArgument('expression');
        
        $value = $this->executePhpCode("return {$expression};");
        if (is_string($value) && strpos($value, 'Erreur:') === 0) {
            $output->writeln($this->formatError("Erreur dans l'expression: {$value}"));
            return 1;
        }
        
        $success = $value === true;
        
        if ($success) {
            $output->writeln($this->formatSuccess("✅ Valeur true"));
        } else {
            $output->writeln($this->formatError("❌ Valeur n'est pas true"));
            $output->writeln("Actual: " . $this->formatValue($value));
        }
        
        $this->addAssertionToTest($expression, "assertTrue", []);
        return $success ? 0 : 1;
    }
    
    private function executeFalseAssertion(InputInterface $input, OutputInterface $output): int
    {
        $expression = $input->getArgument('expression');
        
        $value = $this->executePhpCode("return {$expression};");
        if (is_string($value) && strpos($value, 'Erreur:') === 0) {
            $output->writeln($this->formatError("Erreur dans l'expression: {$value}"));
            return 1;
        }
        
        $success = $value === false;
        
        if ($success) {
            $output->writeln($this->formatSuccess("✅ Valeur false"));
        } else {
            $output->writeln($this->formatError("❌ Valeur n'est pas false"));
            $output->writeln("Actual: " . $this->formatValue($value));
        }
        
        $this->addAssertionToTest($expression, "assertFalse", []);
        return $success ? 0 : 1;
    }
    
    private function executeNullAssertion(InputInterface $input, OutputInterface $output): int
    {
        $expression = $input->getArgument('expression');
        
        $value = $this->executePhpCode("return {$expression};");
        if (is_string($value) && strpos($value, 'Erreur:') === 0) {
            $output->writeln($this->formatError("Erreur dans l'expression: {$value}"));
            return 1;
        }
        
        $success = $value === null;
        
        if ($success) {
            $output->writeln($this->formatSuccess("✅ Valeur null"));
        } else {
            $output->writeln($this->formatError("❌ Valeur n'est pas null"));
            $output->writeln("Actual: " . $this->formatValue($value));
        }
        
        $this->addAssertionToTest($expression, "assertNull", []);
        return $success ? 0 : 1;
    }
    
    private function executeNotNullAssertion(InputInterface $input, OutputInterface $output): int
    {
        $expression = $input->getArgument('expression');
        
        $value = $this->executePhpCode("return {$expression};");
        if (is_string($value) && strpos($value, 'Erreur:') === 0) {
            $output->writeln($this->formatError("Erreur dans l'expression: {$value}"));
            return 1;
        }
        
        $success = $value !== null;
        
        if ($success) {
            $output->writeln($this->formatSuccess("✅ Valeur non null"));
        } else {
            $output->writeln($this->formatError("❌ Valeur est null"));
        }
        
        $this->addAssertionToTest($expression, "assertNotNull", []);
        return $success ? 0 : 1;
    }
    
    private function isCompatibleType($value, string $expectedType): bool
    {
        return match($expectedType) {
            'int', 'integer' => is_int($value),
            'float', 'double' => is_float($value),
            'string' => is_string($value),
            'bool', 'boolean' => is_bool($value),
            'array' => is_array($value),
            'object' => is_object($value),
            'null' => is_null($value),
            'resource' => is_resource($value),
            'callable' => is_callable($value),
            default => false
        };
    }
    
    private function addAssertionToTest(string $expression, string $method, array $params): void
    {
        $currentTest = $this->getCurrentTest();
        if ($currentTest) {
            $service = $this->phpunit();
            $paramStr = empty($params) ? '' : implode(', ', array_map(fn($p) => var_export($p, true), $params)) . ', ';
            $assertionCode = "\$this->{$method}({$paramStr}{$expression});";
            $service->addAssertionToTest($currentTest, $assertionCode);
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
    
    public static function getAllCommands(): array
    {
        return [
            new self('phpunit:assert-type'),
            new self('phpunit:assert-instance'), 
            new self('phpunit:assert-count'),
            new self('phpunit:assert-empty'),
            new self('phpunit:assert-not-empty'),
            new self('phpunit:assert-true'),
            new self('phpunit:assert-false'),
            new self('phpunit:assert-null'),
            new self('phpunit:assert-not-null')
        ];
    }
}
