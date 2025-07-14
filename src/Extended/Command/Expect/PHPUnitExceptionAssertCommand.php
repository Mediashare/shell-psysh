<?php

namespace Psy\Extended\Command\Expect;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputOption;

class PHPUnitExceptionAssertCommand extends \Psy\Extended\Command\BaseCommand
{

    private string $assertionType;

    public function __construct(string $name)
    {
        $this->assertionType = $name;
        parent::__construct($name);
    }

    protected function configure(): void
    {
        $this
            ->setDescription($this->getDescriptionText())
            ->addArgument('expression', InputArgument::REQUIRED, 'Expression à tester')
            ->addOption('message', 'm', InputOption::VALUE_OPTIONAL, "Message d'exception attendu (optionnel)");
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        $examples = [];
        $workflows = [];
        $tips = [];
        
        switch ($this->assertionType) {
            case 'phpunit:expect-exception':
            case 'phpunit:assert-exception':
                $examples = [
                    'phpunit:expect-exception "throw new InvalidArgumentException()"' => 'Attend une InvalidArgumentException',
                    'phpunit:assert-exception "throw new RuntimeException(\"Error\")" --message="Error"' => 'Attend une RuntimeException avec message spécifique',
                    'phpunit:expect-exception "$user->setEmail(\"invalid\")"' => 'Test d\'une méthode qui doit lever une exception',
                    'phpunit:assert-exception "json_decode(\"invalid json\")"' => 'Test d\'une fonction qui doit échouer',
                    'phpunit:expect-exception "new DateTime(\"invalid date\")"' => 'Test d\'un constructeur qui doit lever une exception'
                ];
                $workflows = [
                    'Test de validation d\'entrée' => [
                        '1. Définir une donnée invalide: \$invalidEmail = "not-an-email"',
                        '2. Tester l\'exception: phpunit:expect-exception "$user->setEmail(\$invalidEmail)"',
                        '3. Vérifier le type d\'exception et le message'
                    ],
                    'Test d\'API qui échoue' => [
                        '1. Simuler une erreur: \$badData = "invalid json"',
                        '2. Tester la fonction: phpunit:assert-exception "json_decode(\$badData, true, 512, JSON_THROW_ON_ERROR)"',
                        '3. Valider le type JsonException'
                    ]
                ];
                $tips = [
                    'Utilisez --message pour vérifier le contenu du message d\'exception',
                    'Testez les cas limites et les données invalides',
                    'Vérifiez que les bonnes exceptions sont levées, pas d\'autres types',
                    'Utilisez try/catch dans vos tests pour des scénarios complexes'
                ];
                break;
                
            case 'phpunit:expect-no-exception':
            case 'phpunit:assert-no-exception':
                $examples = [
                    'phpunit:expect-no-exception "$user->setEmail(\"test@example.com\")"' => 'Vérifie qu\'aucune exception n\'est levée',
                    'phpunit:assert-no-exception "json_decode(\"{\"valid\": true}"' => 'Test d\'une fonction qui doit réussir',
                    'phpunit:expect-no-exception "new DateTime(\"2024-01-01\")"' => 'Test d\'un constructeur qui doit réussir',
                    'phpunit:assert-no-exception "$calculator->add(5, 3)"' => 'Test d\'une opération qui doit fonctionner',
                    'phpunit:expect-no-exception "file_get_contents(\"existing_file.txt\")"' => 'Test d\'accès à un fichier existant'
                ];
                $workflows = [
                    'Test de fonctionnement normal' => [
                        '1. Préparer des données valides: \$validData = "valid input"',
                        '2. Tester l\'opération: phpunit:expect-no-exception "$service->process(\$validData)"',
                        '3. Vérifier que tout fonctionne sans erreur'
                    ],
                    'Test de robustesse' => [
                        '1. Tester plusieurs cas valides successivement',
                        '2. Utiliser phpunit:assert-no-exception pour chaque cas',
                        '3. Valider que le système reste stable'
                    ]
                ];
                $tips = [
                    'Testez les cas nominaux et les données valides',
                    'Vérifiez que les opérations attendues ne lèvent pas d\'exceptions inattendues',
                    'Utilisez cette commande pour valider la robustesse du code',
                    'Combinez avec d\'autres assertions pour des tests complets'
                ];
                break;
        }
        
        return $this->formatComplexHelp([
            'name' => $this->assertionType,
            'description' => $this->getDescriptionText() . ' avec validation avancée',
            'usage' => [
                $this->assertionType . ' "expression_code"',
                $this->assertionType . ' "expression_code" --message="expected message"'
            ],
            'arguments' => [
                'expression' => 'Code PHP à exécuter pour tester l\'exception'
            ],
            'options' => [
                '--message' => 'Message d\'exception attendu (validation partielle)'
            ],
            'examples' => $examples,
            'tips' => $tips,
            'workflows' => $workflows,
            'advanced' => [
                'Support des exceptions personnalisées et des hiérarchies de classes',
                'Validation du message d\'exception avec correspondance partielle',
                'Intégration avec le système de test pour génération automatique',
                'Gestion des exceptions imbriquées et des traces complètes'
            ],
            'troubleshooting' => [
                'Si l\'exception attendue n\'est pas levée: vérifiez la syntaxe du code',
                'Pour les exceptions personnalisées: utilisez le nom de classe complet',
                'En cas d\'exception inattendue: examinez la trace avec phpunit:debug',
                'Pour tester les messages: utilisez l\'option --message avec une partie du texte'
            ],
            'related' => [
                'phpunit:assert' => 'Assertions générales',
                'phpunit:debug' => 'Débogue les exceptions',
                'phpunit:mock' => 'Simule des exceptions dans les mocks',
                'phpunit:trace' => 'Affiche la trace des exceptions'
            ]
        ]);
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $expression = $input->getArgument('expression');
        $expectedMessage = $input->getOption('message');

        try {
            $this->executeWithExceptionHandling($expression, $output, $expectedMessage);
            return 0;
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de l'assertion: " . $e->getMessage()));
            return 1;
        }
    }

    private function executeWithExceptionHandling(string $expression, OutputInterface $output, ?string $expectedMessage): void
    {
        switch ($this->assertionType) {
            case 'phpunit:expect-exception':
            case 'phpunit:assert-exception':
                $this->assertException($expression, $output, $expectedMessage);
                break;
            case 'phpunit:expect-no-exception':
            case 'phpunit:assert-no-exception':
                $this->assertNoException($expression, $output);
                break;
        }
    }

    private function assertException(string $expression, OutputInterface $output, ?string $expectedMessage): void
    {
        $className = $this->parseExceptionClassName($this->assertionType);
        $exceptionOccurred = false;
        $messageMatched = true;

        try {
            eval($expression);
        } catch (\Throwable $e) {
            $exceptionOccurred = is_a($e, $className);
            if ($exceptionOccurred && $expectedMessage !== null) {
                $messageMatched = strpos($e->getMessage(), $expectedMessage) !== false;
            }

            if ($exceptionOccurred && $messageMatched) {
                $output->writeln($this->formatSuccess("✅ Exception attendue '{$className}' capturée"));
                if ($expectedMessage !== null) {
                    $output->writeln($this->formatSuccess("✅ Message d'exception attendu: '{$expectedMessage}'"));
                }
            } else {
                $output->writeln($this->formatError("❌ Exception inattendue capturée: " . get_class($e)));
                if (!$messageMatched) {
                    $output->writeln($this->formatError("❌ Message d'exception incorrect: " . $e->getMessage()));
                }
            }
            return;
        }

        $output->writeln($this->formatError("❌ Aucune exception {$className} capturée"));
    }

    private function assertNoException(string $expression, OutputInterface $output): void
    {
        try {
            eval($expression);
            $output->writeln($this->formatSuccess("✅ Aucune exception lancée"));
        } catch (\Throwable $e) {
            $output->writeln($this->formatError("❌ Exception non attendue: " . get_class($e)));
            $output->writeln($this->formatError("Message: " . $e->getMessage()));
        }
    }

    private function parseExceptionClassName(string $assertionType): string
    {
        // Support pour les deux syntaxes : expect-exception et assert-exception
        if (preg_match('/phpunit:(expect|assert)-exception (.+)/', $assertionType, $matches)) {
            return $matches[2];
        }
        return '\\Exception';
    }

    private function getDescriptionText(): string
    {
        switch ($this->assertionType) {
            case 'phpunit:expect-exception':
            case 'phpunit:assert-exception':
                return "Attendre qu'une exception spécifique soit lancée";
            case 'phpunit:expect-no-exception':
            case 'phpunit:assert-no-exception':
                return "Vérifier qu'aucune exception n'est lancée";
            default:
                return '';
        }
    }

    public static function getExceptionAssertionCommands(): array
    {
        return [
            // Commandes expect (style original)
            new self('phpunit:expect-exception'),
            new self('phpunit:expect-no-exception'),
            // Commandes assert (alias pour cohérence avec les autres assertions)
            new self('phpunit:assert-exception'),
            new self('phpunit:assert-no-exception')
        ];
    }
}
