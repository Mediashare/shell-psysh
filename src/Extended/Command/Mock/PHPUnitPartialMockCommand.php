<?php

namespace Psy\Extended\Command\Mock;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;use Psy\Extended\Service\PHPUnitMockService;

class PHPUnitPartialMockCommand extends \Psy\Extended\Command\BaseCommand
{
    

    public function __construct()
    {
        parent::__construct('phpunit:partial-mock');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Créer un mock partiel d\'une classe')
            ->addArgument('class', InputArgument::REQUIRED, 'Nom de la classe à mocker')
            ->addArgument('methods', InputArgument::REQUIRED, 'Méthodes à mocker (JSON array)');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $className = $input->getArgument('class');
        $methodsJson = $input->getArgument('methods');
        
        try {
            // Parser les méthodes
            $methods = json_decode($methodsJson, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                $output->writeln($this->formatError("❌ Format JSON invalide pour les méthodes"));
                return 1;
            }
            
            $mockService = $this->mock();
            
            // Créer le mock partiel
            $mockData = $mockService->createPartialMock($className, $methods);
            
            if (!$mockData) {
                $output->writeln($this->formatError("❌ Impossible de créer le mock partiel"));
                return 1;
            }
            
            // Générer le code PHP
            $mockCode = $mockService->generatePartialMockCode($mockData);
            
            // Exécuter le code
            $this->executePhpCode($mockCode);
            
            $output->writeln($this->formatSuccess("✅ Mock partiel créé : {$mockData['variable']}"));
            $output->writeln($this->formatInfo("📋 Classe: {$className}"));
            $output->writeln($this->formatInfo("🔧 Méthodes mockées: " . implode(', ', $methods)));
            
            // Ajouter au test courant si disponible
            $service = $this->phpunit();
            $currentTest = $service->getCurrentTest()?->getTestClassName();
            if ($currentTest) {
                $service->addCodeToTest($currentTest, $mockCode);
                $output->writeln($this->formatInfo("📝 Mock ajouté au test {$currentTest}"));
            }
            
            return 0;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de la création du mock partiel: " . $e->getMessage()));
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
