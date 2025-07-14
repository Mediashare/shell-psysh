<?php

namespace Psy\Test\Extended\Command\Assert;

use Psy\Extended\Command\Assert\PHPUnitAssertCommand;
use Psy\Extended\Command\Config\PHPUnitCreateCommand;
use Psy\Test\Extended\Command\ExtendedCommandTestCase;

class PHPUnitAssertCommandTest extends ExtendedCommandTestCase
{
    private PHPUnitAssertCommand $command;
    
    protected function setUp(): void
    {
        parent::setUp();
        $this->command = new PHPUnitAssertCommand();
        
        // Create a test context
        $createCommand = new PHPUnitCreateCommand();
        $createTester = $this->createCommandTester($createCommand);
        $createTester->execute(['service' => 'TestService']);
    }
    
    /**
     * Test basic command properties
     */
    public function testCommandBasics()
    {
        $this->assertEquals('phpunit:assert', $this->command->getName());
        $this->assertStringContainsString('Exécuter une assertion PHPUnit', $this->command->getDescription());
    }
    
    /**
     * Test simple assertion
     */
    public function testSimpleAssertion()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'expression' => '5 == 5'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, '✅');
        $this->assertOutputContains($tester, 'Assertion réussie');
    }
    
    /**
     * Test assertion with custom message
     */
    public function testAssertionWithMessage()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'expression' => 'true',
            '--message' => 'This should always pass'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, '✅');
        $this->assertOutputContains($tester, 'Assertion réussie');
    }
    
    /**
     * Test multiple assertions
     */
    public function testMultipleAssertions()
    {
        // Set some variables in context BEFORE creating the tester
        $this->setShellVariables([
            'result' => 'some value',
            'data' => ['a', 'b', 'c'],
            'items' => [1, 2, 3]
        ]);
        
        $tester = $this->createCommandTester($this->command);
        
        // First assertion
        $tester->execute([
            'expression' => '$result !== null'
        ]);
        $this->assertCommandSuccess($tester);
        
        // Second assertion
        $tester->execute([
            'expression' => 'is_array($data)'
        ]);
        $this->assertCommandSuccess($tester);
        
        // Third assertion
        $tester->execute([
            'expression' => 'count($items) === 3'
        ]);
        $this->assertCommandSuccess($tester);
        
        // Note: The current implementation doesn't actually add assertions to the test
        // it just validates them. So we just verify that all assertions passed.
    }
    
    /**
     * Test common assertion types
     */
    public function testCommonAssertionTypes()
    {
        $tester = $this->createCommandTester($this->command);
        
        $assertions = [
            '1 == 1',
            '"test" === "test"',
            'true',
            '!false',
            'null === null',
            '"value" !== null',
            'is_string("text")',
            'is_int(42)',
            'is_array([])',
            '(new \DateTime()) instanceof \DateTime',
            '10 > 5',
            '5 < 10',
            'strpos("hello world", "world") !== false',
            'count([]) === 0',
            'empty([])',
            '!empty([1])'
        ];
        
        foreach ($assertions as $assertion) {
            $tester->execute(['expression' => $assertion]);
            $this->assertCommandSuccess($tester);
            $this->assertOutputContains($tester, '✅');
        }
    }
    
    /**
     * Test assertion without quotes
     */
    public function testAssertionWithoutQuotes()
    {
        $tester = $this->createCommandTester($this->command);
        
        // Should work without $this-> prefix
        $tester->execute([
            'expression' => '10 == 10'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, '✅');
    }
    
    /**
     * Test assertion with variables from context
     */
    public function testAssertionWithContextVariables()
    {
        // Set some variables in context BEFORE creating the tester
        $this->setShellVariables([
            'testVar' => 'test value',
            'testNum' => 42,
            'testArray' => [1, 2, 3]
        ]);
        
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'expression' => '$testVar === "test value"'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, '✅');
    }
    
    /**
     * Test complex help
     */
    public function testComplexHelp()
    {
        $help = $this->command->getComplexHelp();
        
        // Check structure
        $this->assertStringContainsString('phpunit:assert', $help);
        $this->assertStringContainsString('Description', $help);
        $this->assertStringContainsString('Usage', $help);
        $this->assertStringContainsString('Examples', $help);
        
        // Check examples
        $this->assertStringContainsString('equals', $help);
        $this->assertStringContainsString('true', $help);
        $this->assertStringContainsString('count', $help);
        
        // Check tips
        $this->assertStringContainsString('variables PsySH', $help);
    }
    
    /**
     * Test assertion in specific test method
     */
    public function testAssertionInSpecificMethod()
    {
        // Set some variables in context BEFORE creating the tester
        $this->setShellVariables([
            'data' => ['test', 'data']
        ]);
        
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'expression' => '!empty($data)',
            '--method' => 'testDataNotEmpty'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, 'testDataNotEmpty');
    }
    
    /**
     * Test error handling for invalid assertion
     */
    public function testInvalidAssertion()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'expression' => 'this is not valid PHP code'
        ]);
        
        $this->assertCommandFailure($tester);
        $this->assertOutputContains($tester, 'Erreur');
    }
    
    /**
     * Test assertion with multiline code
     */
    public function testMultilineAssertion()
    {
        $tester = $this->createCommandTester($this->command);
        
        $assertion = '$expected = ["a", "b", "c"]; $result = ["a", "b", "c"]; $expected === $result';
        
        $tester->execute([
            'expression' => $assertion
        ]);
        
        $this->assertCommandSuccess($tester);
    }
    
    /**
     * Test adding setup code before assertion
     */
    public function testAssertionWithSetupCode()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'expression' => '$calculatedValue > 100',
            '--setup' => '$calculatedValue = 50 * 3'
        ]);
        
        $this->assertCommandSuccess($tester);
    }
}
