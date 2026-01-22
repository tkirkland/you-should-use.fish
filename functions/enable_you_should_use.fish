# Enable you-should-use plugin for Fish Shell
# Ported from ysu.zsh enable_you_should_use function (lines 276-282)
# Sets up event handlers and initializes the plugin

function enable_you_should_use --description "Enable the you-should-use plugin"
    # First disable to clean up any existing state (like ZSH version does)
    disable_you_should_use

    # Define the preexec event handler
    # This runs before each command is executed
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

    # Define the prompt event handler (for message buffer flushing)
    # This runs before each prompt is displayed (like ZSH precmd)
    function _ysu_on_prompt --on-event fish_prompt --description "YSU prompt hook"
        # Flush any buffered messages (for YSU_MESSAGE_POSITION=after)
        if functions -q _ysu_buffer_flush
            _ysu_buffer_flush
        end
    end

    # Initialize the alias/abbreviation cache
    if functions -q _ysu_init_cache
        _ysu_init_cache
    end

    # Mark plugin as enabled
    set -g _ysu_enabled 1
end
