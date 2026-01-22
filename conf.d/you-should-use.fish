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
set -g YSU_VERSION "2.0.0"

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
        # $argv[1] contains the command line
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

    # Mark plugin as enabled
    set -g _ysu_enabled 1
end
