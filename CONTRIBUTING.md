# Contributing

Report bugs and suggest changes in [GitHub Issues](https://github.com/viasnake/outcrop/issues). For a bug, include the Mogura version or commit, host OS, steps to reproduce, and the expected and actual behavior. [Report security issues privately](SECURITY.md).

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

Use indentation to show nesting. Across languages, use a single space wherever
spacing is needed between tokens. Avoid padding keys, assignments, or comments
to line up with neighboring lines.

Use Node.js 22 or later to rebuild the bundled stylesheet after changing utility classes and to run the Chromium tests.

```sh
npm ci
npm run build:css
npx playwright install chromium
mise run test:results
```

## Build a distribution

Build the archive after completing the development setup.

```sh
mise exec -- perl -I "$PWD/.tools/carton/lib/perl5" .tools/carton/bin/carton exec sh -eu <<'SH'
perl Makefile.PL
make disttest
make dist
SH
```

Set `MOGURA_TEST_SYFT` to a Syft executable to exercise exclusion rules on temporary fixtures. The normal test suite uses local HTTP and simulated disk operations.
