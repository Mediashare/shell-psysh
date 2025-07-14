#!/bin/bash

# Test script for Performance commands
# Tests PHPUnitBenchmarkCommand, PHPUnitCompareCommand, PHPUnitComparePerformanceCommand

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/test_utils.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Performance Commands"
echo ""

# Test PHPUnitBenchmarkCommand (phpunit:benchmark)
run_test_step "phpunit:benchmark help" \
    "../bin/psysh -c \"phpunit:benchmark --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitCompareCommand (phpunit:compare)
run_test_step "phpunit:compare help" \
    "../bin/psysh -c \"phpunit:compare --help\"" \
    "Usage:" \
    "check_contains"

# Test PHPUnitComparePerformanceCommand (phpunit:compare-performance)
run_test_step "phpunit:compare-performance help" \
    "../bin/psysh -c \"phpunit:compare-performance --help\"" \
    "Usage:" \
    "check_contains"

# Test benchmark with simple function
run_test_step "Benchmark simple function" \
    "../bin/psysh -c \"phpunit:benchmark --function='strlen' --input='Hello World' --iterations=1000\"" \
    "benchmark" \
    "check_contains"

# Test benchmark with custom code
run_test_step "Benchmark custom code" \
    "../bin/psysh -c \"phpunit:benchmark --code='for(\$i=0;\$i<100;\$i++){\$sum+=\$i;}' --iterations=500\"" \
    "benchmark" \
    "check_contains"

# Test performance comparison between two functions
run_test_step "Compare performance of two functions" \
    "../bin/psysh -c \"phpunit:compare --function1='strlen' --function2='mb_strlen' --input='Hello World' --iterations=1000\"" \
    "comparison" \
    "check_contains"

# Test performance comparison with memory usage
run_test_step "Compare performance with memory usage" \
    "../bin/psysh -c \"phpunit:compare-performance --code1='array_fill(0,1000,0)' --code2='range(0,999)' --measure-memory\"" \
    "memory" \
    "check_contains"

# Test benchmark with time limit
run_test_step "Benchmark with time limit" \
    "../bin/psysh -c \"phpunit:benchmark --code='usleep(1000)' --time-limit=5 --iterations=10\"" \
    "benchmark" \
    "check_contains"

# Test performance profiling
run_test_step "Performance profiling" \
    "../bin/psysh -c \"phpunit:benchmark --code='json_encode(range(0,100))' --profile --iterations=100\"" \
    "profile" \
    "check_contains"

# Test performance with different data sizes
run_test_step "Performance with different data sizes" \
    "../bin/psysh -c \"phpunit:compare --function1='serialize' --function2='json_encode' --input='range(0,1000)' --iterations=500\"" \
    "comparison" \
    "check_contains"

# Test combined performance operations
run_test_step "Combined performance operations" \
    "../bin/psysh -c \"phpunit:benchmark --code='md5(\\\"test\\\")' --iterations=1000; phpunit:compare --function1='md5' --function2='sha1' --input='test' --iterations=1000\"" \
    "benchmark" \
    "check_contains"

test_summary
