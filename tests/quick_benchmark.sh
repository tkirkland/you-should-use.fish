#!/bin/bash
# Quick Performance Benchmark for you-should-use Fish Plugin
# This script provides a quick way to verify performance requirements
#
# Requirements:
#   - Startup overhead: <100ms
#   - Per-command latency: <10ms (combined <50ms)
#
# Usage: bash tests/quick_benchmark.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "You Should Use - Quick Performance Test"
echo "========================================"
echo ""
echo "Project directory: $PROJECT_DIR"
echo ""

# Check if fish is available
if ! command -v fish &> /dev/null; then
    echo "ERROR: fish shell is not installed"
    exit 1
fi

echo "Fish version: $(fish --version)"
echo ""

# Benchmark 1: Baseline startup time
echo "--- Baseline Fish Startup Time ---"
echo "Running: time fish -c 'exit'"
echo ""
for i in 1 2 3; do
    echo "Run $i:"
    time fish -c 'exit'
    echo ""
done

# Benchmark 2: Plugin startup time
echo "--- Plugin Startup Time ---"
echo "Running: time fish -c 'source conf.d/you-should-use.fish; exit'"
echo ""
for i in 1 2 3; do
    echo "Run $i:"
    time fish -c "source $PROJECT_DIR/conf.d/you-should-use.fish; exit"
    echo ""
done

# Benchmark 3: Full initialization
echo "--- Full Initialization (with cache) ---"
echo ""
for i in 1 2 3; do
    echo "Run $i:"
    time fish -c "
        for f in $PROJECT_DIR/functions/*.fish
            source \$f
        end
        source $PROJECT_DIR/conf.d/you-should-use.fish
        _ysu_init_cache
        exit
    "
    echo ""
done

echo "========================================"
echo "Quick Benchmark Complete"
echo "========================================"
echo ""
echo "Expected results:"
echo "  - Plugin overhead should be <100ms"
echo "  - Per-command latency should be <10ms"
echo ""
echo "For detailed benchmarks, run:"
echo "  fish tests/test_performance.fish"
