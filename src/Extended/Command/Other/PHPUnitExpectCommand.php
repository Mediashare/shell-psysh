<?php

namespace Psy\Extended\Command\Other;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;use Psy\Extended\Service\PHPUnitMockService;

class PHPUnitExpectCommand extends \Psy\Extended\Command\BaseCommand
{
    

    public function __construct()
    {
        parent::__construct('phpunit:expect');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Configurer les expectations d\'un mock')
            ->addArgument('expectation', InputArgument::REQUIRED, 'Expression d\'expectation (ex: $mock->method()->willReturn($value))');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $expectation = $input->getArgument('expectation');
        
        try {
            $mockService = $this->mock();
            
            // Parser et valider l'expectation
            $parsedExpectation = $mockService->parseExpectation($expectation);
            
            if (!$parsedExpectation) {
                $output->writeln($this->formatError("❌ Format d'expectation invalide"));
                $output->writeln($this->formatInfo("💡 Format attendu: \$mock->method()->willReturn(\$value)"));
                return 1;
            }
            
            // Exécuter l'expectation
            $this->executePhpCode($expectation . ';');
            
            $output->writeln($this->formatSuccess("✅ Expectation configurée"));
            $output->writeln($this->formatInfo("📋 Expectation: {$expectation}"));
            
            // Ajouter au test courant si disponible
            $currentTest = $this->getCurrentTest();
            if ($currentTest) {
                $service = $this->phpunit();
                $service->addCodeToTest($currentTest, $expectation . ';');
                $output->writeln($this->formatInfo("📝 Expectation ajoutée au test {$currentTest}"));
            }
            
            // Enregistrer l'expectation pour le suivi
            $mockService->recordExpectation($parsedExpectation);
            
            return 0;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de la configuration de l'expectation: " . $e->getMessage()));
            return 1;
        }
    }
    
    protected function getMockService(): PHPUnitMockService
    {
        if (!isset($GLOBALS['phpunit_mock_service'])) {
            $GLOBALS['phpunit_mock_service'] = new PHPUnitMockService();
        }
        return $GLOBALS['phpunit_mock_service'];
    }

    public function getComplexHelp(): array
    {
        return [
            "description" => $this->getDescription(),
            "usage" => [$this->getName()],
            "examples" => []
        ];
    }}
