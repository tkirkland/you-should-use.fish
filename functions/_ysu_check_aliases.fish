# Alias checking function for you-should-use Fish plugin
# Ported from ysu.zsh _check_aliases function (lines 201-267)
# Detects when typed command matches a defined function alias

function _ysu_check_aliases --description "Check if typed command matches a function alias"
    set -l typed $argv[1]

    # Skip if no input
    if test -z "$typed"
        return
    end

    # sudo will use another user's profile and so aliases would not apply
    if string match -q 'sudo *' $typed
        return
    end

    # Ensure cache is initialized
    if not set -q _ysu_cache_initialized
        return
    end

    # Track found aliases for ALL mode
    set -l found_alias_keys
    set -l found_alias_values

    # Track best match for BESTMATCH mode
    set -l best_match ""
    set -l best_match_value ""

    # Iterate through cached aliases using parallel arrays
    # _ysu_alias_names contains function names
    # _ysu_alias_values contains the commands they wrap
    set -l alias_count (count $_ysu_alias_names)
    for i in (seq $alias_count)
        set -l key $_ysu_alias_names[$i]
        set -l value $_ysu_alias_values[$i]

        # Skip empty values
        if test -z "$value"
            continue
        end

        # Skip ignored aliases
        if set -q YSU_IGNORED_ALIASES
            if contains -- $key $YSU_IGNORED_ALIASES
                continue
            end
        end

        # Check if typed command matches alias value
        # Match exact command or command with trailing arguments
        if test "$typed" = "$value"; or string match -q "$value *" $typed
            # If the alias is longer or the same length as its command
            # we assume that it is there to cater for typos.
            # If not, then the alias would not save any time
            # for the user and so doesn't hold much value anyway
            set -l value_len (string length $value)
            set -l key_len (string length $key)

            if test $value_len -gt $key_len
                # Add to found aliases list
                set -a found_alias_keys $key
                set -a found_alias_values $value

                # Match aliases to longest portion of command (best match)
                set -l best_match_value_len 0
                if test -n "$best_match_value"
                    set best_match_value_len (string length $best_match_value)
                end

                if test $value_len -gt $best_match_value_len
                    set best_match $key
                    set best_match_value $value
                # On equal length, choose the shortest alias
                else if test $value_len -eq $best_match_value_len -a -n "$best_match"
                    set -l best_match_len (string length $best_match)
                    if test $key_len -lt $best_match_len
                        set best_match $key
                        set best_match_value $value
                    end
                end
            end
        end
    end

    # Print result matches based on current mode
    set -l mode BESTMATCH
    if set -q YSU_MODE
        set mode $YSU_MODE
    end

    if test "$mode" = "ALL"
        # Sort found aliases for consistent output
        for i in (seq (count $found_alias_keys))
            set -l key $found_alias_keys[$i]
            set -l value $found_alias_values[$i]
            _ysu_message "alias" "$value" "$key"

            # Check hardcore mode if function exists
            if functions -q _ysu_check_hardcore
                _ysu_check_hardcore "$key"
            end
        end
    else
        # BESTMATCH mode (default)
        if test -n "$best_match"
            # Make sure that the best matched alias has not already
            # been typed by the user (they already used the alias)
            if test "$typed" = "$best_match"; or string match -q "$best_match *" $typed
                return
            end

            _ysu_message "alias" "$best_match_value" "$best_match"

            # Check hardcore mode if function exists
            if functions -q _ysu_check_hardcore
                _ysu_check_hardcore "$best_match"
            end
        end
    end
end
