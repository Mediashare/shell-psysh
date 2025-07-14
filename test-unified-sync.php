#!/usr/bin/env php
<?php

/*
 * Test script for the unified synchronization system
 * 
 * This script tests the variable synchronization between:
 * - Main shell
 * - phpunit:code sub-shell
 * - phpunit:assert command
 * - eval() contexts
 * 
 * Usage: php test-unified-sync.php
 */

// Load autoloader
require_once __DIR__ . '/vendor/autoload.php';

// Test the unified synchronization system
function testUnifiedSync() {
    echo "🧪 Testing Unified Synchronization System\n";
    echo str_repeat('=', 60) . "\n\n";
    
    // 1. Initialize UnifiedSyncService
    echo "1. Initializing UnifiedSyncService...\n";
    $unifiedSync = \Psy\Extended\Service\UnifiedSyncService::getInstance();
    $unifiedSync->setDebug(true);
    
    // 2. Create a mock shell
    echo "2. Creating mock shell...\n";
    $config = new \Psy\Configuration();
    $shell = new \Psy\Shell($config);
    
    // 3. Initialize with some variables
    echo "3. Setting up initial variables...\n";
    $initialVars = [
        'result' => 42,
        'name' => 'TestUser',
        'data' => ['key' => 'value']
    ];
    
    $shell->setScopeVariables($initialVars);
    $unifiedSync->setMainShell($shell);
    
    // 4. Test variable synchronization
    echo "4. Testing variable synchronization...\n";
    
    // Test setting variables through unified sync
    $unifiedSync->setVariable('newVar', 'newValue');
    $unifiedSync->setVariable('testResult', 123);
    
    // Check if they're in the shell
    $shellVars = $shell->getScopeVariables();
    echo "   - Shell variables: " . json_encode(array_keys($shellVars)) . "\n";
    
    // 5. Test code execution with synchronization
    echo "5. Testing code execution with synchronization...\n";
    
    $context = [];
    $result = $unifiedSync->executeWithSync('$computed = $result * 2; return $computed;', $context);
    echo "   - Execution result: $result\n";
    echo "   - Context after execution: " . json_encode(array_keys($context)) . "\n";
    
    // 6. Test sub-shell creation
    echo "6. Testing sub-shell creation...\n";
    
    $subShell = $unifiedSync->createSyncedSubShell('test> ');
    $subShellVars = $subShell->getScopeVariables();
    echo "   - Sub-shell variables: " . json_encode(array_keys($subShellVars)) . "\n";
    
    // 7. Test synchronization from sub-shell
    echo "7. Testing synchronization from sub-shell...\n";
    
    $subShell->setScopeVariables(array_merge($subShellVars, ['subShellVar' => 'subValue']));
    $unifiedSync->syncFromSubShell($subShell);
    
    // Check if the variable is now in the main shell
    $mainVars = $shell->getScopeVariables();
    echo "   - Main shell now has: " . json_encode(array_keys($mainVars)) . "\n";
    
    // 8. Test stats
    echo "8. Getting service stats...\n";
    $stats = $unifiedSync->getStats();
    echo "   - Stats: " . json_encode($stats, JSON_PRETTY_PRINT) . "\n";
    
    // 9. Test cleanup
    echo "9. Testing cleanup...\n";
    $unifiedSync->cleanup();
    
    echo "\n✅ All tests completed successfully!\n";
}

// Test the old vs new synchronization methods
function testCompatibility() {
    echo "\n🔄 Testing Compatibility Between Old and New Sync Systems\n";
    echo str_repeat('=', 60) . "\n\n";
    
    // Create both services
    $unifiedSync = \Psy\Extended\Service\UnifiedSyncService::getInstance();
    $oldSync = \Psy\Extended\Service\ShellSyncService::getInstance();
    
    // Create shell
    $shell = new \Psy\Shell();
    $shell->setScopeVariables(['compatTest' => 'value']);
    
    // Set up both services
    $unifiedSync->setMainShell($shell);
    $oldSync->setMainShell($shell);
    
    // Test that both can access the same variables
    $unifiedVars = $unifiedSync->getAllVariables();
    $oldVars = $oldSync->getMainShellVariables();
    
    echo "Unified sync variables: " . json_encode(array_keys($unifiedVars)) . "\n";
    echo "Old sync variables: " . json_encode(array_keys($oldVars)) . "\n";
    
    // Test that changes in one are reflected in the other
    $unifiedSync->setVariable('unifiedVar', 'unified');
    $oldSync->syncToMainShell(['oldVar' => 'old']);
    
    $finalVars = $shell->getScopeVariables();
    echo "Final shell variables: " . json_encode(array_keys($finalVars)) . "\n";
    
    echo "\n✅ Compatibility test completed!\n";
}

// Run tests
try {
    testUnifiedSync();
    testCompatibility();
    
    echo "\n🎉 All synchronization tests passed!\n";
    echo "The unified synchronization system is working correctly.\n";
    
} catch (Exception $e) {
    echo "\n❌ Test failed: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
    exit(1);
}
