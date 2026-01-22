# Disable you-should-use plugin for Fish Shell
# Ported from ysu.zsh disable_you_should_use function (lines 269-274)
# Removes event handlers and clears plugin state

function disable_you_should_use --description "Disable the you-should-use plugin"
    # Remove event handler functions if they exist
    # This effectively "unregisters" them from Fish events
    if functions -q _ysu_on_preexec
        functions -e _ysu_on_preexec
    end

    if functions -q _ysu_on_prompt
        functions -e _ysu_on_prompt
    end

    # Clear cache variables
    set -e _ysu_cache_initialized
    set -e _ysu_abbr_keys
    set -e _ysu_abbr_values
    set -e _ysu_alias_names
    set -e _ysu_alias_values
    set -e _ysu_git_alias_keys
    set -e _ysu_git_alias_values

    # Clear message buffer
    set -e _YSU_BUFFER

    # Mark plugin as disabled
    set -g _ysu_enabled 0
end
