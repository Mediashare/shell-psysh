#!/bin/bash
# Script to run Extended Commands and Services tests

echo "🧪 Running PsySH Extended Tests..."
echo "================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if PHPUnit is installed
if ! command -v vendor/bin/phpunit &> /dev/null; then
    echo -e "${RED}❌ PHPUnit not found. Please run: composer require --dev phpunit/phpunit${NC}"
    exit 1
fi

# Create test directories if they don't exist
mkdir -p test/Extended/Command/Config
mkdir -p test/Extended/Command/Mock
mkdir -p test/Extended/Command/Runner
mkdir -p test/Extended/Command/Assert
mkdir -p test/Extended/Service

# Run different test suites
echo -e "${YELLOW}1. Running Extended Commands Tests...${NC}"
vendor/bin/phpunit -c phpunit-extended.xml --testsuite="Extended Commands"
COMMANDS_RESULT=$?

echo ""
echo -e "${YELLOW}2. Running Extended Services Tests...${NC}"
vendor/bin/phpunit -c phpunit-extended.xml --testsuite="Extended Services"
SERVICES_RESULT=$?

echo ""
echo -e "${YELLOW}3. Running All Extended Tests with Coverage...${NC}"
vendor/bin/phpunit -c phpunit-extended.xml --coverage-text

# Summary
echo ""
echo "================================="
echo "📊 Test Summary:"
echo "================================="

if [ $COMMANDS_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ Extended Commands Tests: PASSED${NC}"
else
    echo -e "${RED}❌ Extended Commands Tests: FAILED${NC}"
fi

if [ $SERVICES_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ Extended Services Tests: PASSED${NC}"
else
    echo -e "${RED}❌ Extended Services Tests: FAILED${NC}"
fi

echo ""

# Exit with failure if any tests failed
if [ $COMMANDS_RESULT -ne 0 ] || [ $SERVICES_RESULT -ne 0 ]; then
    exit 1
fi

echo -e "${GREEN}🎉 All Extended Tests Passed!${NC}"
exit 0
