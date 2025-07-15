#!/bin/bash

# Test script for Config commands
# Tests PHPUnitConfigCommand, PHPUnitCreateCommand, PHPUnitExportCommand, etc.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Config Commands"
echo ""

# Test PHPUnitConfigCommand (phpunit:config)
echo "🔍 Testing phpunit:config command..."
echo "$PROJECT_RO$PROJECT_ROOT/bin/psysh -c \"phpunit:config --show\""
$PROJECT_RO$PROJECT_ROOT/bin/psysh -c "phpunit:config --show"
echo ""

# Test PHPUnitCreateCommand (phpunit:create)
echo "🔍 Testing phpunit:create command..."
echo "$PROJECT_RO$PROJECT_ROOT/bin/psysh -c \"phpunit:create TestClass --type=class --namespace=Tests\""
$PROJECT_RO$PROJECT_ROOT/bin/psysh -c "phpunit:create TestClass --type=class --namespace=Tests"
echo ""

# Test PHPUnitExportCommand (phpunit:export)
echo "🔍 Testing phpunit:export command..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:export --format=json --output=temp_export.json\""
$PROJECT_ROOT/bin/psysh -c "phpunit:export --format=json --output=temp_export.json"
echo ""

# Test PHPUnitListCommand (phpunit:list)
echo "🔍 Testing phpunit:list command..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:list\""
$PROJECT_ROOT/bin/psysh -c "phpunit:list"
echo ""

# Test PHPUnitListProjectCommand (phpunit:list-project)
echo "🔍 Testing phpunit:list-project command..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:list-project\""
$PROJECT_ROOT/bin/psysh -c "phpunit:list-project"
echo ""

# Test PHPUnitHelpCommand (phpunit:help)
echo "🔍 Testing phpunit:help command..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:help\""
$PROJECT_ROOT/bin/psysh -c "phpunit:help"
echo ""

# Test PHPUnitHelpCommand with specific command
echo "🔍 Testing phpunit:help with specific command..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:help phpunit:assert\""
$PROJECT_ROOT/bin/psysh -c "phpunit:help phpunit:assert"
echo ""

# Test PHPUnitCodeCommand (phpunit:code)
echo "🔍 Testing phpunit:code command..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:code --show-config\""
$PROJECT_ROOT/bin/psysh -c "phpunit:code --show-config"
echo ""

# Test PHPUnitTempConfigCommand (phpunit:temp-config)
echo "🔍 Testing phpunit:temp-config command..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:temp-config --create\""
$PROJECT_ROOT/bin/psysh -c "phpunit:temp-config --create"
echo ""

# Test PHPUnitRestoreConfigCommand (phpunit:restore-config)
echo "🔍 Testing phpunit:restore-config command..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:restore-config --backup-file=phpunit.xml.backup\""
$PROJECT_ROOT/bin/psysh -c "phpunit:restore-config --backup-file=phpunit.xml.backup"
echo ""

# Test CustomHelpCommand (custom:help)
echo "🔍 Testing custom:help command..."
echo "$PROJECT_ROOT/bin/psysh -c \"custom:help\""
$PROJECT_ROOT/bin/psysh -c "custom:help"
echo ""

# Test combined config operations
echo "🔍 Testing combined config operations..."
echo "$PROJECT_ROOT/bin/psysh -c \"phpunit:config --show; phpunit:list; phpunit:help\""
$PROJECT_ROOT/bin/psysh -c "phpunit:config --show; phpunit:list; phpunit:help"
echo ""

test_summary
