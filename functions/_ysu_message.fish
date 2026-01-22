# Message formatting function for you-should-use Fish plugin
# Ported from ysu.zsh ysu_message function

function _ysu_message --description "Format and display alias reminder message"
    # Color definitions using Fish native set_color
    set -l NONE (set_color normal)
    set -l BOLD (set_color --bold)
    set -l YELLOW (set_color yellow)
    set -l PURPLE (set_color magenta)

    # Default message format with placeholders
    set -l DEFAULT_MESSAGE_FORMAT "$BOLD$YELLOW""Found existing %alias_type for ""$PURPLE""\"%command\"$YELLOW"". You should use: ""$PURPLE""\"%alias\"$NONE"

    # Arguments: alias_type, command, alias
    set -l alias_type_arg $argv[1]
    set -l command_arg $argv[2]
    set -l alias_arg $argv[3]

    # Escape arguments that will be interpreted by printf incorrectly
    # Escape % as %% and \ as \\
    set command_arg (string replace --all '%' '%%' -- $command_arg)
    set command_arg (string replace --all '\\' '\\\\' -- $command_arg)

    # Get message format from environment or use default
    set -l MESSAGE
    if set -q YSU_MESSAGE_FORMAT
        set MESSAGE $YSU_MESSAGE_FORMAT
    else
        set MESSAGE $DEFAULT_MESSAGE_FORMAT
    end

    # Replace placeholders with actual values
    set MESSAGE (string replace --all '%alias_type' $alias_type_arg -- $MESSAGE)
    set MESSAGE (string replace --all '%command' $command_arg -- $MESSAGE)
    set MESSAGE (string replace --all '%alias' $alias_arg -- $MESSAGE)

    # Output to buffer (or directly to stderr if buffer system not yet initialized)
    # Buffer system will be added in subtask-1-3
    if functions -q _ysu_buffer_write
        _ysu_buffer_write "$MESSAGE\n"
    else
        # Direct output to stderr for standalone testing
        printf "%s\n" $MESSAGE >&2
    end
end
