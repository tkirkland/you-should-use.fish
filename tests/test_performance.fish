#!/usr/bin/env fish
# Performance Benchmark Test for you-should-use Fish Plugin
# Tests: Startup time overhead and per-command latency
#
# Run with: fish tests/test_performance.fish
# Requirements: Plugin overhead <100ms startup, <10ms per-command

set -l script_dir (dirname (status filename))
set -l project_dir (dirname $script_dir)

# Test result tracking
set -g _test_passed 0
set -g _test_failed 0
set -g _test_skipped 0

# Benchmark configuration
set -g BENCHMARK_ITERATIONS 5
set -g STARTUP_THRESHOLD_MS 100
set -g COMMAND_THRESHOLD_MS 10

# Test helpers
function test_begin --description "Start a test section"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    set_color --bold cyan
    echo "BENCHMARK: $argv[1]"
    set_color normal
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
end

function test_pass --description "Mark test as passed"
    set _test_passed (math $_test_passed + 1)
    set_color --bold green
    echo "  ✓ PASS: $argv[1]"
    set_color normal
end

function test_fail --description "Mark test as failed"
    set _test_failed (math $_test_failed + 1)
    set_color --bold red
    echo "  ✗ FAIL: $argv[1]"
    set_color normal
end

function test_skip --description "Mark test as skipped"
    set _test_skipped (math $_test_skipped + 1)
    set_color --bold yellow
    echo "  ⊘ SKIP: $argv[1]"
    set_color normal
end

function test_info --description "Print test info"
    set_color yellow
    echo "  → $argv[1]"
    set_color normal
end

function test_result --description "Print benchmark result"
    set_color cyan
    echo "  ⏱ $argv[1]"
    set_color normal
end

function test_summary --description "Print test summary"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    set_color --bold
    echo "BENCHMARK SUMMARY"
    set_color normal
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    set_color green
    echo "  Passed:  $_test_passed"
    set_color red
    echo "  Failed:  $_test_failed"
    set_color yellow
    echo "  Skipped: $_test_skipped"
    set_color normal
    echo ""
    if test $_test_failed -eq 0
        set_color --bold green
        echo "All performance benchmarks passed! ✓"
        set_color normal
    else
        set_color --bold red
        echo "Some performance benchmarks failed. ✗"
        set_color normal
        return 1
    end
end

# Get current time in milliseconds (Fish 3.4+)
function get_time_ms --description "Get current time in milliseconds"
    # Use date command for millisecond precision
    date +%s%3N
end

# Calculate average of a list of numbers
function calc_average --description "Calculate average of numbers"
    set -l sum 0
    set -l count 0
    for num in $argv
        set sum (math "$sum + $num")
        set count (math $count + 1)
    end
    if test $count -gt 0
        math "$sum / $count"
    else
        echo 0
    end
end

# Calculate min of a list of numbers
function calc_min --description "Calculate minimum of numbers"
    set -l min $argv[1]
    for num in $argv[2..-1]
        if test (math "$num < $min") -eq 1
            set min $num
        end
    end
    echo $min
end

# Calculate max of a list of numbers
function calc_max --description "Calculate maximum of numbers"
    set -l max $argv[1]
    for num in $argv[2..-1]
        if test (math "$num > $max") -eq 1
            set max $num
        end
    end
    echo $max
end

# ==============================================================================
# BENCHMARK 1: Baseline Fish Startup Time
# ==============================================================================

test_begin "Baseline Fish Startup Time (without plugin)"

test_info "Running $BENCHMARK_ITERATIONS iterations..."
set -l baseline_times

for i in (seq $BENCHMARK_ITERATIONS)
    set -l start (get_time_ms)
    fish -c 'exit' 2>/dev/null
    set -l end (get_time_ms)
    set -l duration (math "$end - $start")
    set -a baseline_times $duration
    test_info "Iteration $i: {$duration}ms"
end

set -g baseline_avg (calc_average $baseline_times)
set -g baseline_min (calc_min $baseline_times)
set -g baseline_max (calc_max $baseline_times)

test_result "Baseline - Average: {$baseline_avg}ms, Min: {$baseline_min}ms, Max: {$baseline_max}ms"
test_pass "Baseline measurement complete"

# ==============================================================================
# BENCHMARK 2: Plugin Startup Time
# ==============================================================================

test_begin "Plugin Startup Time (with plugin loaded)"

test_info "Running $BENCHMARK_ITERATIONS iterations..."
set -l plugin_times

for i in (seq $BENCHMARK_ITERATIONS)
    set -l start (get_time_ms)
    fish -c "source $project_dir/conf.d/you-should-use.fish; exit" 2>/dev/null
    set -l end (get_time_ms)
    set -l duration (math "$end - $start")
    set -a plugin_times $duration
    test_info "Iteration $i: {$duration}ms"
end

set -g plugin_avg (calc_average $plugin_times)
set -g plugin_min (calc_min $plugin_times)
set -g plugin_max (calc_max $plugin_times)

test_result "With Plugin - Average: {$plugin_avg}ms, Min: {$plugin_min}ms, Max: {$plugin_max}ms"

# Calculate overhead
set -g overhead_avg (math "$plugin_avg - $baseline_avg")
set -g overhead_min (math "$plugin_min - $baseline_min")
set -g overhead_max (math "$plugin_max - $baseline_max")

test_result "Overhead - Average: {$overhead_avg}ms, Min: {$overhead_min}ms, Max: {$overhead_max}ms"

# Check if overhead is acceptable
if test (math "$overhead_avg < $STARTUP_THRESHOLD_MS") -eq 1
    test_pass "Startup overhead ({$overhead_avg}ms avg) is below threshold ({$STARTUP_THRESHOLD_MS}ms)"
else
    test_fail "Startup overhead ({$overhead_avg}ms avg) exceeds threshold ({$STARTUP_THRESHOLD_MS}ms)"
end

# ==============================================================================
# BENCHMARK 3: Full Plugin Initialization (with cache)
# ==============================================================================

test_begin "Full Plugin Initialization (with cache build)"

test_info "Running $BENCHMARK_ITERATIONS iterations with cache initialization..."
set -l init_times

for i in (seq $BENCHMARK_ITERATIONS)
    set -l start (get_time_ms)
    fish -c "
        for f in $project_dir/functions/*.fish
            source \$f
        end
        source $project_dir/conf.d/you-should-use.fish
        _ysu_init_cache
        exit
    " 2>/dev/null
    set -l end (get_time_ms)
    set -l duration (math "$end - $start")
    set -a init_times $duration
    test_info "Iteration $i: {$duration}ms"
end

set -l init_avg (calc_average $init_times)
set -l init_overhead (math "$init_avg - $baseline_avg")

test_result "Full Init - Average: {$init_avg}ms, Overhead: {$init_overhead}ms"

if test (math "$init_overhead < $STARTUP_THRESHOLD_MS") -eq 1
    test_pass "Full initialization overhead ({$init_overhead}ms) is below threshold ({$STARTUP_THRESHOLD_MS}ms)"
else
    test_fail "Full initialization overhead ({$init_overhead}ms) exceeds threshold ({$STARTUP_THRESHOLD_MS}ms)"
end

# ==============================================================================
# BENCHMARK 4: Per-Command Detection Latency
# ==============================================================================

test_begin "Per-Command Detection Latency"

# First, source all plugin files for this test
test_info "Loading plugin files..."
for f in $project_dir/functions/*.fish
    source $f 2>/dev/null
end
source $project_dir/conf.d/you-should-use.fish 2>/dev/null

# Initialize cache
_ysu_init_cache

# Set up test abbreviation
abbr -a _ysu_perf_test 'git status' 2>/dev/null

# Refresh cache to pick up test abbreviation
_ysu_refresh_abbr_cache

test_info "Measuring alias check latency ($BENCHMARK_ITERATIONS iterations)..."
set -l alias_times

for i in (seq $BENCHMARK_ITERATIONS)
    set -l start (get_time_ms)
    _ysu_check_aliases "ls -la" 2>/dev/null
    set -l end (get_time_ms)
    set -l duration (math "$end - $start")
    set -a alias_times $duration
end

set -l alias_avg (calc_average $alias_times)
test_result "Alias check - Average: {$alias_avg}ms"

if test (math "$alias_avg < $COMMAND_THRESHOLD_MS") -eq 1
    test_pass "Alias check latency ({$alias_avg}ms) is below threshold ({$COMMAND_THRESHOLD_MS}ms)"
else
    test_fail "Alias check latency ({$alias_avg}ms) exceeds threshold ({$COMMAND_THRESHOLD_MS}ms)"
end

test_info "Measuring abbreviation check latency ($BENCHMARK_ITERATIONS iterations)..."
set -l abbr_times

for i in (seq $BENCHMARK_ITERATIONS)
    set -l start (get_time_ms)
    _ysu_check_abbreviations "git status" 2>/dev/null
    set -l end (get_time_ms)
    set -l duration (math "$end - $start")
    set -a abbr_times $duration
end

set -l abbr_avg (calc_average $abbr_times)
test_result "Abbreviation check - Average: {$abbr_avg}ms"

if test (math "$abbr_avg < $COMMAND_THRESHOLD_MS") -eq 1
    test_pass "Abbreviation check latency ({$abbr_avg}ms) is below threshold ({$COMMAND_THRESHOLD_MS}ms)"
else
    test_fail "Abbreviation check latency ({$abbr_avg}ms) exceeds threshold ({$COMMAND_THRESHOLD_MS}ms)"
end

test_info "Measuring git alias check latency ($BENCHMARK_ITERATIONS iterations)..."
set -l git_times

for i in (seq $BENCHMARK_ITERATIONS)
    set -l start (get_time_ms)
    _ysu_check_git_aliases "git status" 2>/dev/null
    set -l end (get_time_ms)
    set -l duration (math "$end - $start")
    set -a git_times $duration
end

set -l git_avg (calc_average $git_times)
test_result "Git alias check - Average: {$git_avg}ms"

if test (math "$git_avg < $COMMAND_THRESHOLD_MS") -eq 1
    test_pass "Git alias check latency ({$git_avg}ms) is below threshold ({$COMMAND_THRESHOLD_MS}ms)"
else
    test_fail "Git alias check latency ({$git_avg}ms) exceeds threshold ({$COMMAND_THRESHOLD_MS}ms)"
end

# Clean up test abbreviation
abbr -e _ysu_perf_test 2>/dev/null

# ==============================================================================
# BENCHMARK 5: Combined Preexec Handler Latency
# ==============================================================================

test_begin "Combined Preexec Handler Latency"

test_info "Measuring full preexec handler latency ($BENCHMARK_ITERATIONS iterations)..."
set -l preexec_times

for i in (seq $BENCHMARK_ITERATIONS)
    set -l start (get_time_ms)
    # Simulate what _ysu_on_preexec does
    _ysu_check_aliases "git commit -m 'test'" 2>/dev/null
    _ysu_check_abbreviations "git commit -m 'test'" 2>/dev/null
    _ysu_check_git_aliases "git commit -m 'test'" 2>/dev/null
    set -l end (get_time_ms)
    set -l duration (math "$end - $start")
    set -a preexec_times $duration
end

set -l preexec_avg (calc_average $preexec_times)
set -l preexec_min (calc_min $preexec_times)
set -l preexec_max (calc_max $preexec_times)

test_result "Preexec Handler - Average: {$preexec_avg}ms, Min: {$preexec_min}ms, Max: {$preexec_max}ms"

# Combined latency should still be well under perceptible threshold (50ms)
set -l combined_threshold 50
if test (math "$preexec_avg < $combined_threshold") -eq 1
    test_pass "Combined preexec latency ({$preexec_avg}ms) is below perceptible threshold ({$combined_threshold}ms)"
else
    test_fail "Combined preexec latency ({$preexec_avg}ms) exceeds perceptible threshold ({$combined_threshold}ms)"
end

# ==============================================================================
# BENCHMARK 6: Cache Size and Memory
# ==============================================================================

test_begin "Cache Statistics"

# Report cache sizes
set -l abbr_count (count $_ysu_abbr_keys 2>/dev/null; or echo 0)
set -l alias_count (count $_ysu_alias_names 2>/dev/null; or echo 0)
set -l git_count (count $_ysu_git_alias_keys 2>/dev/null; or echo 0)

test_result "Abbreviation cache entries: $abbr_count"
test_result "Function alias cache entries: $alias_count"
test_result "Git alias cache entries: $git_count"

set -l total_cache (math "$abbr_count + $alias_count + $git_count")
test_result "Total cached entries: $total_cache"

# Cache shouldn't be empty (at least system functions should be cached)
if test $alias_count -gt 0
    test_pass "Function alias cache is populated"
else
    test_fail "Function alias cache is empty"
end

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
set_color --bold magenta
echo "PERFORMANCE SUMMARY"
set_color normal
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Startup Times:"
echo "    • Baseline (vanilla Fish):    {$baseline_avg}ms average"
echo "    • With plugin sourced:        {$plugin_avg}ms average"
echo "    • Overhead:                   {$overhead_avg}ms average"
echo ""
echo "  Per-Command Latency:"
echo "    • Alias check:                {$alias_avg}ms"
echo "    • Abbreviation check:         {$abbr_avg}ms"
echo "    • Git alias check:            {$git_avg}ms"
echo "    • Combined (all three):       {$preexec_avg}ms"
echo ""
echo "  Cache Statistics:"
echo "    • Abbreviations:              $abbr_count entries"
echo "    • Function aliases:           $alias_count entries"
echo "    • Git aliases:                $git_count entries"
echo ""

# Overall verdict
if test (math "$overhead_avg < $STARTUP_THRESHOLD_MS") -eq 1; and test (math "$preexec_avg < $combined_threshold") -eq 1
    set_color --bold green
    echo "  ✓ PERFORMANCE REQUIREMENTS MET"
    echo "    Startup overhead < 100ms: YES ({$overhead_avg}ms)"
    echo "    Per-command latency < 50ms: YES ({$preexec_avg}ms)"
    set_color normal
else
    set_color --bold red
    echo "  ✗ PERFORMANCE REQUIREMENTS NOT MET"
    if test (math "$overhead_avg >= $STARTUP_THRESHOLD_MS") -eq 1
        echo "    Startup overhead >= 100ms: {$overhead_avg}ms"
    end
    if test (math "$preexec_avg >= $combined_threshold") -eq 1
        echo "    Per-command latency >= 50ms: {$preexec_avg}ms"
    end
    set_color normal
end
echo ""

test_summary
