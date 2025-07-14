<?php

namespace Psy\Extended\Command\Assert;


use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;

class PHPUnitAssertEqualsCommand extends BaseAssertCommand
{
    protected string $assertType = 'Equals';
    protected string $assertMethod = 'assertEquals';

    public function __construct()
    {
        parent::__construct('phpunit:assert-equals');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Assert that two values are equal')
            ->addArgument('expected', InputArgument::REQUIRED, 'Expected value')
            ->addArgument('actual', InputArgument::REQUIRED, 'Actual value')
            ->addArgument('message', InputArgument::OPTIONAL, 'Optional failure message', '');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $expected = $input->getArgument('expected');
        $actual = $input->getArgument('actual');
        $message = $input->getArgument('message');

        return $this->executeAssertion($input, $output, $expected, $actual, $message);
    }

    protected function performAssertion($expected = null, $actual = null, string $message = ''): array
    {
        $success = $expected == $actual;
        
        return [
            'success' => $success,
            'expected' => $expected,
            'actual' => $actual,
            'details' => $success ? 'Values are equal' : 'Values are not equal'
        ];
    }

    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit:assert-equals',
            'description' => 'Vérifie que deux valeurs sont égales (avec conversion de type)',
            'usage' => [
                'phpunit:assert-equals <expected> <actual>',
                'phpunit:assert-equals <expected> <actual> "<message>"'
            ],
            'examples' => [
                'phpunit:assert-equals 100 $invoice->getTotal()' => 'Vérifie que le total est 100',
                'phpunit:assert-equals "active" $user->getStatus() "User should be active"' => 'Avec message personnalisé',
                'phpunit:assert-equals true $result' => 'Vérifie une valeur booléenne'
            ],
            'tips' => [
                'Utilise == (égalité avec conversion de type)',
                'Pour une égalité stricte, utilisez phpunit:assert-same',
                'Fonctionne avec tous les types: string, int, bool, array, object',
                'Les objets sont comparés par leurs propriétés'
            ],
            'related' => [
                'phpunit:assert-same' => 'Assertion stricte (===)',
                'phpunit:assert-not-equals' => 'Assertion inverse',
                'phpunit:assert-true' => 'Vérifier si une valeur est true'
            ]
        ]);
    }
}
