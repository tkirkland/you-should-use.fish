# You Should Use (Fish Shell)

A Fish shell plugin that reminds you to use your aliases.

Ported from [ysu.zsh](https://github.com/MichaelAquilina/zsh-you-should-use).

## Installation

### Manual

```fish
# Copy to your Fish config
cp -r conf.d/* ~/.config/fish/conf.d/
cp -r functions/* ~/.config/fish/functions/
```

### Fisher

```fish
fisher install tkirkland/you-should-use.fish
```

### Oh My Fish

```fish
omf install tkirkland/you-should-use.fish
```

## Usage

Once installed, the plugin automatically reminds you when you type a command that has an alias:

```
$ eza --icons
Found existing alias for "eza --icons". You should use: "ls"
```

It checks:
- **Aliases** (Fish functions created via `alias`)
- **Abbreviations** (`abbr`)
- **Git aliases** (`git config alias.*`)

## Configuration

Set these variables in your `config.fish` or environment:

### `YSU_MESSAGE_FORMAT`

Custom message format. Placeholders: `%alias_type`, `%command`, `%alias`

```fish
set -g YSU_MESSAGE_FORMAT "Use '%alias' instead of '%command'"
```

### `YSU_MESSAGE_POSITION`

When to show the message: `before` (default) or `after` command output.

```fish
set -g YSU_MESSAGE_POSITION after
```

### `YSU_MODE`

- `BESTMATCH` (default) - Show only the best matching alias
- `ALL` - Show all matching aliases

```fish
set -g YSU_MODE ALL
```

### `YSU_HARDCORE`

Block command execution when an alias is available.

```fish
set -g YSU_HARDCORE 1
```

### `YSU_IGNORED_ALIASES`

List of aliases to ignore.

```fish
set -g YSU_IGNORED_ALIASES ls ll
```

## Commands

- `enable_you_should_use` - Enable the plugin
- `disable_you_should_use` - Disable the plugin

## License

MIT
