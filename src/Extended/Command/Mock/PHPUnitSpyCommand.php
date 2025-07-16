<?php

namespace Psy\Extended\Command\Mock;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;use Psy\Extended\Service\PHPUnitMockService;

class PHPUnitSpyCommand extends \Psy\Extended\Command\BaseCommand
{
    

    public function __construct()
    {
        parent::__construct('phpunit:spy');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Activer l\'espionnage sur un mock')
            ->addArgument('mock', InputArgument::REQUIRED, 'Variable du mock à espionner (ex: $repository)');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $mockVariable = $input->getArgument('mock');
        
        try {
            $mockService = $this->mock();
            
            // Valider la variable du mock
            if (!preg_match('/^\$[a-zA-Z_][a-zA-Z0-9_]*$/', $mockVariable)) {
                $output->writeln($this->formatError("❌ Format de variable invalide"));
                $output->writeln($this->formatInfo("💡 Format attendu: \$variableName"));
                return 1;
            }
            
            // Activer l'espionnage
            $spyResult = $mockService->enableSpy($mockVariable);
            
            if ($spyResult['success']) {
                $output->writeln($this->formatSuccess("✅ Espionnage activé sur {$mockVariable}"));
                $output->writeln($this->formatInfo("📊 Les appels de méthodes seront enregistrés"));
                
                // Ajouter au test courant si disponible
                $service = $this->phpunit();
                $currentTest = $service->getCurrentTest()?->getTestClassName();
                if ($currentTest) {
                    $spyCode = $mockService->generateSpyCode($mockVariable);
                    $service->addCodeToTest($currentTest, $spyCode);
                    $output->writeln($this->formatInfo("📝 Espionnage ajouté au test {$currentTest}"));
                }
            } else {
                $output->writeln($this->formatError("❌ Impossible d'activer l'espionnage"));
                if (isset($spyResult['reason'])) {
                    $output->writeln($this->formatError("💭 " . $spyResult['reason']));
                }
            }
            
            return $spyResult['success'] ? 0 : 1;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de l'activation de l'espionnage: " . $e->getMessage()));
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
