# Cache initialization function for you-should-use Fish plugin
# Ported from fish-abbreviation-tips caching pattern
# This caches abbreviations to parallel arrays for O(1) lookup performance

function _ysu_init_cache --description "Initialize abbreviation cache for YSU plugin"
    # Clear existing abbreviation cache
    set -g _ysu_abbr_keys
    set -g _ysu_abbr_values

    # Parse abbr --show output
    # Format: abbr -a -- key 'value'
    # or:     abbr -a -r -- key 'regex_value' (regex abbreviations)
    for line in (abbr --show 2>/dev/null)
        # Try standard format first: abbr -a -- key 'value'
        set -l parts (string match -r "^abbr -a(?:\\s+-r)?\\s+--\\s+(\\S+)\\s+'(.*)'\$" $line)

        if test (count $parts) -ge 3
            set -a _ysu_abbr_keys $parts[2]
            set -a _ysu_abbr_values $parts[3]
            continue
        end

        # Try format without quotes: abbr -a -- key value
        set parts (string match -r "^abbr -a(?:\\s+-r)?\\s+--\\s+(\\S+)\\s+(.*)\$" $line)
        if test (count $parts) -ge 3
            set -a _ysu_abbr_keys $parts[2]
            set -a _ysu_abbr_values $parts[3]
            continue
        end

        # Try older format: abbr key=value or abbr key 'value'
        set parts (string match -r "^abbr\\s+(\\S+)=(.*)\$" $line)
        if test (count $parts) -ge 3
            set -a _ysu_abbr_keys $parts[2]
            # Remove surrounding quotes if present
            set -l val $parts[3]
            set val (string replace -r "^['\"](.*)['\"]\$" '$1' -- $val)
            set -a _ysu_abbr_values $val
        end
    end

    # Mark cache as initialized
    set -g _ysu_cache_initialized 1
end
