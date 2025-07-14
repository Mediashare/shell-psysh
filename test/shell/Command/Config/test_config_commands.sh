#!/bin/bash

# Test script for Config commands
# Tests PHPUnitConfigCommand, PHPUnitCreateCommand, PHPUnitExportCommand, etc.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/test_utils.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Config Commands"
echo ""

# Test PHPUnitConfigCommand (phpunit:config)
echo "🔍 Testing phpunit:config command..."
echo "../bin/psysh -c \"phpunit:config --show\""
../bin/psysh -c "phpunit:config --show"
echo ""

# Test PHPUnitCreateCommand (phpunit:create)
echo "🔍 Testing phpunit:create command..."
echo "../bin/psysh -c \"phpunit:create TestClass --type=class --namespace=Tests\""
../bin/psysh -c "phpunit:create TestClass --type=class --namespace=Tests"
echo ""

# Test PHPUnitExportCommand (phpunit:export)
echo "🔍 Testing phpunit:export command..."
echo "../bin/psysh -c \"phpunit:export --format=json --output=temp_export.json\""
../bin/psysh -c "phpunit:export --format=json --output=temp_export.json"
echo ""

# Test PHPUnitListCommand (phpunit:list)
echo "🔍 Testing phpunit:list command..."
echo "../bin/psysh -c \"phpunit:list\""
../bin/psysh -c "phpunit:list"
echo ""

# Test PHPUnitListProjectCommand (phpunit:list-project)
echo "🔍 Testing phpunit:list-project command..."
echo "../bin/psysh -c \"phpunit:list-project\""
../bin/psysh -c "phpunit:list-project"
echo ""

# Test PHPUnitHelpCommand (phpunit:help)
echo "🔍 Testing phpunit:help command..."
echo "../bin/psysh -c \"phpunit:help\""
../bin/psysh -c "phpunit:help"
echo ""

# Test PHPUnitHelpCommand with specific command
echo "🔍 Testing phpunit:help with specific command..."
echo "../bin/psysh -c \"phpunit:help phpunit:assert\""
../bin/psysh -c "phpunit:help phpunit:assert"
echo ""

# Test PHPUnitCodeCommand (phpunit:code)
echo "🔍 Testing phpunit:code command..."
echo "../bin/psysh -c \"phpunit:code --show-config\""
../bin/psysh -c "phpunit:code --show-config"
echo ""

# Test PHPUnitTempConfigCommand (phpunit:temp-config)
echo "🔍 Testing phpunit:temp-config command..."
echo "../bin/psysh -c \"phpunit:temp-config --create\""
../bin/psysh -c "phpunit:temp-config --create"
echo ""

# Test PHPUnitRestoreConfigCommand (phpunit:restore-config)
echo "🔍 Testing phpunit:restore-config command..."
echo "../bin/psysh -c \"phpunit:restore-config --backup-file=phpunit.xml.backup\""
../bin/psysh -c "phpunit:restore-config --backup-file=phpunit.xml.backup"
echo ""

# Test CustomHelpCommand (custom:help)
echo "🔍 Testing custom:help command..."
echo "../bin/psysh -c \"custom:help\""
../bin/psysh -c "custom:help"
echo ""

# Test combined config operations
echo "🔍 Testing combined config operations..."
echo "../bin/psysh -c \"phpunit:config --show; phpunit:list; phpunit:help\""
../bin/psysh -c "phpunit:config --show; phpunit:list; phpunit:help"
echo ""

test_summary
