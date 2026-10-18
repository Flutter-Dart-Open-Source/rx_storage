# Repository Guidelines

## Project Structure & Module Organization

`rx_storage` is a reactive storage library for Dart and Flutter. `lib/rx_storage.dart` defines the package exports; `lib/src/` contains storage interfaces, the implementation, asynchronous queues, loggers, and models. Tests mirror these areas under `test/`, with shared adapters in `test/fake_storage.dart` and helpers in `test/utils/`. `test/rx_storage_test.dart` aggregates the suites, including `test/perf.dart`. Package artwork lives in `screenshots/`; `example/rx_storage_example.dart` is currently an empty placeholder.

## Build, Test, and Development Commands

Use Dart 3.0.0 or later within the SDK constraint in `pubspec.yaml`. CI tests Dart 3.0.0, stable, and beta; analysis and formatting run on stable.

- `dart pub get` — install dependencies.
- `dart analyze --fatal-infos --fatal-warnings` — run the CI analyzer checks.
- `dart format .` — format Dart sources.
- `dart format --output=none --set-exit-if-changed .` — check formatting without rewriting files.
- `dart run test test/rx_storage_test.dart --chain-stack-traces` — run the complete CI test entry point.

This package has no standalone application build or development server.

## Coding Style & Naming Conventions

Use Dart formatting with two-space indentation, `snake_case.dart` filenames, `UpperCamelCase` types, and `lowerCamelCase` members. Follow `analysis_options.yaml`: recommended lints, strict casts/types/inference, single quotes, explicit return types, final locals where possible, and relative imports within `lib/`. Document public APIs with `///` comments and expose intended public additions through `lib/rx_storage.dart`.

## Testing Guidelines

Use `package:test` with descriptive `group` and `test` names in `*_test.dart` files. Run focused checks with, for example, `dart test test/storage/streams_test.dart`. Register new suites in `test/rx_storage_test.dart` so CI executes them. Cover relevant stream emissions, null/type errors, serialized updates, disposal, and asynchronous failures. CI collects library coverage and uploads it to Codecov; no numeric coverage threshold is configured in the repository.

## Commit & Pull Request Guidelines

Recent history favors Conventional Commits, including `chore(deps): ...` and `refactor(async): ...`. Use `<type>(<scope>): <description>` with a relevant scope, and flag breaking changes with `!`. Keep changes focused. PRs should explain the behavior change, link related issues, report validation commands/results, and update `README.md` or `CHANGELOG.md` when public behavior changes.
