# Cache initialization function for you-should-use Fish plugin
# Ported from fish-abbreviation-tips caching pattern
# This caches abbreviations, function aliases, and git aliases to parallel arrays for O(1) lookup performance

function _ysu_init_cache --description "Initialize abbreviation, function alias, and git alias cache for YSU plugin"
    # Clear existing abbreviation cache
    set -g _ysu_abbr_keys
    set -g _ysu_abbr_values

    # Clear existing function alias cache
    # _ysu_alias_names: list of function names
    # _ysu_alias_values: list of function bodies (first line/command)
    set -g _ysu_alias_names
    set -g _ysu_alias_values

    # Clear existing git alias cache
    # _ysu_git_alias_keys: list of git alias names (e.g., "co" for "git config alias.co")
    # _ysu_git_alias_values: list of git alias values (e.g., "checkout")
    set -g _ysu_git_alias_keys
    set -g _ysu_git_alias_values

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

    # Cache function aliases (Fish functions act as aliases)
    # Get all function names and extract their bodies
    for func_name in (functions -n 2>/dev/null)
        # Skip internal/private functions (starting with _) unless they're user-defined short aliases
        # Also skip fish builtins and completion functions
        # We cache all functions to allow alias detection
        set -a _ysu_alias_names $func_name

        # Get function definition to extract the body/command it wraps
        # functions <name> returns the full definition, we extract the command
        set -l func_def (functions $func_name 2>/dev/null)
        if test -n "$func_def"
            # Parse function body: look for the actual command being wrapped
            # Function format:
            # function name [--description 'desc']
            #     command $argv
            # end
            # We want to extract the command being wrapped (if it's a simple wrapper)
            set -l body_lines
            set -l in_body 0
            for line in $func_def
                # Skip the function declaration line
                if string match -qr '^\s*function\s+' $line
                    set in_body 1
                    continue
                end
                # Skip the end line
                if string match -qr '^\s*end\s*$' $line
                    continue
                end
                # Collect body lines
                if test $in_body -eq 1
                    set -l trimmed (string trim $line)
                    if test -n "$trimmed"
                        set -a body_lines $trimmed
                    end
                end
            end

            # If function has a simple body (one command), extract it
            if test (count $body_lines) -eq 1
                # Remove $argv from the end if present (common pattern for alias functions)
                set -l cmd (string replace -r '\s*\$argv\s*$' '' -- $body_lines[1])
                set -a _ysu_alias_values $cmd
            else if test (count $body_lines) -gt 0
                # For complex functions, store the first line as hint
                set -a _ysu_alias_values $body_lines[1]
            else
                # Empty function or parse error, store function name as value
                set -a _ysu_alias_values $func_name
            end
        else
            # Could not get definition, store function name
            set -a _ysu_alias_values $func_name
        end
    end

    # Cache git aliases
    # Parse output from: git config --get-regexp "^alias\..+$"
    # Format: alias.key value (e.g., "alias.co checkout")
    for line in (git config --get-regexp "^alias\..+\$" 2>/dev/null | sort)
        # Extract key and value from "alias.key value" format
        # The key is everything after "alias." until the first space
        # The value is everything after the first space
        set -l parts (string match -r '^alias\.(\S+)\s+(.*)$' $line)

        if test (count $parts) -ge 3
            set -a _ysu_git_alias_keys $parts[2]
            set -a _ysu_git_alias_values $parts[3]
        else
            # Fallback: try splitting on first space if regex didn't match
            # This handles edge cases where value might be empty or unusual
            set -l key_part (string replace -r '^alias\.' '' -- (string split -m 1 ' ' $line)[1])
            set -l val_part (string split -m 1 ' ' $line)[2]
            if test -n "$key_part"
                set -a _ysu_git_alias_keys $key_part
                set -a _ysu_git_alias_values $val_part
            end
        end
    end

    # Mark cache as initialized
    set -g _ysu_cache_initialized 1
end
