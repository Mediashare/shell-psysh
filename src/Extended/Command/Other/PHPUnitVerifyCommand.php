<?php

namespace Psy\Extended\Command\Other;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;use Psy\Extended\Service\PHPUnitMockService;

class PHPUnitVerifyCommand extends \Psy\Extended\Command\BaseCommand
{
    

    public function __construct()
    {
        parent::__construct('phpunit:verify');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Vérifier les appels sur un mock')
            ->addArgument('verification', InputArgument::REQUIRED, 'Vérification à effectuer (ex: $mock->method()->wasCalledTimes(2))');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Validation automatique des arguments
        if (!$this->validateArguments($input, $output)) {
            return 2;
        }

        $verification = $input->getArgument('verification');
        
        try {
            $mockService = $this->mock();
            
            // Parser la vérification
            $parsedVerification = $mockService->parseVerification($verification);
            
            if (!$parsedVerification) {
                $output->writeln($this->formatError("❌ Format de vérification invalide"));
                $output->writeln($this->formatInfo("💡 Format attendu: \$mock->method()->wasCalledTimes(2)"));
                return 1;
            }
            
            // Effectuer la vérification
            $verificationResult = $mockService->performVerification($parsedVerification);
            
            if ($verificationResult['success']) {
                $output->writeln($this->formatSuccess("✅ Vérification réussie"));
                $output->writeln($this->formatInfo("📋 {$verification}"));
                if (isset($verificationResult['details'])) {
                    $output->writeln($this->formatInfo("📊 " . $verificationResult['details']));
                }
            } else {
                $output->writeln($this->formatError("❌ Vérification échouée"));
                $output->writeln($this->formatError("📋 {$verification}"));
                if (isset($verificationResult['reason'])) {
                    $output->writeln($this->formatError("💭 " . $verificationResult['reason']));
                }
            }
            
            // Ajouter au test courant si disponible
            $currentTest = $this->getCurrentTest();
            if ($currentTest) {
                $service = $this->phpunit();
                $verificationCode = $mockService->generateVerificationCode($parsedVerification);
                $service->addCodeToTest($currentTest, $verificationCode);
                $output->writeln($this->formatInfo("📝 Vérification ajoutée au test {$currentTest}"));
            }
            
            return $verificationResult['success'] ? 0 : 1;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de la vérification: " . $e->getMessage()));
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
