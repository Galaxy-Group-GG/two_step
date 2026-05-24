# Contributing

Thanks for contributing to `two_step`.

## Local Setup

This project uses Ruby `3.4.7` and the dependencies declared in the gemspec and `Gemfile`.

```bash
bin/setup
```

That installs gems and prepares the dummy Rails app used by the test suite.

## Commands

```bash
bin/lint              # Standard + standard-rails
bin/test              # prepares the dummy app DB, then runs the test suite
bundle exec rake coverage
docker compose build test && docker compose run --rm test
```

## Development Guidelines

- Add or update tests for every behavior change.
- Prefer small, focused pull requests with a clear user-facing reason.
- Keep public APIs backward-compatible when possible and document any contract changes in `README.md` and `CHANGELOG.md`.
- Use [Standard](https://github.com/standardrb/standard) instead of maintaining a custom RuboCop ruleset unless a new rule is necessary for correctness.

## Security

Because this gem handles authentication flows, please avoid filing public issues for security-sensitive reports. Follow the process in `SECURITY.md`.
