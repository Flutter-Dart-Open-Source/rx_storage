## 4.0.0 - Oct 23, 2026

### Dependencies

- Update dependencies:
  - `rxdart_ext` from `^0.3.0` to `^0.4.0`.
  - `stack_trace` from `^1.10.0` to `^1.11.1`.

- **Breaking**: require Dart SDK `>=3.0.0 <4.0.0`; Dart 2 is no longer supported.

### Changes

- **Breaking**: enforce inheritance and implementation restrictions with Dart 3
  class modifiers:
  - `Storage`, `TransactionalStorage`, `RxStorage`, `RxStorageLogger`, and
    `RxStorageLoggerEvent` are now `abstract interface` classes. Implement these
    contracts instead of extending them.
  - `RealRxStorage`, `RxStorageDefaultLogger`, and `RxStorageEmptyLogger` are now
    `base` classes. Extend them to reuse their implementation, and mark subclasses
    as `base`, `final`, or `sealed`.
  - `KeyAndValue`, `RxStorageError`, and the concrete logger event classes are now
    `final`. Define custom logger events by implementing `RxStorageLoggerEvent`.

- **Breaking**: remove the deprecated `RxStorage.executeUpdate` API and its
  `RealRxStorage` implementation. Use `update` with named arguments (`key`,
  `decoder`, `transformer`, `encoder`, and optional `options`) instead.

- **Breaking**: `Storage.readAll()` and `RxStorage.observeAll()` now require
  an `EntryDecoder<Key>` callback and return maps of decoded values. The
  callback receives both the key and its stored value and supports asynchronous
  decoding. Pass `(key, raw) => raw` to retain the previous raw-value behavior.
  Null decoding results retain their keys; removed keys are omitted from maps.

- Add the built-in `InMemoryStorage<Key>` adapter with synchronous and
  asynchronous encoder/decoder support. Encoded null values retain their keys;
  `remove()` deletes entries, and `readAll()` decodes a shallow entry
  snapshot into a new map.

### Fixes

- Reject queued writes with `StateError` on disposal instead of leaving their
  futures pending. Started operations can finish without further notifications
  or logs.
- Retain asynchronous adapter initialization failures for later operations
  without emitting an uncaught error before the first operation starts.
- Run external disposal cleanup at most once and share its result across
  concurrent and repeated `dispose()` calls.
- Release idle write queues after synchronous task failures.

### Docs

- Clarify the README and illustrate stream emissions with a timeline diagram.
- Exclude repository tooling, image prompts, and generated output from the
  published package.

## 3.0.0 - Jul 19, 2024

- Update dependencies
  - `rxdart_ext` to `^0.3.0` (~ `rxdart` to `^0.28.0`).

## 2.1.0 - Oct 4, 2023

- Accept `Dart SDK` versions above 3.0.

- Deprecated `RxStorage.executeUpdate`. It has been replaced by `update` method.
    ```dart
    Future<void> update<T extends Object>({
      required Key key,
      required Decoder<T?> decoder,
      required Transformer<T?> transformer,
      required Encoder<T?> encoder,
      Options? options,
    })
    ```

- `Transformer<T>` can return a `Future<T>`.

- Update dependencies
  - `disposebag` to `^1.5.1`.

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
