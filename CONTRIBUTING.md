# Contributing

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a branch for your changes

## Development

Install locally for testing:

```fish
set -p fish_function_path /path/to/ysu.fish/functions
source /path/to/ysu.fish/conf.d/you-should-use.fish
```

## Testing

Run the test suite:

```fish
cd tests
fish test_runner.fish
```

## Code Style

- Use descriptive function names prefixed with `_ysu_` for internal functions
- Add `--description` to all functions
- Comment non-obvious logic

## Pull Requests

1. Update tests if adding new functionality
2. Ensure all tests pass
3. Update README.md if adding/changing configuration options
4. Keep commits focused and atomic

## Reporting Issues

Use the issue templates for bug reports and feature requests.
