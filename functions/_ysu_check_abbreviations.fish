# Abbreviation checking function for you-should-use Fish plugin
# Ported from ysu.zsh _check_global_aliases function (lines 161-198)
# Detects when typed command matches a defined Fish abbreviation

function _ysu_check_abbreviations --description "Check if typed command matches a Fish abbreviation"
    set -l typed $argv[1]

    # Skip if no input
    if test -z "$typed"
        return
    end

    # sudo will use another user's profile and so abbreviations would not apply
    if string match -q 'sudo *' $typed
        return
    end

    # Ensure cache is initialized
    if not set -q _ysu_cache_initialized
        return
    end

    # Track found abbreviations for ALL mode
    set -l found_abbr_keys
    set -l found_abbr_values

    # Track best match for BESTMATCH mode
    set -l best_match ""
    set -l best_match_value ""

    # Iterate through cached abbreviations using parallel arrays
    # _ysu_abbr_keys contains abbreviation names
    # _ysu_abbr_values contains the expansions they represent
    set -l abbr_count (count $_ysu_abbr_keys)
    for i in (seq $abbr_count)
        set -l key $_ysu_abbr_keys[$i]
        set -l value $_ysu_abbr_values[$i]

        # Skip empty values
        if test -z "$value"
            continue
        end

        # Skip ignored abbreviations (global aliases equivalent)
        if set -q YSU_IGNORED_GLOBAL_ALIASES
            if contains -- $key $YSU_IGNORED_GLOBAL_ALIASES
                continue
            end
        end

        # Check if typed command matches abbreviation value
        # Match patterns:
        # - " $value " (value surrounded by spaces - middle of command)
        # - " $value"  (value at end of command with leading space)
        # - "$value "  (value at start of command with trailing space)
        # - "$value"   (exact match - entire command)
        if test "$typed" = "$value"
            # Exact match
            set -l value_len (string length $value)
            set -l key_len (string length $key)

            if test $value_len -gt $key_len
                set -a found_abbr_keys $key
                set -a found_abbr_values $value

                # Track best match (longest value wins)
                set -l best_match_value_len 0
                if test -n "$best_match_value"
                    set best_match_value_len (string length $best_match_value)
                end

                if test $value_len -gt $best_match_value_len
                    set best_match $key
                    set best_match_value $value
                else if test $value_len -eq $best_match_value_len -a -n "$best_match"
                    # On equal length, choose the shortest abbreviation
                    set -l best_match_len (string length $best_match)
                    if test $key_len -lt $best_match_len
                        set best_match $key
                        set best_match_value $value
                    end
                end
            end
        else if string match -q "* $value *" " $typed "; or \
                string match -q "* $value" " $typed"; or \
                string match -q "$value *" "$typed"
            # Value found within typed command (with word boundaries)
            set -l value_len (string length $value)
            set -l key_len (string length $key)

            if test $value_len -gt $key_len
                set -a found_abbr_keys $key
                set -a found_abbr_values $value

                # Track best match
                set -l best_match_value_len 0
                if test -n "$best_match_value"
                    set best_match_value_len (string length $best_match_value)
                end

                if test $value_len -gt $best_match_value_len
                    set best_match $key
                    set best_match_value $value
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
        # Output all found abbreviations
        for i in (seq (count $found_abbr_keys))
            set -l key $found_abbr_keys[$i]
            set -l value $found_abbr_values[$i]
            _ysu_message "abbreviation" "$value" "$key"

            # Check hardcore mode if function exists
            if functions -q _ysu_check_hardcore
                _ysu_check_hardcore "$key"
            end
        end
    else
        # BESTMATCH mode (default)
        if test -n "$best_match"
            # Make sure that the best matched abbreviation has not already
            # been typed by the user (they already used the abbreviation)
            if test "$typed" = "$best_match"; or string match -q "$best_match *" $typed
                return
            end

            _ysu_message "abbreviation" "$best_match_value" "$best_match"

            # Check hardcore mode if function exists
            if functions -q _ysu_check_hardcore
                _ysu_check_hardcore "$best_match"
            end
        end
    end
end
