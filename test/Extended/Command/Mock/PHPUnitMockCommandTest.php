<?php

namespace Psy\Test\Extended\Command\Mock;

use Psy\Extended\Command\Mock\PHPUnitMockCommand;
use Psy\Test\Extended\Command\ExtendedCommandTestCase;

class PHPUnitMockCommandTest extends ExtendedCommandTestCase
{
    private PHPUnitMockCommand $command;
    
    protected function setUp(): void
    {
        parent::setUp();
        // Définir la constante pour indiquer qu'on est en mode test
        if (!defined('PHPUNIT_TESTSUITE')) {
            define('PHPUNIT_TESTSUITE', true);
        }
        $this->command = new PHPUnitMockCommand();
        $this->initCommand($this->command);
    }
    /**
     * Test basic command properties
     */
    public function testCommandBasics()
    {
        $this->assertEquals('phpunit:mock', $this->command->getName());
        $this->assertStringContainsString('Créer un mock', $this->command->getDescription());
    }
    
    /**
     * Test creating a simple mock
     */
    public function testCreateSimpleMock()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'class' => 'DateTime'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, 'Mock créé');
        $this->assertOutputContains($tester, 'DateTime');
        
        // Check that mock variable was set in context
        $vars = $this->context->getAll();
        $this->assertArrayHasKey('mock', $vars);
        $this->assertNotNull($vars['mock']);
    }
    
    /**
     * Test creating mock with custom variable name
     */
    public function testCreateMockWithCustomVariableName()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'class' => 'ArrayObject',
            '--as' => 'myArrayMock'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, 'myArrayMock');
        
        // Check custom variable name
        $vars = $this->context->getAll();
        $this->assertArrayHasKey('myArrayMock', $vars);
        $this->assertNotNull($vars['myArrayMock']);
    }
    
    /**
     * Test creating mock with methods option
     */
    public function testCreateMockWithMethods()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'class' => 'SplFileInfo',
            '--methods' => 'getFilename,getPath'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, 'Mock créé');
        $this->assertOutputContains($tester, 'getFilename');
        $this->assertOutputContains($tester, 'getPath');
    }
    
    /**
     * Test creating mock with constructor disabled
     */
    public function testCreateMockWithoutConstructor()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'class' => 'Exception',
            '--no-constructor' => true
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, 'sans constructeur');
    }
    
    /**
     * Test creating mock with clone disabled
     */
    public function testCreateMockWithoutClone()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'class' => 'stdClass',
            '--no-clone' => true
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, 'sans clone');
    }
    
    /**
     * Test creating mock with all options
     */
    public function testCreateMockWithAllOptions()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'class' => 'Iterator',
            '--as' => 'iteratorMock',
            '--methods' => 'current,next',
            '--no-constructor' => true,
            '--no-clone' => true
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, 'iteratorMock');
        $this->assertOutputContains($tester, 'current');
        $this->assertOutputContains($tester, 'next');
        $this->assertOutputContains($tester, 'sans constructeur');
        $this->assertOutputContains($tester, 'sans clone');
        
        $vars = $this->context->getAll();
        $this->assertArrayHasKey('iteratorMock', $vars);
    }
    
    /**
     * Test creating mock for interface
     */
    public function testCreateMockForInterface()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'class' => 'Countable'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, 'Mock créé');
        $this->assertOutputContains($tester, 'Countable');
    }
    
    /**
     * Test error when class doesn't exist
     */
    public function testCreateMockForNonExistentClass()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'class' => 'NonExistentClass'
        ]);
        
        $this->assertCommandFailure($tester);
        $this->assertOutputContains($tester, 'Erreur');
    }
    
    /**
     * Test complex help
     */
    public function testComplexHelp()
    {
        $help = $this->command->getComplexHelp();
        
        // Check structure
        $this->assertStringContainsString('phpunit:mock', $help);
        $this->assertStringContainsString('Description', $help);
        $this->assertStringContainsString('Usage', $help);
        $this->assertStringContainsString('Options', $help);
        $this->assertStringContainsString('Examples', $help);
        
        // Check examples
        $this->assertStringContainsString('UserRepository', $help);
        $this->assertStringContainsString('HttpClient', $help);
        
        // Check options
        $this->assertStringContainsString('--as', $help);
        $this->assertStringContainsString('--methods', $help);
        $this->assertStringContainsString('--no-constructor', $help);
    }
    
    /**
     * Test mocking a class in the current test
     */
    public function testMockingInCurrentTest()
    {
        // First create a test
        $createCommand = new \Psy\Extended\Command\Config\PHPUnitCreateCommand();
        $createTester = $this->createCommandTester($createCommand);
        $createTester->execute(['service' => 'TestService']);
        
        // Now create a mock
        $tester = $this->createCommandTester($this->command);
        $tester->execute([
            'class' => 'PDO',
            '--as' => 'dbMock'
        ]);
        
        $this->assertCommandSuccess($tester);
        
        // Verify mock is in context
        $this->assertNotNull($this->context->get('dbMock'));
    }
    
    /**
     * Test creating multiple mocks
     */
    public function testCreateMultipleMocks()
    {
        $tester = $this->createCommandTester($this->command);
        
        // Create first mock
        $tester->execute([
            'class' => 'DateTime',
            '--as' => 'dateMock'
        ]);
        $this->assertCommandSuccess($tester);
        
        // Create second mock
        $tester->execute([
            'class' => 'DateTimeZone',
            '--as' => 'timezoneMock'
        ]);
        $this->assertCommandSuccess($tester);
        
        // Verify both mocks exist
        $vars = $this->context->getAll();
        $this->assertArrayHasKey('dateMock', $vars);
        $this->assertArrayHasKey('timezoneMock', $vars);
        $this->assertNotNull($vars['dateMock']);
        $this->assertNotNull($vars['timezoneMock']);
    }
}
