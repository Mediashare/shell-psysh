<?php

namespace Psy\Test\Extended\Command\Runner;

use Psy\Extended\Command\Runner\PsyshMonitorCommand;
use Psy\Test\Extended\Command\ExtendedCommandTestCase;

class PsyshMonitorCommandTest extends ExtendedCommandTestCase
{
    private PsyshMonitorCommand $command;
    
    protected function setUp(): void
    {
        parent::setUp();
        $this->command = new PsyshMonitorCommand();
    }
    
    /**
     * Test basic command properties
     */
    public function testCommandBasics()
    {
        $this->assertEquals('monitor', $this->command->getName());
        $this->assertStringContainsString("Monitor code execution", $this->command->getDescription());
    }
    
    /**
     * Test monitoring simple code execution
     */
    public function testMonitorSimpleCode()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'code' => '$x = 5 + 3'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, 'Monitoring');
        
        // The code execution should complete
        $this->assertOutputContains($tester, 'Execution completed successfully');
    }
    
    /**
     * Test monitoring with time option
     */
    public function testMonitorWithTimeOption()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'code' => 'usleep(1000)',
            '--time' => true
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputMatches($tester, '/Temps.*:.*m?s/');
    }
    
    /**
     * Test monitoring with memory option
     */
    public function testMonitorWithMemoryOption()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'code' => '$arr = range(1, 1000)',
            '--memory' => true
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputMatches($tester, '/Mémoire.*:.*[KM]?B/');
    }
    
    /**
     * Test monitoring with variables option
     */
    public function testMonitorWithVariablesOption()
    {
        // Set some initial variables
        $this->setShellVariables([
            'foo' => 'bar',
            'num' => 42
        ]);
        
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'code' => '$foo = "changed"; $new = "value"',
            '--vars' => true
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, 'Variables modifiées');
        $this->assertOutputContains($tester, '$foo');
        $this->assertOutputContains($tester, '$new');
    }
    
    /**
     * Test monitoring with all options enabled
     */
    public function testMonitorWithAllOptions()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'code' => '$result = array_map(function($x) { return $x * 2; }, range(1, 10))',
            '--time' => true,
            '--memory' => true,
            '--vars' => true
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, 'Monitoring');
        $this->assertOutputMatches($tester, '/Temps.*:/');
        $this->assertOutputMatches($tester, '/Mémoire.*:/');
        $this->assertOutputContains($tester, '$result');
    }
    
    /**
     * Test monitoring code that throws exception
     */
    public function testMonitorCodeWithException()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'code' => 'throw new Exception("Test error")'
        ]);
        
        $this->assertCommandFailure($tester);
        $this->assertOutputContains($tester, 'Error');
        $this->assertOutputContains($tester, 'Test error');
    }
    
    /**
     * Test monitoring multi-line code
     */
    public function testMonitorMultiLineCode()
    {
        $tester = $this->createCommandTester($this->command);
        
        $code = '$sum = 0;
for ($i = 1; $i <= 5; $i++) {
    $sum += $i;
}';
        
        $tester->execute([
            'code' => $code,
            '--time' => true
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, 'Execution completed successfully');
    }
    
    /**
     * Test monitoring function calls
     */
    public function testMonitorFunctionCalls()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'code' => '$result = strlen("hello world")',
            '--vars' => true
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, '$result');
    }
    
    /**
     * Test complex help
     */
    public function testComplexHelp()
    {
        $helpArray = $this->command->getComplexHelp();
        $this->assertIsArray($helpArray);
        
        // Check structure
        $this->assertArrayHasKey('description', $helpArray);
        $this->assertArrayHasKey('usage', $helpArray);
        $this->assertArrayHasKey('options', $helpArray);
        $this->assertArrayHasKey('examples', $helpArray);
        
        // Check content
        $this->assertStringContainsString('monitoring', $helpArray['description']);
        $this->assertIsArray($helpArray['usage']);
        $this->assertIsArray($helpArray['options']);
        $this->assertIsArray($helpArray['examples']);
        
        // Check options
        $this->assertArrayHasKey('--time (-t)', $helpArray['options']);
        $this->assertArrayHasKey('--memory (-m)', $helpArray['options']);
        $this->assertArrayHasKey('--vars (-v)', $helpArray['options']);
        
        // Check examples
        $examples = array_keys($helpArray['examples']);
        $this->assertContains('monitor "for ($i=0; $i<10; $i++) { echo $i; }"', $examples);
    }
    
    /**
     * Test monitoring heavy computation
     */
    public function testMonitorHeavyComputation()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'code' => '$data = array_fill(0, 1000, "test")',
            '--memory' => true,
            '--time' => true
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputMatches($tester, '/Temps.*:/');
        $this->assertOutputMatches($tester, '/Mémoire.*:/');
    }
    
    /**
     * Test monitoring with existing variables modification
     */
    public function testMonitorVariableModifications()
    {
        // Set initial state
        $this->setShellVariables([
            'counter' => 0,
            'message' => 'initial'
        ]);
        
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'code' => '$counter++; $message = "updated"; $newVar = true',
            '--vars' => true
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, 'Variables modifiées');
        $this->assertOutputContains($tester, '$counter');
        $this->assertOutputContains($tester, '$message');
        $this->assertOutputContains($tester, '$newVar');
    }
}
