#!/usr/bin/env fish
# Test script for you-should-use Fish plugin - Alias Detection Types
# Tests: Regular aliases (functions), Abbreviations, and Git aliases
#
# Run with: fish tests/test_alias_detection.fish
# Or source the plugin first and then run individual tests

set -l script_dir (dirname (status filename))
set -l project_dir (dirname $script_dir)

# Test result tracking
set -g _test_passed 0
set -g _test_failed 0
set -g _test_skipped 0

# Test helpers
function test_begin --description "Start a test section"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    set_color --bold cyan
    echo "TEST: $argv[1]"
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

function test_summary --description "Print test summary"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    set_color --bold
    echo "TEST SUMMARY"
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
        echo "All tests passed! ✓"
        set_color normal
    else
        set_color --bold red
        echo "Some tests failed. ✗"
        set_color normal
        return 1
    end
end

# Cleanup function for test aliases/abbreviations
function cleanup_test_artifacts --description "Remove test artifacts"
    # Remove test abbreviations
    abbr -e _ysu_test_gs 2>/dev/null
    abbr -e _ysu_test_gp 2>/dev/null
    abbr -e _ysu_test_ll 2>/dev/null

    # Remove test functions
    functions -e _ysu_test_ll 2>/dev/null
    functions -e _ysu_test_gst 2>/dev/null

    # Remove test git aliases (only if in a git repo)
    if git rev-parse --git-dir >/dev/null 2>&1
        git config --local --unset alias._ysu_test_st 2>/dev/null
        git config --local --unset alias._ysu_test_co 2>/dev/null
    end
end

# ==============================================================================
# SETUP: Source plugin files
# ==============================================================================

test_begin "Setup - Loading Plugin Files"

# Source all the functions
set -l load_success true

for func_file in $project_dir/functions/*.fish
    set -l func_name (basename $func_file .fish)
    if source $func_file 2>/dev/null
        test_info "Loaded: $func_name"
    else
        test_fail "Failed to load: $func_name"
        set load_success false
    end
end

# Source the main entry point
if source $project_dir/conf.d/you-should-use.fish 2>/dev/null
    test_info "Loaded: conf.d/you-should-use.fish"
else
    test_fail "Failed to load: conf.d/you-should-use.fish"
    set load_success false
end

if test $load_success = true
    test_pass "All plugin files loaded successfully"
else
    test_fail "Some plugin files failed to load"
end

# ==============================================================================
# TEST 1: Cache Initialization
# ==============================================================================

test_begin "Cache Initialization"

# Initialize the cache
_ysu_init_cache

if set -q _ysu_cache_initialized
    test_pass "Cache initialized flag set"
else
    test_fail "Cache not initialized"
end

if set -q _ysu_abbr_keys
    test_info "Abbreviation cache: "(count $_ysu_abbr_keys)" entries"
    test_pass "Abbreviation cache created"
else
    test_fail "Abbreviation cache not created"
end

if set -q _ysu_alias_names
    test_info "Function alias cache: "(count $_ysu_alias_names)" entries"
    test_pass "Function alias cache created"
else
    test_fail "Function alias cache not created"
end

if set -q _ysu_git_alias_keys
    test_info "Git alias cache: "(count $_ysu_git_alias_keys)" entries"
    test_pass "Git alias cache created"
else
    test_fail "Git alias cache not created"
end

# ==============================================================================
# TEST 2: Abbreviation Detection
# ==============================================================================

test_begin "Abbreviation Detection"

# Clean up any existing test artifacts
cleanup_test_artifacts

# Set up test abbreviation
test_info "Setting up test abbreviation: _ysu_test_gs -> 'git status'"
abbr -a _ysu_test_gs 'git status'

# Reinitialize cache to pick up new abbreviation
_ysu_init_cache

# Check if abbreviation is in cache
if contains _ysu_test_gs $_ysu_abbr_keys
    test_pass "Abbreviation cached correctly"
else
    test_fail "Abbreviation not found in cache"
    test_info "Cache keys: $_ysu_abbr_keys"
end

# Test detection - capture stderr output
test_info "Testing detection of 'git status' command..."
set -l output (_ysu_check_abbreviations "git status" 2>&1)

if string match -q '*_ysu_test_gs*' "$output"; or string match -q '*git status*' "$output"
    test_pass "Abbreviation detection works - suggested '_ysu_test_gs'"
    test_info "Output: $output"
else
    test_fail "Abbreviation not detected for 'git status'"
    test_info "Output was: $output"
end

# Test that already using the abbreviation doesn't trigger reminder
test_info "Testing that using the abbreviation doesn't re-trigger..."
set output (_ysu_check_abbreviations "_ysu_test_gs" 2>&1)

if test -z "$output"
    test_pass "No reminder when using abbreviation directly"
else
    test_fail "Incorrectly reminded when using abbreviation"
    test_info "Output: $output"
end

# Clean up
abbr -e _ysu_test_gs 2>/dev/null

# ==============================================================================
# TEST 3: Function Alias Detection
# ==============================================================================

test_begin "Function Alias (Regular) Detection"

# Clean up any existing test artifacts
cleanup_test_artifacts

# Set up test function alias
test_info "Setting up test function: _ysu_test_ll -> 'ls -la'"
function _ysu_test_ll --description "Test alias for ls -la"
    ls -la $argv
end

# Reinitialize cache to pick up new function
_ysu_init_cache

# Check if function is in cache
if contains _ysu_test_ll $_ysu_alias_names
    test_pass "Function alias cached correctly"
else
    test_fail "Function alias not found in cache"
end

# Find the value in the cache
set -l idx 1
for name in $_ysu_alias_names
    if test "$name" = _ysu_test_ll
        test_info "Cached value: $_ysu_alias_values[$idx]"
        break
    end
    set idx (math $idx + 1)
end

# Test detection
test_info "Testing detection of 'ls -la' command..."
set -l output (_ysu_check_aliases "ls -la" 2>&1)

if string match -q '*_ysu_test_ll*' "$output"; or string match -q '*ls -la*' "$output"
    test_pass "Function alias detection works - suggested '_ysu_test_ll'"
    test_info "Output: $output"
else
    test_fail "Function alias not detected for 'ls -la'"
    test_info "Output was: $output"
    test_info "Note: Function body parsing may need adjustment"
end

# Clean up
functions -e _ysu_test_ll 2>/dev/null

# ==============================================================================
# TEST 4: Git Alias Detection
# ==============================================================================

test_begin "Git Alias Detection"

# Check if we're in a git repository
if not git rev-parse --git-dir >/dev/null 2>&1
    test_skip "Not in a git repository - skipping git alias tests"
else
    # Clean up any existing test artifacts
    cleanup_test_artifacts

    # Set up test git alias
    test_info "Setting up test git alias: _ysu_test_st -> 'status'"
    git config --local alias._ysu_test_st status

    # Reinitialize cache to pick up new git alias
    _ysu_init_cache

    # Check if git alias is in cache
    if contains _ysu_test_st $_ysu_git_alias_keys
        test_pass "Git alias cached correctly"
    else
        test_fail "Git alias not found in cache"
        test_info "Git alias keys: $_ysu_git_alias_keys"
    end

    # Test detection
    test_info "Testing detection of 'git status' command..."
    set -l output (_ysu_check_git_aliases "git status" 2>&1)

    if string match -q '*_ysu_test_st*' "$output"; or string match -q '*git _ysu_test_st*' "$output"
        test_pass "Git alias detection works - suggested 'git _ysu_test_st'"
        test_info "Output: $output"
    else
        test_fail "Git alias not detected for 'git status'"
        test_info "Output was: $output"
    end

    # Test that non-git commands don't trigger git alias detection
    test_info "Testing that non-git commands don't trigger detection..."
    set output (_ysu_check_git_aliases "ls -la" 2>&1)

    if test -z "$output"
        test_pass "Non-git commands correctly ignored"
    else
        test_fail "Non-git command incorrectly triggered git alias detection"
        test_info "Output: $output"
    end

    # Clean up
    git config --local --unset alias._ysu_test_st 2>/dev/null
end

# ==============================================================================
# TEST 5: sudo Commands Should Be Skipped
# ==============================================================================

test_begin "sudo Commands Handling"

# Set up test abbreviation
abbr -a _ysu_test_gp 'git push'
_ysu_init_cache

# Test that sudo commands are skipped
test_info "Testing that sudo commands are skipped..."
set -l output (_ysu_check_abbreviations "sudo git push" 2>&1)

if test -z "$output"
    test_pass "sudo commands correctly skipped for abbreviations"
else
    test_fail "sudo command incorrectly triggered abbreviation detection"
    test_info "Output: $output"
end

set output (_ysu_check_aliases "sudo ls -la" 2>&1)
if test -z "$output"
    test_pass "sudo commands correctly skipped for function aliases"
else
    test_fail "sudo command incorrectly triggered function alias detection"
end

set output (_ysu_check_git_aliases "sudo git status" 2>&1)
if test -z "$output"
    test_pass "sudo commands correctly skipped for git aliases"
else
    test_fail "sudo command incorrectly triggered git alias detection"
end

# Clean up
abbr -e _ysu_test_gp 2>/dev/null

# ==============================================================================
# TEST 6: Ignored Aliases
# ==============================================================================

test_begin "Ignored Aliases"

# Set up test abbreviation
abbr -a _ysu_test_gs 'git status'
_ysu_init_cache

# Add to ignore list
set -g YSU_IGNORED_GLOBAL_ALIASES _ysu_test_gs

# Test that ignored abbreviation is not suggested
test_info "Testing that ignored abbreviation is not suggested..."
set -l output (_ysu_check_abbreviations "git status" 2>&1)

# The output should NOT contain our test abbreviation since it's ignored
if not string match -q '*_ysu_test_gs*' "$output"
    test_pass "Ignored abbreviation correctly skipped"
else
    test_fail "Ignored abbreviation was incorrectly suggested"
    test_info "Output: $output"
end

# Clean up
set -e YSU_IGNORED_GLOBAL_ALIASES
abbr -e _ysu_test_gs 2>/dev/null

# ==============================================================================
# TEST 7: Event Handlers Registered
# ==============================================================================

test_begin "Event Handlers"

if functions -q _ysu_on_preexec
    test_pass "_ysu_on_preexec handler registered"
else
    test_fail "_ysu_on_preexec handler not found"
end

if functions -q _ysu_on_prompt
    test_pass "_ysu_on_prompt handler registered"
else
    test_fail "_ysu_on_prompt handler not found"
end

if functions -q _ysu_on_postexec
    test_pass "_ysu_on_postexec handler registered (for cache refresh)"
else
    test_fail "_ysu_on_postexec handler not found"
end

# ==============================================================================
# TEST 8: Message Formatting
# ==============================================================================

test_begin "Message Formatting"

# Test default message format
test_info "Testing default message format..."
set -l output (_ysu_message "alias" "git status" "gs" 2>&1)

if string match -q '*alias*' "$output"; and string match -q '*git status*' "$output"; and string match -q '*gs*' "$output"
    test_pass "Default message format works"
    test_info "Output: $output"
else
    test_fail "Default message format failed"
    test_info "Output: $output"
end

# Test custom message format
test_info "Testing custom message format..."
set -g YSU_MESSAGE_FORMAT "Use '%alias' instead of '%command' (type: %alias_type)"
set output (_ysu_message "abbreviation" "git push" "gp" 2>&1)

if string match -q "*Use 'gp' instead of 'git push' (type: abbreviation)*" "$output"
    test_pass "Custom message format works"
    test_info "Output: $output"
else
    test_fail "Custom message format failed"
    test_info "Output: $output"
end

# Clean up
set -e YSU_MESSAGE_FORMAT

# ==============================================================================
# FINAL CLEANUP
# ==============================================================================

test_begin "Cleanup"

cleanup_test_artifacts
test_info "Test artifacts cleaned up"
test_pass "Cleanup complete"

# ==============================================================================
# SUMMARY
# ==============================================================================

test_summary
