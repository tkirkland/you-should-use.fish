# You Should Use - Fish Shell Plugin
# Main entry point with automatic initialization on shell startup
# Ported from ysu.zsh (enable_you_should_use, lines 276-282)
#
# This plugin reminds you when you type a command that could have been
# replaced by a shorter alias, abbreviation, or git alias.
#
# Configuration variables:
#   YSU_MESSAGE_FORMAT     - Custom message format (placeholders: %alias_type, %command, %alias)
#   YSU_MESSAGE_POSITION   - 'before' (default) or 'after' command output
#   YSU_MODE               - 'BESTMATCH' (default) or 'ALL'
#   YSU_HARDCORE           - Set to 1 to block commands when alias unused
#   YSU_HARDCORE_ALIASES   - List of aliases to enforce in hardcore mode
#   YSU_IGNORED_ALIASES    - List of aliases to ignore
#   YSU_IGNORED_GLOBAL_ALIASES - List of abbreviations to ignore

# Plugin version
set -g YSU_VERSION "1.0.0"

# Enable the plugin
# This sets up the event handlers (_ysu_on_preexec and _ysu_on_prompt)
# and initializes the alias/abbreviation cache
if functions -q enable_you_should_use
    enable_you_should_use
else
    # Fallback: define event handlers directly if enable function not yet loaded
    # This can happen if conf.d runs before functions/ is processed

    # Preexec event handler - runs before each command
    function _ysu_on_preexec --on-event fish_preexec --description "YSU preexec hook"
        set -l typed $argv[1]

        # Skip if cache not initialized
        if not set -q _ysu_cache_initialized
            return
        end

        # Check all alias types
        if functions -q _ysu_check_aliases
            _ysu_check_aliases $typed
        end

        if functions -q _ysu_check_abbreviations
            _ysu_check_abbreviations $typed
        end

        if functions -q _ysu_check_git_aliases
            _ysu_check_git_aliases $typed
        end
    end

    # Prompt event handler - runs before each prompt (like ZSH precmd)
    function _ysu_on_prompt --on-event fish_prompt --description "YSU prompt hook"
        # Flush any buffered messages (for YSU_MESSAGE_POSITION=after)
        if functions -q _ysu_buffer_flush
            _ysu_buffer_flush
        end
    end

    # Initialize the cache when functions become available
    # Use a prompt hook to defer initialization
    function _ysu_deferred_init --on-event fish_prompt --description "Deferred YSU initialization"
        if not set -q _ysu_cache_initialized
            if functions -q _ysu_init_cache
                _ysu_init_cache
            end
        end
        # Remove this deferred init hook after first run
        functions -e _ysu_deferred_init
    end

    # Cache refresh trigger: abbreviation changes
    # Detects when user adds or removes abbreviations and refreshes the cache
    function _ysu_on_postexec --on-event fish_postexec --description "YSU postexec hook for cache refresh"
        # $argv[1] contains the command that just ran
        set -l cmd $argv[1]

        # Check if an abbreviation command was executed
        # Patterns: abbr -a, abbr --add, abbr -e, abbr --erase, abbr --rename
        if string match -qr '^\s*abbr\s+(-a|--add|-e|--erase|--rename)\b' $cmd
            # Refresh only the abbreviation cache for efficiency
            _ysu_refresh_abbr_cache
        end
    end

    # Helper function to refresh only abbreviation cache (faster than full init)
    function _ysu_refresh_abbr_cache --description "Refresh abbreviation cache"
        # Clear existing abbreviation cache
        set -g _ysu_abbr_keys
        set -g _ysu_abbr_values

        # Parse abbr --show output
        for line in (abbr --show 2>/dev/null)
            # Try standard format: abbr -a -- key 'value'
            set -l parts (string match -r "^abbr -a(?:\\s+-r)?\\s+--\\s+(\\S+)\\s+'(.*)'\$" $line)
            if test (count $parts) -ge 3
                set -a _ysu_abbr_keys $parts[2]
                set -a _ysu_abbr_values $parts[3]
                continue
            end

            # Try format without quotes: abbr -a -- key value
            set parts (string match -r "^abbr -a(?:\\s+-r)?\\s+--\\s+(\\S+)\\s+(.*)\$" $line)
            if test (count $parts) -ge 3
                set -a _ysu_abbr_keys $parts[2]
                set -a _ysu_abbr_values $parts[3]
                continue
            end

            # Try older format: abbr key=value
            set parts (string match -r "^abbr\\s+(\\S+)=(.*)\$" $line)
            if test (count $parts) -ge 3
                set -a _ysu_abbr_keys $parts[2]
                set -l val $parts[3]
                set val (string replace -r "^['\"](.*)['\"]\$" '$1' -- $val)
                set -a _ysu_abbr_values $val
            end
        end
    end

    # Cache refresh trigger: directory changes for git aliases
    # Git aliases may differ between repositories, so refresh when PWD changes
    function _ysu_on_pwd_change --on-variable PWD --description "YSU PWD change hook for git cache refresh"
        # Check if we're in a git repository and the repo root changed
        set -l current_git_root (git rev-parse --show-toplevel 2>/dev/null)

        # Store and compare to previous git root
        if test -n "$current_git_root"
            if test "$current_git_root" != "$_ysu_last_git_root"
                set -g _ysu_last_git_root $current_git_root
                # Refresh only the git alias cache
                _ysu_refresh_git_cache
            end
        else
            # Not in a git repo anymore
            if set -q _ysu_last_git_root
                set -e _ysu_last_git_root
                # Clear git alias cache
                set -g _ysu_git_alias_keys
                set -g _ysu_git_alias_values
            end
        end
    end

    # Helper function to refresh only git alias cache (faster than full init)
    function _ysu_refresh_git_cache --description "Refresh git alias cache"
        # Clear existing git alias cache
        set -g _ysu_git_alias_keys
        set -g _ysu_git_alias_values

        # Parse git aliases
        for line in (git config --get-regexp "^alias\..+\$" 2>/dev/null | sort)
            set -l parts (string match -r '^alias\.(\S+)\s+(.*)$' $line)
            if test (count $parts) -ge 3
                set -a _ysu_git_alias_keys $parts[2]
                set -a _ysu_git_alias_values $parts[3]
            else
                # Fallback for edge cases
                set -l key_part (string replace -r '^alias\.' '' -- (string split -m 1 ' ' $line)[1])
                set -l val_part (string split -m 1 ' ' $line)[2]
                if test -n "$key_part"
                    set -a _ysu_git_alias_keys $key_part
                    set -a _ysu_git_alias_values $val_part
                end
            end
        end
    end

    # Mark plugin as enabled
    set -g _ysu_enabled 1
end
