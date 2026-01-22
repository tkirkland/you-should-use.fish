# Hardcore mode function for you-should-use Fish plugin
# Ported from ysu.zsh _check_ysu_hardcore function (lines 116-124)
# Prevents command execution when an alias was not used

function _ysu_check_hardcore --description "Block command execution if alias unused and hardcore mode enabled"
    set -l alias_name $argv[1]

    # Check if hardcore mode should be activated:
    # 1. YSU_HARDCORE is set (global hardcore mode), OR
    # 2. The alias is in YSU_HARDCORE_ALIASES (selective hardcore mode)
    set -l should_block false

    # Check global hardcore mode
    if set -q YSU_HARDCORE
        set should_block true
    end

    # Check selective hardcore mode (YSU_HARDCORE_ALIASES)
    if test -n "$alias_name"; and set -q YSU_HARDCORE_ALIASES
        if contains -- $alias_name $YSU_HARDCORE_ALIASES
            set should_block true
        end
    end

    # Block execution if hardcore mode is active
    if test "$should_block" = true
        # Color definitions using Fish native set_color
        set -l NONE (set_color normal)
        set -l BOLD (set_color --bold)
        set -l RED (set_color red)

        # Output message to buffer
        if functions -q _ysu_buffer_write
            _ysu_buffer_write "$BOLD$RED""You Should Use hardcore mode enabled. Use your aliases!""$NONE\n"
        else
            # Direct output if buffer function not available
            printf "%s%sYou Should Use hardcore mode enabled. Use your aliases!%s\n" $BOLD $RED $NONE >&2
        end

        # Block command execution by clearing the command line
        # This is the Fish equivalent of ZSH's kill -s INT $$
        commandline -f repaint
        commandline ''

        return 1
    end

    return 0
end
