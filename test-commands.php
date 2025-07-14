#!/usr/bin/env php
<?php

/*
 * Test script for PsySH Enhanced Commands
 * 
 * Usage: php test-commands.php
 */

// Update autoloader first
echo "🔄 Updating composer autoloader...\n";
system('composer dump-autoload');

// Load autoloader
require_once __DIR__ . '/vendor/autoload.php';

// Create a simple test configuration
$config = new \Psy\Configuration();

// Create shell instance
echo "\n📋 Creating PsySH shell instance...\n";
$shell = new \Psy\Shell($config);

// List all available commands
echo "\n📋 Available commands:\n";
$commands = $shell->all();
foreach ($commands as $name => $command) {
    $className = get_class($command);
    $isExtended = str_contains($className, 'Extended');
    $marker = $isExtended ? '✨' : '  ';
    echo "{$marker} {$name} ({$className})\n";
}

// Count extended commands
$extendedCommands = array_filter($commands, function($cmd) {
    return str_contains(get_class($cmd), 'Extended');
});
echo "\n✅ Found " . count($extendedCommands) . " extended commands.\n";

// Test the autoload command
echo "\n🧪 Testing 'autoload' command...\n";
try {
    // Create a mock input/output for testing
    $input = new \Symfony\Component\Console\Input\ArrayInput(['command' => 'autoload']);
    $output = new \Symfony\Component\Console\Output\BufferedOutput();
    
    if ($shell->has('autoload')) {
        $autoloadCommand = $shell->get('autoload');
        $exitCode = $autoloadCommand->run($input, $output);
        
        echo "Exit code: $exitCode\n";
        echo "Output:\n" . $output->fetch() . "\n";
    } else {
        echo "❌ 'autoload' command not found!\n";
    }
} catch (\Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}

echo "\n✅ Test complete!\n";
echo "To start the enhanced shell, run: bin/psysh\n";
