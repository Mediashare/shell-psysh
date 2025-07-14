<?php

namespace Psy\Extended\Command\Other;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;use Psy\Extended\Service\PHPUnitMockService;

class PHPUnitCallOriginalCommand extends \Psy\Extended\Command\BaseCommand
{
    

    public function __construct()
    {
        parent::__construct('phpunit:call-original');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Configurer un mock pour appeler la méthode originale')
            ->addArgument('expression', InputArgument::REQUIRED, 'Expression du mock (ex: $mock->method())');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $expression = $input->getArgument('expression');
        
        try {
            $mockService = $this->mock();
            
            // Parser l'expression pour extraire le mock et la méthode
            $parsedExpression = $mockService->parseMethodExpression($expression);
            
            if (!$parsedExpression) {
                $output->writeln($this->formatError("❌ Format d'expression invalide"));
                $output->writeln($this->formatInfo("💡 Format attendu: \$mock->method()"));
                return 1;
            }
            
            // Générer le code pour appeler la méthode originale
            $originalCallCode = $mockService->generateCallOriginalCode($parsedExpression);
            
            // Exécuter le code
            $this->executePhpCode($originalCallCode);
            
            $output->writeln($this->formatSuccess("✅ Configuration pour appeler la méthode originale"));
            $output->writeln($this->formatInfo("📋 Expression: {$expression}"));
            
            // Ajouter au test courant si disponible
            $currentTest = $this->getCurrentTest();
            if ($currentTest) {
                $service = $this->phpunit();
                $service->addCodeToTest($currentTest, $originalCallCode);
                $output->writeln($this->formatInfo("📝 Configuration ajoutée au test {$currentTest}"));
            }
            
            return 0;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de la configuration: " . $e->getMessage()));
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
