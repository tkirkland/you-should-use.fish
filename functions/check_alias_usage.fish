# Alias usage analysis function for you-should-use Fish plugin
# Ported from ysu.zsh check_alias_usage function (lines 16-66)
# Analyzes history for abbreviation and function alias usage patterns

function check_alias_usage --description "Analyze history for alias usage patterns"
    # Optional parameter that limits how far back history is checked
    # Default to a large value if not specified
    set -l limit $argv[1]
    if test -z "$limit"
        set limit 9000000000
    end

    # Ensure cache is initialized (we need abbreviations and function aliases)
    if not set -q _ysu_cache_initialized
        if functions -q _ysu_init_cache
            _ysu_init_cache
        else
            echo "Error: _ysu_init_cache not found. Please source the YSU plugin first." >&2
            return 1
        end
    end

    # Build list of all aliases to track (abbreviations and function aliases)
    # Store alias names, their expansions, and counts in parallel arrays
    set -l alias_names
    set -l alias_values
    set -l alias_counts

    # Add abbreviations to tracking list
    for i in (seq (count $_ysu_abbr_keys))
        set -a alias_names $_ysu_abbr_keys[$i]
        set -a alias_values $_ysu_abbr_values[$i]
        set -a alias_counts 0
    end

    # Add function aliases to tracking list
    # Only add if not already present (avoid duplicates)
    for i in (seq (count $_ysu_alias_names))
        set -l name $_ysu_alias_names[$i]
        if not contains -- $name $alias_names
            set -a alias_names $name
            set -a alias_values $_ysu_alias_values[$i]
            set -a alias_counts 0
        end
    end

    # Get history entries
    # Fish history command returns most recent first
    set -l history_entries (history --null | string split0)

    # Calculate how many entries to process
    set -l total (count $history_entries)
    if test $total -gt $limit
        set total $limit
    end

    set -l current 0

    # Process each history entry
    for i in (seq $total)
        set -l line $history_entries[$i]

        # Skip empty lines
        if test -z "$line"
            continue
        end

        # Handle pipe-separated commands (split on |)
        for entry in (string split '|' $line)
            # Remove leading and trailing whitespace
            set entry (string trim $entry)

            # Skip empty entries
            if test -z "$entry"
                continue
            end

            # Extract first word (that's what abbreviations/aliases work with)
            set -l word (string split -m 1 ' ' $entry)[1]
            if test -z "$word"
                set word $entry
            end

            # Check if this word is one of our tracked aliases
            for j in (seq (count $alias_names))
                if test "$word" = "$alias_names[$j]"
                    # Increment count
                    set alias_counts[$j] (math $alias_counts[$j] + 1)
                    break
                end
            end
        end

        # Print progress to stderr (overwrites previous line)
        set current (math $current + 1)
        printf "Analysing: [%d/%d]\r" $current $total >&2
    end

    # Clear the progress line
    printf "\r\033[K" >&2

    # Build output with counts and sort by usage
    # Format: count: alias=value
    for i in (seq (count $alias_names))
        set -l cnt $alias_counts[$i]
        set -l name $alias_names[$i]
        set -l value $alias_values[$i]
        # Output format matches ZSH: count: 'name'='value'
        printf "%d: '%s'='%s'\n" $cnt $name $value
    end | sort -rn -k1
end
