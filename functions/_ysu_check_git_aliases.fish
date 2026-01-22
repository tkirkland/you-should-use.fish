# Git alias checking function for you-should-use Fish plugin
# Ported from ysu.zsh _check_git_aliases function (lines 127-158)
# Detects when typed git command matches a defined git alias

function _ysu_check_git_aliases --description "Check if typed git command matches a git alias"
    set -l typed $argv[1]

    # Skip if no input
    if test -z "$typed"
        return
    end

    # sudo will use another user's profile and so aliases would not apply
    if string match -q 'sudo *' $typed
        return
    end

    # Only check git commands
    if not string match -q 'git *' $typed
        return
    end

    # Ensure cache is initialized
    if not set -q _ysu_cache_initialized
        return
    end

    # Extract the git subcommand portion (everything after "git ")
    set -l git_cmd (string replace -r '^git\s+' '' -- $typed)

    # Track if any alias was found (for hardcore mode)
    set -l found false

    # Iterate through cached git aliases using parallel arrays
    # _ysu_git_alias_keys contains alias names (e.g., "co", "st")
    # _ysu_git_alias_values contains the commands they expand to (e.g., "checkout", "status")
    set -l alias_count (count $_ysu_git_alias_keys)
    for i in (seq $alias_count)
        set -l key $_ysu_git_alias_keys[$i]
        set -l value $_ysu_git_alias_values[$i]

        # Skip empty values
        if test -z "$value"
            continue
        end

        # Skip ignored aliases (support YSU_IGNORED_GIT_ALIASES)
        if set -q YSU_IGNORED_GIT_ALIASES
            if contains -- $key $YSU_IGNORED_GIT_ALIASES
                continue
            end
        end

        # Check if the typed git command matches the alias value
        # Match exact command or command with trailing arguments
        # e.g., "git status" matches alias "st" -> "status"
        # e.g., "git checkout main" matches alias "co" -> "checkout"
        if test "$git_cmd" = "$value"; or string match -q "$value *" $git_cmd
            _ysu_message "git alias" "$value" "git $key"
            set found true
        end
    end

    # Check hardcore mode if any aliases were found
    if test "$found" = true
        if functions -q _ysu_check_hardcore
            _ysu_check_hardcore
        end
    end
end
