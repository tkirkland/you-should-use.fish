# Message formatting function for you-should-use Fish plugin
# Ported from ysu.zsh ysu_message function

# Buffer system for message positioning
# Writing to a buffer rather than directly to stdout/stderr allows us to decide
# if we want to write the reminder message before or after a command has been executed

function _ysu_buffer_write --description "Write message to YSU buffer, conditionally flush based on position"
    # Append content to global buffer
    set -g _YSU_BUFFER "$_YSU_BUFFER$argv[1]"

    # Maintain historical behaviour by default (before)
    set -l position before
    if set -q YSU_MESSAGE_POSITION
        set position $YSU_MESSAGE_POSITION
    end

    # Color definitions for error message
    set -l NONE (set_color normal)
    set -l BOLD (set_color --bold)
    set -l RED (set_color red)

    if test "$position" = before
        _ysu_buffer_flush
    else if test "$position" != after
        # Unknown position value - show error and flush
        printf "%s%sUnknown value for YSU_MESSAGE_POSITION '%s'. Expected value 'before' or 'after'%s\n" $BOLD $RED $position $NONE >&2
        _ysu_buffer_flush
    end
    # If position is "after", don't flush - will be flushed by precmd hook
end

function _ysu_buffer_flush --description "Flush the YSU message buffer to stderr"
    # Only output if buffer has content
    if test -n "$_YSU_BUFFER"
        # Output buffer content to stderr
        # Using printf with %s to handle escape codes properly
        printf "%s" $_YSU_BUFFER >&2
        # Clear the buffer
        set -g _YSU_BUFFER ""
    end
end

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

    # Output to buffer (flushes immediately if position=before, or waits for precmd if position=after)
    if functions -q _ysu_buffer_write
        _ysu_buffer_write "$MESSAGE\n"
    else
        # Direct output to stderr for standalone testing
        printf "%s\n" $MESSAGE >&2
    end
end
