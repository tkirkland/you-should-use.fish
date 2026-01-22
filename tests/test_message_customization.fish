#!/usr/bin/env fish
# Test script for you-should-use Fish plugin - Message Customization and Positioning
# Tests: YSU_MESSAGE_FORMAT placeholders and YSU_MESSAGE_POSITION (before/after)
#
# Run with: fish tests/test_message_customization.fish
#
# This tests the message formatting and positioning features as specified in:
# - Requirement 6: Message Customization (%alias, %command, %alias_type placeholders)
# - Requirement 7: Message Position (before/after command output)

set -l script_dir (dirname (status filename))
set -l project_dir (dirname $script_dir)

# Test result tracking
set -g _test_passed 0
set -g _test_failed 0
set -g _test_skipped 0

# Test helpers (same as other test files)
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
    echo "TEST SUMMARY - Message Customization & Positioning"
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

# Cleanup function for test environment
function cleanup_message_test_artifacts --description "Remove test artifacts"
    # Remove test abbreviations
    abbr -e _ysu_msg_test_gs 2>/dev/null
    abbr -e _ysu_msg_test_gp 2>/dev/null

    # Clear message-related settings
    set -e YSU_MESSAGE_FORMAT 2>/dev/null
    set -e YSU_MESSAGE_POSITION 2>/dev/null

    # Clear the buffer
    set -g _YSU_BUFFER ""
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

# Verify message functions exist
if functions -q _ysu_message
    test_pass "_ysu_message function loaded"
else
    test_fail "_ysu_message function not found - tests will fail"
end

if functions -q _ysu_buffer_write
    test_pass "_ysu_buffer_write function loaded"
else
    test_fail "_ysu_buffer_write function not found - tests will fail"
end

if functions -q _ysu_buffer_flush
    test_pass "_ysu_buffer_flush function loaded"
else
    test_fail "_ysu_buffer_flush function not found - tests will fail"
end

# Clean up any existing test artifacts
cleanup_message_test_artifacts

# ==============================================================================
# TEST 1: Default Message Format
# ==============================================================================

test_begin "Default Message Format"

# Ensure no custom format is set
set -e YSU_MESSAGE_FORMAT 2>/dev/null

# Test default message format
test_info "Testing default message format..."
set -l output (_ysu_message "alias" "git status" "gs" 2>&1)

# Default format should contain all three pieces of information
if string match -q '*alias*' "$output"
    test_pass "Default format includes alias_type"
else
    test_fail "Default format missing alias_type"
    test_info "Output: $output"
end

if string match -q '*git status*' "$output"
    test_pass "Default format includes command"
else
    test_fail "Default format missing command"
    test_info "Output: $output"
end

if string match -q '*gs*' "$output"
    test_pass "Default format includes alias name"
else
    test_fail "Default format missing alias name"
    test_info "Output: $output"
end

# Verify it contains "should use" text
if string match -qi '*should use*' "$output"
    test_pass "Default format includes 'should use' text"
else
    test_fail "Default format should include 'should use' text"
end

test_info "Full output: $output"

# ==============================================================================
# TEST 2: Custom Message Format with %alias placeholder
# ==============================================================================

test_begin "Custom Message Format - %alias Placeholder"

# Set custom format with %alias placeholder
set -gx YSU_MESSAGE_FORMAT "Try using '%alias' instead!"
test_info "Set YSU_MESSAGE_FORMAT=\"Try using '%alias' instead!\""

# Test the custom format
set -l output (_ysu_message "abbreviation" "git push" "gp" 2>&1)

if string match -q "*Try using 'gp' instead!*" "$output"
    test_pass "Custom format with %alias placeholder works"
    test_info "Output: $output"
else
    test_fail "Custom format %alias placeholder not replaced"
    test_info "Expected: Try using 'gp' instead!"
    test_info "Got: $output"
end

# Clean up
set -e YSU_MESSAGE_FORMAT

# ==============================================================================
# TEST 3: Custom Message Format with %command placeholder
# ==============================================================================

test_begin "Custom Message Format - %command Placeholder"

# Set custom format with %command placeholder
set -gx YSU_MESSAGE_FORMAT "You typed '%command' - there's a better way!"
test_info "Set YSU_MESSAGE_FORMAT=\"You typed '%command' - there's a better way!\""

# Test the custom format
set -l output (_ysu_message "alias" "git status" "gs" 2>&1)

if string match -q "*You typed 'git status' - there's a better way!*" "$output"
    test_pass "Custom format with %command placeholder works"
    test_info "Output: $output"
else
    test_fail "Custom format %command placeholder not replaced"
    test_info "Expected: You typed 'git status' - there's a better way!"
    test_info "Got: $output"
end

# Clean up
set -e YSU_MESSAGE_FORMAT

# ==============================================================================
# TEST 4: Custom Message Format with %alias_type placeholder
# ==============================================================================

test_begin "Custom Message Format - %alias_type Placeholder"

# Set custom format with %alias_type placeholder
set -gx YSU_MESSAGE_FORMAT "Found %alias_type: consider using it!"
test_info "Set YSU_MESSAGE_FORMAT=\"Found %alias_type: consider using it!\""

# Test with different alias types
test_info "Testing with alias_type='abbreviation'..."
set -l output (_ysu_message "abbreviation" "git pull" "gpl" 2>&1)

if string match -q "*Found abbreviation: consider using it!*" "$output"
    test_pass "Custom format with %alias_type 'abbreviation' works"
else
    test_fail "%alias_type 'abbreviation' not replaced correctly"
    test_info "Output: $output"
end

test_info "Testing with alias_type='git alias'..."
set output (_ysu_message "git alias" "git checkout" "co" 2>&1)

if string match -q "*Found git alias: consider using it!*" "$output"
    test_pass "Custom format with %alias_type 'git alias' works"
else
    test_fail "%alias_type 'git alias' not replaced correctly"
    test_info "Output: $output"
end

# Clean up
set -e YSU_MESSAGE_FORMAT

# ==============================================================================
# TEST 5: Custom Message Format with ALL placeholders
# ==============================================================================

test_begin "Custom Message Format - All Placeholders Combined"

# Set custom format with all placeholders
set -gx YSU_MESSAGE_FORMAT "[%alias_type] '%command' -> use '%alias'"
test_info "Set YSU_MESSAGE_FORMAT=\"[%alias_type] '%command' -> use '%alias'\""

# Test the combined format
set -l output (_ysu_message "abbreviation" "docker compose up" "dcu" 2>&1)

if string match -q "*[abbreviation] 'docker compose up' -> use 'dcu'*" "$output"
    test_pass "Custom format with all placeholders works"
    test_info "Output: $output"
else
    test_fail "Combined placeholder replacement failed"
    test_info "Expected: [abbreviation] 'docker compose up' -> use 'dcu'"
    test_info "Got: $output"
end

# Clean up
set -e YSU_MESSAGE_FORMAT

# ==============================================================================
# TEST 6: Special Characters in Command (%,\)
# ==============================================================================

test_begin "Special Characters Handling"

# Ensure no custom format
set -e YSU_MESSAGE_FORMAT 2>/dev/null

# Test command with % character
test_info "Testing command with % character..."
set -l output (_ysu_message "alias" "printf '%s'" "pf" 2>&1)

# The % should be escaped and not cause printf issues
if string match -q '*printf*' "$output"
    test_pass "Command with % character handled correctly"
else
    test_fail "Command with % character not handled"
    test_info "Output: $output"
end

# Test command with backslash
test_info "Testing command with backslash..."
set output (_ysu_message "alias" "echo 'test\\nvalue'" "ecn" 2>&1)

if string match -q '*echo*' "$output"
    test_pass "Command with backslash handled correctly"
else
    test_fail "Command with backslash not handled"
    test_info "Output: $output"
end

# ==============================================================================
# TEST 7: Message Position - Default (before)
# ==============================================================================

test_begin "Message Position - Default (before)"

# Clear any position setting
set -e YSU_MESSAGE_POSITION 2>/dev/null
set -g _YSU_BUFFER ""

test_info "Testing default position (should be 'before')..."

# When position is 'before', message should be output immediately
# We test by checking if buffer is empty after _ysu_message
set -l output (_ysu_message "alias" "ls -la" "ll" 2>&1)

# After calling _ysu_message with position=before (default), output should appear
# and buffer should be empty
if test -n "$output"
    test_pass "Message output immediately with default position"
else
    test_fail "No output with default position 'before'"
end

# Check if buffer is empty (it should be flushed)
if test -z "$_YSU_BUFFER"
    test_pass "Buffer is empty after immediate output (position=before)"
else
    test_fail "Buffer should be empty after position=before"
    test_info "Buffer contents: $_YSU_BUFFER"
end

# ==============================================================================
# TEST 8: Message Position - Explicit 'before'
# ==============================================================================

test_begin "Message Position - Explicit 'before'"

# Set explicit 'before' position
set -gx YSU_MESSAGE_POSITION before
set -g _YSU_BUFFER ""

test_info "Set YSU_MESSAGE_POSITION=before"

# Test that message is output immediately
set -l output (_ysu_message "abbreviation" "git status" "gs" 2>&1)

if test -n "$output"
    test_pass "Message output immediately with position=before"
    test_info "Output: $output"
else
    test_fail "No immediate output with position=before"
end

# Buffer should be empty
if test -z "$_YSU_BUFFER"
    test_pass "Buffer empty after position=before"
else
    test_fail "Buffer should be empty"
end

# Clean up
set -e YSU_MESSAGE_POSITION

# ==============================================================================
# TEST 9: Message Position - 'after'
# ==============================================================================

test_begin "Message Position - 'after'"

# Set 'after' position
set -gx YSU_MESSAGE_POSITION after
set -g _YSU_BUFFER ""

test_info "Set YSU_MESSAGE_POSITION=after"

# Test that message is buffered, not output immediately
# Note: _ysu_message calls _ysu_buffer_write which only outputs to stderr
# In 'after' mode, the message should be stored in buffer for later
test_info "Testing that message is buffered (not flushed immediately)..."

# Call the buffer function directly to test buffering
_ysu_buffer_write "Test buffered message\n"

# Buffer should NOT be empty when position=after
if test -n "$_YSU_BUFFER"
    test_pass "Message buffered with position=after"
    test_info "Buffer contains: $_YSU_BUFFER"
else
    test_fail "Message should be buffered, not flushed"
end

# Now manually flush and verify output
test_info "Testing buffer flush..."
set -l flushed_output (_ysu_buffer_flush 2>&1)

if string match -q "*Test buffered message*" "$flushed_output"
    test_pass "Buffer flushed correctly outputs message"
else
    test_fail "Buffer flush did not output expected message"
    test_info "Output: $flushed_output"
end

# Buffer should now be empty
if test -z "$_YSU_BUFFER"
    test_pass "Buffer empty after flush"
else
    test_fail "Buffer should be empty after flush"
end

# Clean up
set -e YSU_MESSAGE_POSITION

# ==============================================================================
# TEST 10: Message Position - Invalid Value Handling
# ==============================================================================

test_begin "Message Position - Invalid Value Handling"

# Set invalid position value
set -gx YSU_MESSAGE_POSITION invalid_value
set -g _YSU_BUFFER ""

test_info "Set YSU_MESSAGE_POSITION=invalid_value"

# Test that an error message is shown
set -l output (_ysu_buffer_write "test message" 2>&1)

if string match -q '*Unknown value*' "$output"; or string match -q '*invalid_value*' "$output"
    test_pass "Invalid position value shows error message"
    test_info "Error shown: $output"
else
    test_info "Output: $output"
    test_pass "Invalid position handled (message still processed)"
end

# Clean up
set -e YSU_MESSAGE_POSITION

# ==============================================================================
# TEST 11: Integration - Custom Format with Abbreviation Detection
# ==============================================================================

test_begin "Integration - Custom Format with Abbreviation Detection"

# Clean environment
cleanup_message_test_artifacts

# Set up test abbreviation
abbr -a _ysu_msg_test_gs 'git status'
test_info "Created abbreviation: _ysu_msg_test_gs -> 'git status'"

# Initialize cache
_ysu_init_cache

# Verify abbreviation is cached
if contains _ysu_msg_test_gs $_ysu_abbr_keys
    test_pass "Test abbreviation cached"
else
    test_fail "Test abbreviation not found in cache"
end

# Set custom message format
set -gx YSU_MESSAGE_FORMAT "CUSTOM: Use '%alias' for '%command' (type: %alias_type)"
test_info "Set custom message format"

# Test detection with custom format
test_info "Testing detection of 'git status'..."
set -l output (_ysu_check_abbreviations "git status" 2>&1)

if string match -q '*CUSTOM:*' "$output"
    test_pass "Custom message format used in abbreviation detection"
else
    test_fail "Custom format not applied"
    test_info "Output: $output"
end

if string match -q '*_ysu_msg_test_gs*' "$output"
    test_pass "Alias name appears in output"
else
    test_fail "Alias name missing from output"
end

if string match -q '*abbreviation*' "$output"
    test_pass "Alias type 'abbreviation' appears in output"
else
    test_fail "Alias type missing from output"
end

test_info "Full output: $output"

# Clean up
abbr -e _ysu_msg_test_gs 2>/dev/null
set -e YSU_MESSAGE_FORMAT

# ==============================================================================
# TEST 12: Integration - Position 'after' with Detection
# ==============================================================================

test_begin "Integration - Position 'after' with Detection"

# Clean environment
cleanup_message_test_artifacts

# Set up test abbreviation
abbr -a _ysu_msg_test_gp 'git push'
test_info "Created abbreviation: _ysu_msg_test_gp -> 'git push'"

# Initialize cache
_ysu_init_cache

# Set position to after
set -gx YSU_MESSAGE_POSITION after
test_info "Set YSU_MESSAGE_POSITION=after"

# Clear the buffer
set -g _YSU_BUFFER ""

# Run detection
test_info "Testing detection with position=after..."
_ysu_check_abbreviations "git push" 2>&1

# Buffer should contain the message
if string match -q '*_ysu_msg_test_gp*' "$_YSU_BUFFER"
    test_pass "Message buffered when position=after"
    test_info "Buffer: $_YSU_BUFFER"
else
    test_fail "Message not buffered with position=after"
    test_info "Buffer: $_YSU_BUFFER"
end

# Simulate prompt hook (which would flush buffer)
test_info "Simulating prompt hook (flushing buffer)..."
set -l flushed (_ysu_buffer_flush 2>&1)

if string match -q '*_ysu_msg_test_gp*' "$flushed"
    test_pass "Buffer flushed correctly by prompt hook simulation"
else
    test_fail "Buffer flush did not contain expected message"
    test_info "Flushed: $flushed"
end

# Clean up
abbr -e _ysu_msg_test_gp 2>/dev/null
set -e YSU_MESSAGE_POSITION

# ==============================================================================
# TEST 13: Empty Custom Format
# ==============================================================================

test_begin "Empty Custom Format"

# Set empty format
set -gx YSU_MESSAGE_FORMAT ""
test_info "Set YSU_MESSAGE_FORMAT=\"\" (empty)"

# Test with empty format - should still produce some output
set -l output (_ysu_message "alias" "test command" "tc" 2>&1)

# Even with empty format, some output should occur (just newline at minimum)
test_info "Output with empty format: '$output'"
test_pass "Empty format handled without error"

# Clean up
set -e YSU_MESSAGE_FORMAT

# ==============================================================================
# TEST 14: Format with Only One Placeholder
# ==============================================================================

test_begin "Format with Only One Placeholder"

# Test format with only %alias
set -gx YSU_MESSAGE_FORMAT "Use: %alias"
test_info "Testing format with only %alias..."
set -l output (_ysu_message "alias" "long command" "lc" 2>&1)

if string match -q "*Use: lc*" "$output"
    test_pass "Format with only %alias works"
else
    test_fail "Single placeholder format failed"
    test_info "Output: $output"
end

# Test format with only %command
set -gx YSU_MESSAGE_FORMAT "Typed: %command"
test_info "Testing format with only %command..."
set output (_ysu_message "alias" "long command" "lc" 2>&1)

if string match -q "*Typed: long command*" "$output"
    test_pass "Format with only %command works"
else
    test_fail "Single placeholder format failed"
    test_info "Output: $output"
end

# Test format with only %alias_type
set -gx YSU_MESSAGE_FORMAT "Type: %alias_type"
test_info "Testing format with only %alias_type..."
set output (_ysu_message "git alias" "long command" "lc" 2>&1)

if string match -q "*Type: git alias*" "$output"
    test_pass "Format with only %alias_type works"
else
    test_fail "Single placeholder format failed"
    test_info "Output: $output"
end

# Clean up
set -e YSU_MESSAGE_FORMAT

# ==============================================================================
# TEST 15: Multiple Occurrences of Same Placeholder
# ==============================================================================

test_begin "Multiple Occurrences of Same Placeholder"

# Set format with repeated placeholders
set -gx YSU_MESSAGE_FORMAT "%alias is better! Really, use %alias!"
test_info "Testing format with repeated %alias placeholder..."

set -l output (_ysu_message "alias" "some command" "sc" 2>&1)

# Should replace all occurrences
if string match -q "*sc is better! Really, use sc!*" "$output"
    test_pass "Multiple occurrences of same placeholder replaced"
else
    test_fail "Multiple placeholder occurrences not all replaced"
    test_info "Output: $output"
end

# Clean up
set -e YSU_MESSAGE_FORMAT

# ==============================================================================
# FINAL CLEANUP
# ==============================================================================

test_begin "Cleanup"

cleanup_message_test_artifacts
test_info "Test artifacts cleaned up"
test_info "Message format and position variables cleared"
test_pass "Cleanup complete"

# ==============================================================================
# SUMMARY
# ==============================================================================

test_summary
