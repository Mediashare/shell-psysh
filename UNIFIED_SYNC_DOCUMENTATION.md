# Unified Synchronization System Documentation

## Overview

The Unified Synchronization System is a complete refactoring of the variable synchronization workflow in the PsySH Extended shell. It provides a single, unified method for synchronizing variables, historique, classes, functions, and other context between different shell scopes.

## Problem Solved

Previously, the system had multiple, inconsistent synchronization methods:
- `$result = 42` in `phpunit:code` mode was not accessible in the main shell
- Different synchronization strategies for different contexts (shell, eval, sub-shells)
- Complex fallback mechanisms that weren't always reliable
- Difficult debugging of synchronization issues

## New Architecture

### UnifiedSyncService

The core service that handles all synchronization needs:

```php
use Psy\Extended\Service\UnifiedSyncService;

$unifiedSync = UnifiedSyncService::getInstance();
$unifiedSync->setMainShell($shell);
$unifiedSync->setDebug(true); // Enable debug mode
```

### Key Features

1. **Single Source of Truth**: All variables are stored in a unified variable store
2. **Automatic Synchronization**: Variables are automatically synchronized across all contexts
3. **Debug Mode**: Comprehensive debugging support with `--debug` flag
4. **Backward Compatibility**: Works alongside existing ShellSyncService
5. **Persistent Storage**: Variables are persisted to files for reliability

## Usage Examples

### Basic Variable Synchronization

```php
// Set variables in the unified store
$unifiedSync->setVariable('name', 'value');
$unifiedSync->setVariables(['var1' => 'value1', 'var2' => 'value2']);

// Get all variables
$allVars = $unifiedSync->getAllVariables();
```

### Code Execution with Synchronization

```php
$context = [];
$result = $unifiedSync->executeWithSync('$result = 42; return $result;', $context);
// $context now contains all new variables created during execution
```

### Sub-shell Creation and Synchronization

```php
// Create a sub-shell with all variables synchronized
$subShell = $unifiedSync->createSyncedSubShell('phpunit:code> ');

// After using the sub-shell, synchronize back to main shell
$unifiedSync->syncFromSubShell($subShell);
```

## Debug Mode

Debug mode provides detailed logging of all synchronization operations:

```bash
# Enable debug mode for phpunit:code
> phpunit:code --debug

# Enable debug mode for assertions
> phpunit:assert '$result === 42' --debug

# Debug output example:
[DEBUG] Variable 'result' updated in the unified store
[DEBUG] Variables synchronized to the main shell
[DEBUG] Sub-shell created with 5 variables
[DEBUG] 2 variables synchronized from the sub-shell
```

## Command Support

The following commands now support the `--debug` flag:

- `phpunit:code --debug` - Debug mode for code synchronization
- `phpunit:assert <expr> --debug` - Debug mode for assertion synchronization
- More commands will be added as needed

## Implementation Details

### Synchronization Flow

1. **Initialization**: UnifiedSyncService is created as a singleton
2. **Main Shell Setup**: The main shell is registered with the service
3. **Variable Store**: All variables are stored in a unified array
4. **Multi-context Sync**: Variables are synchronized to:
   - Main shell scope
   - Global variables (`$GLOBALS`)
   - Persistent files
   - Specialized contexts (phpunit, etc.)

### File Persistence

Variables are persisted to temporary files for reliability:
- File path: `/tmp/psysh_unified_variables_{PID}.dat`
- Automatic cleanup on service destruction
- Serialized PHP data for type safety

### Backward Compatibility

The system maintains compatibility with existing code:
- Old `ShellSyncService` continues to work
- Existing global variables are preserved
- Gradual migration path for existing code

## Testing

Use the provided test script to verify the synchronization system:

```bash
php test-unified-sync.php
```

This will test:
- Variable synchronization between contexts
- Code execution with automatic sync
- Sub-shell creation and synchronization
- Compatibility with old sync system
- Debug mode functionality

## Troubleshooting

### Common Issues

1. **Variables not synchronizing**
   - Enable debug mode: `--debug`
   - Check that UnifiedSyncService is initialized
   - Verify main shell is properly set

2. **Performance issues**
   - Disable debug mode in production
   - Use `getStats()` to monitor variable store size
   - Clean up with `cleanup()` when done

3. **Compatibility issues**
   - Both old and new sync services can coexist
   - Gradual migration is supported
   - Check global variable conflicts

### Debug Information

Get service statistics:
```php
$stats = $unifiedSync->getStats();
print_r($stats);
```

Sample output:
```php
[
    'total_variables' => 15,
    'has_main_shell' => true,
    'debug_enabled' => true,
    'file_path' => '/tmp/psysh_unified_variables_12345.dat',
    'file_exists' => true
]
```

## Future Enhancements

- **Live Sync**: Real-time synchronization between multiple shells
- **Selective Sync**: Choose which variables to synchronize
- **Performance Monitoring**: Built-in performance metrics
- **Remote Sync**: Synchronization across networked shells
- **Conflict Resolution**: Automatic handling of variable conflicts

## Migration Guide

### From Old Sync System

1. **Gradual Migration**: Keep existing code working while adding new features
2. **Service Initialization**: Initialize UnifiedSyncService alongside ShellSyncService
3. **Command Updates**: Add `--debug` flags to commands as needed
4. **Testing**: Use test scripts to verify synchronization

### Best Practices

1. **Always Initialize**: Set up UnifiedSyncService early in the bootstrap process
2. **Use Debug Mode**: Enable debug mode during development
3. **Clean Up**: Call `cleanup()` when the session ends
4. **Monitor Performance**: Use `getStats()` to monitor variable store size

## Conclusion

The Unified Synchronization System provides a robust, debuggable, and unified approach to variable synchronization across all PsySH Extended contexts. It solves the original problem of variables not being accessible between different shell modes while maintaining backward compatibility and providing enhanced debugging capabilities.

The system is designed to be extensible and can be enhanced with additional features as needed. The debug mode makes it easy to troubleshoot synchronization issues, and the unified approach ensures consistency across all contexts.

<citations>
<document>
<document_type>RULE</document_type>
<document_id>77ENZIfEinIwhGAgXBYEqF</document_id>
</document>
<document>
<document_type>RULE</document_type>
<document_id>8O5lAuEXID0Bos3BwmpP7c</document_id>
</document>
<document>
<document_type>RULE</document_type>
<document_id>qqS8wOCfJtU6whxkUs73nt</document_id>
</document>
<document>
<document_type>RULE</document_type>
<document_id>vBOSlcRfkJrvCIdHGEqTU5</document_id>
</document>
</citations>
