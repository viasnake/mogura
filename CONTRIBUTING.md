# Contributing

Report bugs and suggest changes in [GitHub Issues](https://github.com/viasnake/outcrop/issues). For a bug, include the Outcrop version or commit, host OS, steps to reproduce, and the expected and actual behavior. [Report security issues privately](SECURITY.md).

For a pull request, describe the problem, the change, and its impact. Include the checks you ran when they help reviewers assess the change.

## Develop

Run from the repository root with mise and `build-essential` installed.

```sh
mise trust
mise install
mise run setup
mise run test
mise run format:check
```

Run the browser tests with Node.js 22 or later.

```sh
npm ci
npx playwright install chromium
mise run test:results
```

## Build a distribution

Build the archive after completing the development setup.

```sh
mise exec -- perl -I .tools/carton/lib/perl5 .tools/carton/bin/carton exec sh -eu <<'SH'
perl Makefile.PL
make disttest
make dist
SH
```
