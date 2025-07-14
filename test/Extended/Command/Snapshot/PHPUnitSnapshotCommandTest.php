<?php

namespace Psy\Test\Extended\Command\Snapshot;

use Psy\Extended\Command\Snapshot\PHPUnitSnapshotCommand;
use Psy\Test\Extended\Command\ExtendedCommandTestCase;

class PHPUnitSnapshotCommandTest extends ExtendedCommandTestCase
{
    private PHPUnitSnapshotCommand $command;
    
    protected function setUp(): void
    {
        parent::setUp();
        $this->command = new PHPUnitSnapshotCommand();
    }
    
    /**
     * Test basic command properties
     */
    public function testCommandBasics()
    {
        $this->assertEquals('phpunit:snapshot', $this->command->getName());
        $this->assertStringContainsString('Créer un snapshot', $this->command->getDescription());
    }
    
    /**
     * Test creating a simple snapshot
     */
    public function testCreateSimpleSnapshot()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'expression' => '["a", "b", "c"]'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, '📸 Snapshot créé');
        $this->assertOutputContains($tester, '$snapshot_1');
        
        // Verify snapshot was stored in context
        $snapshot = $this->context->get('snapshot_1');
        $this->assertEquals(['a', 'b', 'c'], $snapshot);
    }
    
    /**
     * Test creating snapshot with custom name
     */
    public function testCreateSnapshotWithCustomName()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'expression' => 'range(1, 5)',
            '--name' => 'myNumbers'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, '📸 Snapshot créé');
        $this->assertOutputContains($tester, '$myNumbers');
        
        // Verify custom named snapshot
        $snapshot = $this->context->get('myNumbers');
        $this->assertEquals([1, 2, 3, 4, 5], $snapshot);
    }
    
    /**
     * Test creating snapshot with description
     */
    public function testCreateSnapshotWithDescription()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'expression' => 'new DateTime("2024-01-01")',
            '--desc' => 'New Year 2024'
        ]);
        
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, '📸 Snapshot créé');
        $this->assertOutputContains($tester, 'New Year 2024');
    }
    
    /**
     * Test creating multiple snapshots
     */
    public function testCreateMultipleSnapshots()
    {
        $tester = $this->createCommandTester($this->command);
        
        // First snapshot
        $tester->execute([
            'expression' => '"first value"'
        ]);
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, '$snapshot_1');
        
        // Second snapshot
        $tester->execute([
            'expression' => '"second value"'
        ]);
        $this->assertCommandSuccess($tester);
        $this->assertOutputContains($tester, '$snapshot_2');
        
        // Third snapshot with name
        $tester->execute([
            'expression' => '"third value"',
            '--name' => 'customSnapshot'
        ]);
        $this->assertCommandSuccess($tester);
        
        // Verify all snapshots exist
        $this->assertEquals('first value', $this->context->get('snapshot_1'));
        $this->assertEquals('second value', $this->context->get('snapshot_2'));
        $this->assertEquals('third value', $this->context->get('customSnapshot'));
    }
    
    /**
     * Test snapshot of complex objects
     */
    public function testSnapshotComplexObject()
    {
        $tester = $this->createCommandTester($this->command);
        
        // Create a complex structure
        $tester->execute([
            'expression' => '[
                "users" => [
                    ["id" => 1, "name" => "Alice"],
                    ["id" => 2, "name" => "Bob"]
                ],
                "count" => 2,
                "timestamp" => time()
            ]'
        ]);
        
        $this->assertCommandSuccess($tester);
        
        $snapshot = $this->context->get('snapshot_1');
        $this->assertIsArray($snapshot);
        $this->assertArrayHasKey('users', $snapshot);
        $this->assertCount(2, $snapshot['users']);
    }
    
    /**
     * Test snapshot with expression using context variables
     */
    public function testSnapshotWithContextVariables()
    {
        // Set some context variables
        $this->setShellVariables([
            'baseValue' => 100,
            'multiplier' => 3
        ]);
        
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'expression' => '$baseValue * $multiplier'
        ]);
        
        $this->assertCommandSuccess($tester);
        
        $snapshot = $this->context->get('snapshot_1');
        $this->assertEquals(300, $snapshot);
    }
    
    /**
     * Test snapshot of function result
     */
    public function testSnapshotFunctionResult()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'expression' => 'array_map(function($x) { return $x * $x; }, range(1, 4))',
            '--name' => 'squares'
        ]);
        
        $this->assertCommandSuccess($tester);
        
        $squares = $this->context->get('squares');
        $this->assertEquals([1, 4, 9, 16], $squares);
    }
    
    /**
     * Test error handling for invalid expression
     */
    public function testSnapshotInvalidExpression()
    {
        $tester = $this->createCommandTester($this->command);
        
        $tester->execute([
            'expression' => 'this is not valid PHP'
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
        $this->assertStringContainsString('phpunit:snapshot', $help);
        $this->assertStringContainsString('Description', $help);
        $this->assertStringContainsString('Usage', $help);
        $this->assertStringContainsString('Options', $help);
        $this->assertStringContainsString('Examples', $help);
        
        // Check options
        $this->assertStringContainsString('--name', $help);
        $this->assertStringContainsString('--desc', $help);
        
        // Check examples
        $this->assertStringContainsString('API', $help);
        $this->assertStringContainsString('array_map', $help);
    }
    
    /**
     * Test snapshot with null and empty values
     */
    public function testSnapshotEdgeCases()
    {
        $tester = $this->createCommandTester($this->command);
        
        // Null snapshot
        $tester->execute([
            'expression' => 'null',
            '--name' => 'nullSnapshot'
        ]);
        $this->assertCommandSuccess($tester);
        $this->assertNull($this->context->get('nullSnapshot'));
        
        // Empty array
        $tester->execute([
            'expression' => '[]',
            '--name' => 'emptyArray'
        ]);
        $this->assertCommandSuccess($tester);
        $this->assertEquals([], $this->context->get('emptyArray'));
        
        // Boolean values
        $tester->execute([
            'expression' => 'true',
            '--name' => 'boolTrue'
        ]);
        $this->assertCommandSuccess($tester);
        $this->assertTrue($this->context->get('boolTrue'));
    }
    
    /**
     * Test snapshot naming conflicts
     */
    public function testSnapshotNamingConflict()
    {
        $tester = $this->createCommandTester($this->command);
        
        // Create first snapshot with custom name
        $tester->execute([
            'expression' => '"first"',
            '--name' => 'mySnapshot'
        ]);
        $this->assertCommandSuccess($tester);
        
        // Try to create another with same name (should overwrite)
        $tester->execute([
            'expression' => '"second"',
            '--name' => 'mySnapshot'
        ]);
        $this->assertCommandSuccess($tester);
        
        // Verify the snapshot was overwritten
        $this->assertEquals('second', $this->context->get('mySnapshot'));
    }
}
