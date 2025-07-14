<?php

namespace Psy\Test\Extended\Command\Config;

use Psy\Extended\Command\Config\PHPUnitCreateCommand;
use Psy\Extended\Model\InteractiveTest;
use Psy\Test\Extended\Command\ExtendedCommandTestCase;

class PHPUnitCreateCommandTest extends ExtendedCommandTestCase
{
    private PHPUnitCreateCommand $command;
    
    protected function setUp(): void
    {
        parent::setUp();
        $this->command = new PHPUnitCreateCommand();
    }
    
    /**
     * Test basic command creation
     */
    public function testCommandBasics()
    {
        $this->assertEquals('phpunit:create', $this->command->getName());
        $this->assertStringContainsString('Création d\'un nouveau test PHPUnit', $this->command->getDescription());
    }
    
    /**
     * Test successful test creation with simple class name
     */
    public function testCreateTestWithSimpleClassName()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'service' => 'UserService'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, '✅ Test créé : UserServiceTest');
        $this->assertOutputContains($tester, 'mode interactif');
        
        // Verify test was created in service
        $phpunitService = $this->serviceManager->getService('phpunit');
        $test = $phpunitService->getTest('UserServiceTest');
        
        $this->assertInstanceOf(InteractiveTest::class, $test);
        $this->assertEquals('UserServiceTest', $test->getTestClassName());
        $this->assertEquals('UserService', $test->getTargetClass());
    }
    
    /**
     * Test creation with namespaced class
     */
    public function testCreateTestWithNamespacedClass()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'service' => 'App\\Service\\EmailService'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, '✅ Test créé : EmailServiceTest');
        
        $phpunitService = $this->serviceManager->getService('phpunit');
        $test = $phpunitService->getTest('EmailServiceTest');
        
        $this->assertEquals('App\\Service\\EmailService', $test->getTargetClass());
    }
    
    /**
     * Test creation with lowercase class name (should be capitalized)
     */
    public function testCreateTestWithLowercaseClassName()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'service' => 'calculator'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, '✅ Test créé : CalculatorTest');
        
        $phpunitService = $this->serviceManager->getService('phpunit');
        $test = $phpunitService->getTest('CalculatorTest');
        
        $this->assertNotNull($test);
        $this->assertEquals('Calculator', $test->getTargetClass());
    }
    
    /**
     * Test complex help output
     */
    public function testComplexHelp()
    {
        $help = $this->command->getComplexHelp();
        
        // Check main sections
        $this->assertStringContainsString('phpunit:create', $help);
        $this->assertStringContainsString('Générateur intelligent de tests PHPUnit', $help);
        
        // Check examples
        $this->assertStringContainsString('App\\Service\\UserService', $help);
        $this->assertStringContainsString('App\\Repository\\ProductRepository', $help);
        $this->assertStringContainsString('App\\Controller\\ApiController', $help);
        
        // Check workflows
        $this->assertStringContainsString('Création TDD', $help);
        $this->assertStringContainsString('Test de service existant', $help);
        
        // Check troubleshooting
        $this->assertStringContainsString('Classe non trouvée', $help);
        $this->assertStringContainsString('composer.json', $help);
    }
    
    /**
     * Test standard help output
     */
    public function testStandardHelp()
    {
        $help = $this->command->getStandardHelp();
        
        $this->assertStringContainsString('Crée un nouveau test PHPUnit', $help);
        $this->assertStringContainsString('Usage: phpunit:create [service]', $help);
    }
    
    /**
     * Test current test is set after creation
     */
    public function testCurrentTestIsSetAfterCreation()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'service' => 'PaymentService'
        ]);
        
        $phpunitService = $this->serviceManager->getService('phpunit');
        $currentTest = $phpunitService->getCurrentTest();
        
        $this->assertNotNull($currentTest);
        $this->assertEquals('PaymentServiceTest', $currentTest->getTestClassName());
    }
    
    /**
     * Test multiple test creations
     */
    public function testMultipleTestCreations()
    {
        $tester = $this->createCommandTester($this->command);
        $phpunitService = $this->serviceManager->getService('phpunit');
        
        // Create first test
        $tester->execute(['service' => 'FirstService']);
        $this->assertCommandSuccess($tester);
        
        // Create second test
        $tester->execute(['service' => 'SecondService']);
        $this->assertCommandSuccess($tester);
        
        // Verify both tests exist
        $firstTest = $phpunitService->getTest('FirstServiceTest');
        $secondTest = $phpunitService->getTest('SecondServiceTest');
        
        $this->assertNotNull($firstTest);
        $this->assertNotNull($secondTest);
        $this->assertNotEquals($firstTest, $secondTest);
        
        // Verify current test is the last one created
        $this->assertEquals('SecondServiceTest', $phpunitService->getCurrentTest()->getTestClassName());
    }
    
    /**
     * Test creation with special characters in class name
     */
    public function testCreateTestWithSpecialCharacters()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'service' => 'My_Special-Service'
        ]);
        
        $this->assertCommandSuccess($tester);
        // The extractClassName method should handle this
        $this->assertOutputContains($tester, 'Test créé');
    }
    
    /**
     * Test validation (if validateArguments returns false)
     */
    public function testValidationFailure()
    {
        // Create a mock command that fails validation
        $command = new class() extends PHPUnitCreateCommand {
            protected function validateArguments($input, $output): bool
            {
                return false;
            }
        };
        
        $tester = $this->createCommandTester($command);
        
        $tester->execute([
            'service' => 'TestService'
        ]);
        
        $this->assertCommandFailure($tester);
    }
}
