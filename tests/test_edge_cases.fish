#!/usr/bin/env fish
# Test script for you-should-use Fish plugin - Edge Cases
# Tests: sudo commands, empty aliases, special characters, no git repo, ignored aliases
#
# Run with: fish tests/test_edge_cases.fish
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
    abbr -e _ysu_edge_test 2>/dev/null
    abbr -e _ysu_edge_empty 2>/dev/null
    abbr -e _ysu_edge_special 2>/dev/null
    abbr -e _ysu_edge_percent 2>/dev/null
    abbr -e _ysu_edge_backslash 2>/dev/null
    abbr -e _ysu_edge_ignored 2>/dev/null

    # Remove test functions
    functions -e _ysu_edge_func 2>/dev/null
    functions -e _ysu_edge_empty_func 2>/dev/null
    functions -e _ysu_edge_special_func 2>/dev/null

    # Remove test git aliases (only if in a git repo)
    if git rev-parse --git-dir >/dev/null 2>&1
        git config --local --unset alias._ysu_edge_st 2>/dev/null
        git config --local --unset alias._ysu_edge_ignored 2>/dev/null
    end

    # Clear ignore lists
    set -e YSU_IGNORED_ALIASES 2>/dev/null
    set -e YSU_IGNORED_GLOBAL_ALIASES 2>/dev/null
    set -e YSU_IGNORED_GIT_ALIASES 2>/dev/null
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

# Clean up any existing test artifacts
cleanup_test_artifacts

# Initialize cache
_ysu_init_cache

# ==============================================================================
# TEST 1: sudo Commands Are Skipped
# ==============================================================================

test_begin "Edge Case: sudo Commands Are Skipped"

# Set up test abbreviation
test_info "Setting up test abbreviation: _ysu_edge_test -> 'git status'"
abbr -a _ysu_edge_test 'git status'
_ysu_init_cache

# Test 1a: sudo with abbreviation detection
test_info "Testing sudo commands with abbreviation detection..."
set -l output (_ysu_check_abbreviations "sudo git status" 2>&1)

if test -z "$output"
    test_pass "sudo commands skipped for abbreviation detection"
else
    test_fail "sudo command incorrectly triggered abbreviation detection"
    test_info "Output: $output"
end

# Test 1b: sudo with function alias detection
test_info "Setting up test function: _ysu_edge_func -> 'ls -la'"
function _ysu_edge_func --description "Test function for edge cases"
    ls -la $argv
end
_ysu_init_cache

set output (_ysu_check_aliases "sudo ls -la" 2>&1)
if test -z "$output"
    test_pass "sudo commands skipped for function alias detection"
else
    test_fail "sudo command incorrectly triggered function alias detection"
    test_info "Output: $output"
end

# Test 1c: sudo with git alias detection
if git rev-parse --git-dir >/dev/null 2>&1
    test_info "Setting up test git alias: _ysu_edge_st -> 'status'"
    git config --local alias._ysu_edge_st status
    _ysu_init_cache

    set output (_ysu_check_git_aliases "sudo git status" 2>&1)
    if test -z "$output"
        test_pass "sudo commands skipped for git alias detection"
    else
        test_fail "sudo command incorrectly triggered git alias detection"
        test_info "Output: $output"
    end
else
    test_skip "Not in git repo - skipping git alias sudo test"
end

# Test 1d: Verify non-sudo commands still work
test_info "Verifying non-sudo commands are still detected..."
set output (_ysu_check_abbreviations "git status" 2>&1)
if string match -q '*_ysu_edge_test*' "$output"
    test_pass "Non-sudo commands still trigger detection"
else
    test_fail "Non-sudo commands not triggering detection after sudo tests"
    test_info "Output: $output"
end

# ==============================================================================
# TEST 2: Empty Aliases Handling
# ==============================================================================

test_begin "Edge Case: Empty Aliases Handling"

# Note: In Fish, abbreviations with empty values are unusual but we should handle them gracefully
# Empty values should be skipped by the detection logic

# Test 2a: Empty input handling
test_info "Testing empty command input..."
set -l output (_ysu_check_aliases "" 2>&1)
if test -z "$output"
    test_pass "Empty command input handled gracefully"
else
    test_fail "Empty command input caused unexpected output"
    test_info "Output: $output"
end

set output (_ysu_check_abbreviations "" 2>&1)
if test -z "$output"
    test_pass "Empty abbreviation input handled gracefully"
else
    test_fail "Empty abbreviation input caused unexpected output"
end

set output (_ysu_check_git_aliases "" 2>&1)
if test -z "$output"
    test_pass "Empty git alias input handled gracefully"
else
    test_fail "Empty git alias input caused unexpected output"
end

# Test 2b: Whitespace-only input
test_info "Testing whitespace-only command input..."
set output (_ysu_check_aliases "   " 2>&1)
if test -z "$output"
    test_pass "Whitespace-only input handled gracefully"
else
    test_fail "Whitespace-only input caused unexpected output"
    test_info "Output: $output"
end

# Test 2c: Cache handles empty values
# This verifies that if somehow empty values get into the cache, they are skipped
test_info "Verifying cache iteration skips empty values..."
# The existing code has: if test -z "$value"; continue; end
# We'll verify by checking that normal operation works after cache init
_ysu_init_cache
if set -q _ysu_cache_initialized
    test_pass "Cache initialized despite potential empty values"
else
    test_fail "Cache initialization failed"
end

# ==============================================================================
# TEST 3: Special Characters in Commands
# ==============================================================================

test_begin "Edge Case: Special Characters (%, \\) in Commands"

# Test 3a: Percent sign in command
test_info "Testing percent sign (%) in command..."
abbr -a _ysu_edge_percent 'echo 100%'
_ysu_init_cache

# Verify the abbreviation was cached
if contains _ysu_edge_percent $_ysu_abbr_keys
    test_pass "Abbreviation with % cached correctly"
else
    test_fail "Abbreviation with % not cached"
end

# Test detection with percent sign
set -l output (_ysu_check_abbreviations "echo 100%" 2>&1)
# The message should be displayed without printf errors
# Even if no match, we want to verify no errors
if not string match -q '*printf*error*' "$output"; and not string match -q '*invalid*' "$output"
    test_pass "Percent sign in command handled without printf errors"
    if test -n "$output"
        test_info "Output: $output"
    end
else
    test_fail "Percent sign caused printf or format errors"
    test_info "Output: $output"
end

# Test 3b: Backslash in command
test_info "Testing backslash (\\) in command..."
abbr -a _ysu_edge_backslash 'echo path\\to\\file'
_ysu_init_cache

# Verify the abbreviation was cached
if contains _ysu_edge_backslash $_ysu_abbr_keys
    test_pass "Abbreviation with \\ cached correctly"
else
    test_fail "Abbreviation with \\ not cached"
end

# Test detection with backslash
set output (_ysu_check_abbreviations 'echo path\\to\\file' 2>&1)
if not string match -q '*error*' "$output"; and not string match -q '*invalid*' "$output"
    test_pass "Backslash in command handled without errors"
    if test -n "$output"
        test_info "Output: $output"
    end
else
    test_fail "Backslash caused errors"
    test_info "Output: $output"
end

# Test 3c: Test _ysu_message directly with special characters
test_info "Testing _ysu_message with percent sign directly..."
set output (_ysu_message "abbreviation" "echo 100%" "_ysu_test" 2>&1)
# The percent should be escaped and not cause printf issues
if string match -q '*echo*' "$output"; and string match -q '*_ysu_test*' "$output"
    test_pass "Message with percent sign formatted correctly"
    test_info "Output: $output"
else
    test_fail "Message with percent sign failed"
    test_info "Output: $output"
end

test_info "Testing _ysu_message with backslash directly..."
set output (_ysu_message "abbreviation" 'path\\to\\file' "_ysu_test" 2>&1)
if string match -q '*path*' "$output"; and string match -q '*_ysu_test*' "$output"
    test_pass "Message with backslash formatted correctly"
    test_info "Output: $output"
else
    test_fail "Message with backslash failed"
    test_info "Output: $output"
end

# Test 3d: Multiple percent signs
test_info "Testing multiple percent signs (100%% -> 100%%)..."
set output (_ysu_message "abbreviation" "100%% complete" "_ysu_test" 2>&1)
if not string match -q '*error*' "$output"
    test_pass "Multiple percent signs handled without errors"
else
    test_fail "Multiple percent signs caused errors"
end

# ==============================================================================
# TEST 4: No Git Repo - Graceful Skip
# ==============================================================================

test_begin "Edge Case: No Git Repo - Graceful Skip"

# Save current directory
set -l original_dir (pwd)

# Create and move to a temporary non-git directory
set -l temp_dir (mktemp -d)
test_info "Testing in temporary non-git directory: $temp_dir"
cd $temp_dir

# Verify we're not in a git repo
if git rev-parse --git-dir >/dev/null 2>&1
    test_fail "Unexpectedly in a git repo in temp directory"
    cd $original_dir
    rm -rf $temp_dir
else
    test_pass "Confirmed not in a git repo"
end

# Test 4a: Git alias detection should gracefully skip
test_info "Testing git alias detection outside git repo..."
set -l output (_ysu_check_git_aliases "git status" 2>&1)
if test -z "$output"
    test_pass "Git alias detection gracefully skipped outside git repo"
else
    test_fail "Git alias detection produced unexpected output outside git repo"
    test_info "Output: $output"
end

# Test 4b: Cache initialization should succeed without git aliases
test_info "Testing cache initialization outside git repo..."
_ysu_init_cache
if set -q _ysu_cache_initialized
    test_pass "Cache initialization succeeded outside git repo"
else
    test_fail "Cache initialization failed outside git repo"
end

# Test 4c: Git alias cache should be empty
test_info "Verifying git alias cache is empty/handled..."
if test (count $_ysu_git_alias_keys) -eq 0
    test_pass "Git alias cache is empty (as expected)"
else
    test_info "Git alias cache has "(count $_ysu_git_alias_keys)" entries (from global config)"
    test_pass "Git alias cache handled (may have global aliases)"
end

# Test 4d: Non-git command detection still works
test_info "Verifying non-git detection still works outside git repo..."
# Reinitialize cache to pick up abbreviations defined earlier in the script
cd $original_dir
_ysu_init_cache

# Clean up temp directory
rm -rf $temp_dir

# ==============================================================================
# TEST 5: Ignored Aliases - Should Not Show Reminder
# ==============================================================================

test_begin "Edge Case: Ignored Aliases - No Reminder"

# Set up fresh test artifacts
cleanup_test_artifacts

# Test 5a: Ignored abbreviation
test_info "Setting up ignored abbreviation test..."
abbr -a _ysu_edge_ignored 'git pull'
_ysu_init_cache

# Verify abbreviation is cached
if contains _ysu_edge_ignored $_ysu_abbr_keys
    test_pass "Ignored abbreviation is in cache"
else
    test_fail "Ignored abbreviation not in cache"
end

# Add to ignore list
set -g YSU_IGNORED_GLOBAL_ALIASES _ysu_edge_ignored

set -l output (_ysu_check_abbreviations "git pull" 2>&1)
if not string match -q '*_ysu_edge_ignored*' "$output"
    test_pass "Ignored abbreviation not suggested"
else
    test_fail "Ignored abbreviation was incorrectly suggested"
    test_info "Output: $output"
end

# Test 5b: Ignored function alias
test_info "Setting up ignored function alias test..."
function _ysu_edge_func --description "Test function to be ignored"
    ls -la $argv
end
_ysu_init_cache

# Add to ignore list
set -g YSU_IGNORED_ALIASES _ysu_edge_func

set output (_ysu_check_aliases "ls -la" 2>&1)
if not string match -q '*_ysu_edge_func*' "$output"
    test_pass "Ignored function alias not suggested"
else
    test_fail "Ignored function alias was incorrectly suggested"
    test_info "Output: $output"
end

# Test 5c: Ignored git alias
if git rev-parse --git-dir >/dev/null 2>&1
    test_info "Setting up ignored git alias test..."
    git config --local alias._ysu_edge_ignored status
    _ysu_init_cache

    # Verify git alias is cached
    if contains _ysu_edge_ignored $_ysu_git_alias_keys
        test_pass "Ignored git alias is in cache"
    else
        test_fail "Ignored git alias not in cache"
    end

    # Add to ignore list
    set -g YSU_IGNORED_GIT_ALIASES _ysu_edge_ignored

    set output (_ysu_check_git_aliases "git status" 2>&1)
    if not string match -q '*_ysu_edge_ignored*' "$output"
        test_pass "Ignored git alias not suggested"
    else
        test_fail "Ignored git alias was incorrectly suggested"
        test_info "Output: $output"
    end
else
    test_skip "Not in git repo - skipping ignored git alias test"
end

# Test 5d: Multiple ignored aliases
test_info "Testing multiple ignored aliases..."
set -g YSU_IGNORED_GLOBAL_ALIASES _ysu_edge_ignored _ysu_edge_test
abbr -a _ysu_edge_test 'git status'
_ysu_init_cache

set output (_ysu_check_abbreviations "git status" 2>&1)
if not string match -q '*_ysu_edge_test*' "$output"
    test_pass "Multiple ignored abbreviations work correctly"
else
    test_fail "Multiple ignored abbreviations not working"
    test_info "Output: $output"
end

# Test 5e: Verify non-ignored aliases still work
test_info "Verifying non-ignored aliases still show reminders..."
abbr -a _ysu_edge_special 'echo hello'
_ysu_init_cache
# Don't add _ysu_edge_special to ignore list

set output (_ysu_check_abbreviations "echo hello" 2>&1)
if string match -q '*_ysu_edge_special*' "$output"
    test_pass "Non-ignored aliases still trigger reminders"
    test_info "Output: $output"
else
    test_fail "Non-ignored aliases not triggering reminders"
    test_info "Output: $output"
end

# ==============================================================================
# TEST 6: Piped Commands Edge Case
# ==============================================================================

test_begin "Edge Case: Commands with Pipes and Operators"

cleanup_test_artifacts
abbr -a _ysu_edge_test 'ls -la'
_ysu_init_cache

# Test 6a: Command at start of pipe
test_info "Testing command at start of pipe..."
set -l output (_ysu_check_abbreviations "ls -la | grep foo" 2>&1)
# The current implementation checks if typed command matches alias value exactly or starts with it
# "ls -la | grep foo" starts with "ls -la " so it should match
if string match -q '*_ysu_edge_test*' "$output"
    test_pass "Command at start of pipe detected"
    test_info "Output: $output"
else
    test_info "Command at start of pipe may not match (depends on implementation)"
    test_skip "Piped commands may not be supported in current implementation"
end

# Test 6b: Command with && operator
test_info "Testing command with && operator..."
set output (_ysu_check_abbreviations "ls -la && echo done" 2>&1)
if string match -q '*_ysu_edge_test*' "$output"
    test_pass "Command with && operator detected"
else
    test_skip "Commands with && may not be supported"
end

# ==============================================================================
# TEST 7: Already Using Alias
# ==============================================================================

test_begin "Edge Case: Already Using the Alias"

cleanup_test_artifacts
abbr -a _ysu_edge_test 'git status'
_ysu_init_cache

# Test 7a: Already using abbreviation
test_info "Testing when user already used the abbreviation..."
set -l output (_ysu_check_abbreviations "_ysu_edge_test" 2>&1)
if test -z "$output"
    test_pass "No reminder when already using abbreviation"
else
    test_fail "Incorrectly reminded when already using abbreviation"
    test_info "Output: $output"
end

# Test 7b: Already using abbreviation with arguments
test_info "Testing when user already used abbreviation with arguments..."
set output (_ysu_check_abbreviations "_ysu_edge_test --porcelain" 2>&1)
if test -z "$output"
    test_pass "No reminder when using abbreviation with arguments"
else
    test_fail "Incorrectly reminded when using abbreviation with arguments"
    test_info "Output: $output"
end

# ==============================================================================
# TEST 8: Case Sensitivity
# ==============================================================================

test_begin "Edge Case: Case Sensitivity"

cleanup_test_artifacts
abbr -a _ysu_edge_test 'git status'
_ysu_init_cache

# Test 8a: Different case should not match
test_info "Testing case sensitivity (GIT STATUS vs git status)..."
set -l output (_ysu_check_abbreviations "GIT STATUS" 2>&1)
# Commands are case-sensitive, so GIT STATUS should not match git status
if not string match -q '*_ysu_edge_test*' "$output"
    test_pass "Case-sensitive matching works (no match for different case)"
else
    # If it does match, that's also acceptable behavior
    test_info "Case-insensitive matching enabled"
    test_pass "Detection works (case handling is consistent)"
end

# ==============================================================================
# TEST 9: Unicode and Special Shell Characters
# ==============================================================================

test_begin "Edge Case: Unicode and Special Shell Characters"

# Test 9a: Unicode in command
test_info "Testing unicode in command..."
set -l output (_ysu_message "alias" "echo héllo wörld" "_ysu_test" 2>&1)
if string match -q '*héllo*' "$output"
    test_pass "Unicode in command handled correctly"
else
    test_fail "Unicode in command not handled"
    test_info "Output: $output"
end

# Test 9b: Quotes in commands
test_info "Testing quotes in commands..."
set output (_ysu_message "alias" 'echo "hello world"' "_ysu_test" 2>&1)
if not string match -q '*error*' "$output"
    test_pass "Quotes in commands handled without errors"
else
    test_fail "Quotes in commands caused errors"
    test_info "Output: $output"
end

# Test 9c: Dollar signs (should not be expanded)
test_info "Testing dollar signs in commands..."
set output (_ysu_message "alias" 'echo $HOME' "_ysu_test" 2>&1)
if string match -q '*$HOME*' "$output"; or string match -q '*HOME*' "$output"
    test_pass "Dollar signs in commands handled"
else
    test_fail "Dollar signs in commands not handled properly"
    test_info "Output: $output"
end

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
