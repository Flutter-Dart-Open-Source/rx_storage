## 2.1.0-dev.0 - TODO

- Refactor `executeUpdate`:
    - Convert to named parameters.
    - Moved to `TransactionallyStorage`.
    - Update docs.
    - `Transformer` can return a `Future`.

## 2.0.0 - Jun 1, 2022

- Update dependencies
    - `rxdart` to `0.27.4`.
    - `rxdart_ext` to `0.2.1`.

- Rename
    - `Logger` to `RxStorageLogger`.
    - `LoggerEvent` to `RxStorageLoggerEvent`.
    - `EmptyLogger` to `RxStorageEmptyLogger`.
    - `DefaultLogger` to `RxStorageDefaultLogger`.
- Update `RxStorageEmptyLogger`: add `@nonvirtual` to `log` method.
- `Encoder` and `Decoder` can return a `Future`

## 1.2.0 - Sep 11, 2021

- Update dependencies
    - `rxdart` to `0.27.2`
    - `rxdart_ext` to `0.1.2`
    - `meta` to `1.7.0`

- Internal: migrated from `pedantic` to `lints`.

## 1.1.0 - May 9, 2021

- Update `rxdart` to `0.27.0`.

## 1.0.0 - Apr 30, 2021

- Stable release for null safety.
- Add `RxStorage.executeUpdate`: Read–modify–write style.
- Synchronize writing task by key.
- Internal refactoring, optimize performance.

## 1.0.0-nullsafety.0 - Feb 24, 2021

- **Breaking**:
    - Opt into nullsafety.
    - Set Dart SDK constraints to `>=2.12.0-0 <3.0.0`.
    - Big refactoring for `Logger`, `RealRxStorage` implementation.

## 0.0.2 - Jan 4, 2021

- Refactors `Storage` and `RxStorage`:
    - Supports any type via `Encoder` and `Decoder`.
    - Generic `Key` and generic `Options`.
- Exports `RealRxStorage` class.

## 0.0.1 - Dec 14, 2020

- Initial version.
