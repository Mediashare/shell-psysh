#!/bin/bash

# Test script for Performance commands
# Tests PHPUnitBenchmarkCommand, PHPUnitCompareCommand, PHPUnitComparePerformanceCommand

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Performance Commands"
echo ""

# Test PHPUnitBenchmarkCommand (phpunit:benchmark)
    --step "phpunit:benchmark --help" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:benchmark help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "Usage:" \
    --output-check contains

# Test PHPUnitCompareCommand (phpunit:compare)
    --step "phpunit:compare --help" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:compare help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "Usage:" \
    --output-check contains

# Test PHPUnitComparePerformanceCommand (phpunit:compare-performance)
    --step "phpunit:compare-performance --help" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "phpunit:compare-performance help" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "Usage:" \
    --output-check contains

# Test benchmark with simple function
    --step "phpunit:benchmark --function='strlen' --input='Hello World' --iterations=1000" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Benchmark simple function" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "benchmark" \
    --output-check contains

# Test benchmark with custom code
    "test_session_sync "Test command" --step \"phpunit:benchmark --code='for(\$i=0;\$i<100;\$i++){\$sum+=\$i;}' --iterations=500\"" \
test_session_sync "Benchmark custom code" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "benchmark" \
    --output-check contains

# Test performance comparison between two functions
    --step "phpunit:compare --function1='strlen' --function2='mb_strlen' --input='Hello World' --iterations=1000" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Compare performance of two functions" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "comparison" \
    --output-check contains

# Test performance comparison with memory usage
    --step "phpunit:compare-performance --code1='array_fill(0,1000,0)' --code2='range(0,999)' --measure-memory" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Compare performance with memory usage" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "memory" \
    --output-check contains

# Test benchmark with time limit
    --step "phpunit:benchmark --code='usleep(1000)' --time-limit=5 --iterations=10" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Benchmark with time limit" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "benchmark" \
    --output-check contains

# Test performance profiling
    --step "phpunit:benchmark --code='json_encode(range(0,100))' --profile --iterations=100" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Performance profiling" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "profile" \
    --output-check contains

# Test performance with different data sizes
    --step "phpunit:compare --function1='serialize' --function2='json_encode' --input='range(0,1000)' --iterations=500" \ --context psysh --output-check contains --tag "phpunit_session"
test_session_sync "Performance with different data sizes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "comparison" \
    --output-check contains

# Test combined performance operations
    "test_session_sync "Test command" --step \"phpunit:benchmark --code='md5("test")' --iterations=1000; phpunit:compare --function1='md5' --function2='sha1' --input='test' --iterations=1000\"" \
test_session_sync "Combined performance operations" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    "benchmark" \
    --output-check contains

test_summary
