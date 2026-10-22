# rx_storage ![alt text](https://avatars3.githubusercontent.com/u/6407041?s=32&v=4)

Reactive key-value storage for Dart and Flutter, powered by RxDart.

## [rx_shared_preferences](https://github.com/hoc081098/rx_shared_preferences) is an extension of this package, check it out!

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

[![Pub Version](https://img.shields.io/pub/v/rx_storage?style=flat)](https://pub.dev/packages/rx_storage)
[![Pub Prerelease](https://img.shields.io/pub/v/rx_storage?style=flat&include_prereleases)](https://pub.dev/packages/rx_storage)
[![codecov](https://codecov.io/gh/Flutter-Dart-Open-Source/rx_storage/branch/master/graph/badge.svg?token=6eORcR6Web)](https://codecov.io/gh/Flutter-Dart-Open-Source/rx_storage)
[![Dart CI](https://github.com/Flutter-Dart-Open-Source/rx_storage/actions/workflows/dart.yml/badge.svg)](https://github.com/Flutter-Dart-Open-Source/rx_storage/actions/workflows/dart.yml)
[![Hits](https://hits.sh/github.com/Flutter-Dart-Open-Source/rx_storage.svg)](https://hits.sh/github.com/Flutter-Dart-Open-Source/rx_storage/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Style](https://img.shields.io/badge/style-lints-40c4ff.svg)](https://pub.dev/packages/lints)

<p align="center">
  <img src="https://raw.githubusercontent.com/Flutter-Dart-Open-Source/rx_storage/master/screenshots/logo.png" width="160" alt="RxDart logo" />
</p>

Liked some of my work? Buy me a coffee (or more likely a beer).

<a href="https://www.buymeacoffee.com/hoc081098" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" height=64></a>

**Contents**

1. [Getting started](#1-getting-started)
2. [Observing changes](#2-observing-changes)
3. [Storage adapters and codecs](#3-storage-adapters-and-codecs)
4. [Ordering and disposal](#4-ordering-and-disposal)
5. [Migrating to 4.0.0](#5-migrating-to-400)
6. [Links and support](#6-links-and-support)

## 1. Getting started

Requires Dart SDK `>=3.0.0 <4.0.0`.

```sh
dart pub add rx_storage
```

For Flutter projects, use `flutter pub add rx_storage`.

The built-in `InMemoryStorage` adapter needs no additional setup:

```dart
import 'package:rx_storage/rx_storage.dart';

Future<void> main() async {
  final storage = RxStorage<String, void>(InMemoryStorage<String>());
  final subscription = storage
      .observe<String>('name', (raw) => raw as String?)
      .listen((value) => print('Name: $value'));

  try {
    await storage.write<String>('name', 'Ada', (value) => value);

    final name = await storage.read<String>('name', (raw) => raw as String?);
    print('Read: $name'); // Ada

    final values = await storage.readAll((_, raw) => raw);
    print('All: $values'); // {name: Ada}

    await storage.remove('name');
  } finally {
    await subscription.cancel();
    await storage.dispose();
  }
}
```

For multiple observers and bulk decoding, run
[the repository example](https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/master/example/rx_storage_example.dart):

```sh
dart run example/rx_storage_example.dart
```

## 2. Observing changes

Both methods return **single-subscription streams**. Create one stream per
listener. Only successful mutations through the same wrapper trigger notifications.
Direct adapter changes and changes through other wrappers are not observed.

### 2.1. Observe one key

`observe(key, decoder)` starts with a storage read, then receives changes for
that key:

| Trigger | Emitted value |
| --- | --- |
| Listener subscribes | The stored value, passed through the decoder |
| `write()` or `update()` succeeds | The value passed to the write, without decoding it again |
| `remove()` succeeds | `null` |
| `clear()` succeeds | `null` if the key appeared in the adapter's `readAll()` before clearing |

The initial decoder receives `null` for both missing keys and stored nulls.
It can supply a default. Later mutation events bypass the decoder, so removal
still emits `null`.

- Use `containsKey()` to distinguish a missing key from a stored null, if the adapter retains nulls.
- Read and decoding failures become stream errors. Incompatible mutation values
  produce a `TypeError`. Null events are always valid.
- Equal consecutive values are emitted. Use `.distinct()` to skip duplicates.

<img src="https://raw.githubusercontent.com/Flutter-Dart-Open-Source/rx_storage/master/screenshots/stream-timeline.png" width="720" alt="Stream timeline: subscribing to K1 triggers an initial read, followed by events for K1 changes only." />

### 2.2. Observe all entries

`observeAll(decoder)` reads and decodes all entries on subscription and after
each successful `write()`, `update()`, `remove()`, or `clear()`:

```dart
final changes = storage.observeAll(
  (key, raw) => raw == null ? null : '$key=$raw',
);
```

- A null decoding result keeps the key. Removed keys are omitted, and empty
  storage emits an empty map.
- Reads and asynchronous decoding complete in stream order. Read or decoding
  failures become stream errors.
- A read may reflect later mutations, rather than the exact state at the
  mutation that triggered it.

## 3. Storage adapters and codecs

`Storage<Key, Options>` adapters determine persistence, durability, null retention,
and value copying. `Options` holds adapter-specific settings.

Encoders convert values for writing. Decoders convert them for reading.
Both can be synchronous or asynchronous. Bulk decoders receive each existing
key and stored value, allowing different codecs per key.

The built-in `InMemoryStorage<Key>`:

- Starts empty, with no persistence between runs.
- Retains encoded nulls until removal or clearing.
- Takes a shallow entry snapshot for `readAll()` and decodes it into a new map.
- Keeps objects by reference. Decoders can copy them. Direct object mutations
  do not trigger stream events.

## 4. Ordering and disposal

Within one wrapper, `write()`, `remove()`, and `update()` share a queue per key.
An `update()` reads, decodes, transforms, encodes, then writes in that queue.

The queue excludes reads, `clear()`, other keys, direct adapter access, and other
wrappers. It provides no multi-key transactions. `update()` is experimental.

Await required writes before `dispose()`. Disposal discards tasks that have not
started and releases wrapper resources. Stored data and adapter resources remain.
Do not use the wrapper afterward.

## 5. Migrating to 4.0.0

`readAll()` and `observeAll()` now require an `EntryDecoder<Key>` and produce
decoded `Map<Key, Object?>` values. To keep the previous raw-value behavior,
pass an identity decoder:

```dart
final raw = await storage.readAll((_, raw) => raw);
final rawChanges = storage.observeAll((_, raw) => raw);
```

Custom adapters must support synchronous and asynchronous entry decoding in
`readAll()`. Custom reactive implementations must also implement `observeAll()`.
Both retain null decoding results and report failures through the future or stream.

## 6. Links and support

- [API reference](https://pub.dev/documentation/rx_storage/latest/)
- [Changelog](https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/master/CHANGELOG.md)
- [Feature requests and bugs](https://github.com/Flutter-Dart-Open-Source/rx_storage/issues)
