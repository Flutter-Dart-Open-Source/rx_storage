# rx_storage ![alt text](https://avatars3.githubusercontent.com/u/6407041?s=32&v=4)

Reactive storage for Dart/Flutter, powered by RxDart.
RxDart Storage for Dart/Flutter.

Requires Dart SDK `>=3.0.0 <4.0.0`.

## [rx_shared_preferences](https://github.com/hoc081098/rx_shared_preferences) is an extension of this package, check it out!

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

[![Pub Version](https://img.shields.io/pub/v/rx_storage?style=flat)](https://pub.dev/packages/rx_storage)
[![Pub Version](https://img.shields.io/pub/v/rx_storage?style=flat&include_prereleases)](https://pub.dev/packages/rx_storage)
[![codecov](https://codecov.io/gh/Flutter-Dart-Open-Source/rx_storage/branch/master/graph/badge.svg?token=6eORcR6Web)](https://codecov.io/gh/Flutter-Dart-Open-Source/rx_storage)
[![Dart CI](https://github.com/Flutter-Dart-Open-Source/rx_storage/actions/workflows/dart.yml/badge.svg)](https://github.com/Flutter-Dart-Open-Source/rx_storage/actions/workflows/dart.yml)
[![Hits](https://hits.sh/github.com/Flutter-Dart-Open-Source/rx_storage.svg)](https://hits.sh/github.com/Flutter-Dart-Open-Source/rx_storage/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Style](https://img.shields.io/badge/style-lints-40c4ff.svg)](https://pub.dev/packages/lints)

<p align="center">
<img src="https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/master/screenshots/logo.png?raw=true" height="200" alt="RxDart" />
</p>

Liked some of my work? Buy me a coffee (or more likely a beer).

<a href="https://www.buymeacoffee.com/hoc081098" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" height=64></a>

## More details about the returned `Stream`

-   It's a **single-subscription `Stream`** (i.e., it can only be listened to once).

-   The `Stream` emits the **value (nullable)** or **a `TypeError`** as its first event when a listener subscribes.

-   It automatically emits a value when the value associated with the key changes successfully
    (**emits `null`** when the value is removed or set to `null`).

-   When the value read from storage has a different type than expected:
    -   If the value is `null`, the `Stream` will **emit `null`** (because `null` can be cast to any nullable type).
    -   Otherwise, the `Stream` will **emit a `TypeError`**.

-   It **can emit** two consecutive data events that are equal. Use an Rx operator such as `distinct` (commonly known as `distinctUntilChanged` in other Rx implementations) to skip data events that are equal to the previous data event.

![Stream timeline: subscribing to K1 triggers an initial read, followed by events for K1 changes only.](https://raw.githubusercontent.com/Flutter-Dart-Open-Source/rx_storage/master/screenshots/stream-timeline.png)

## Usage

A complete example using an in-memory storage adapter. Both observers receive `null`, `<<1>>`, `<<2>>`, then `null` after the key is removed. The adapter keeps data in memory only.

Run [the example](https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/master/example/rx_storage_example.dart) from the repository root:

```sh
dart run example/rx_storage_example.dart
```

```dart
import 'package:rx_storage/rx_storage.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

final class InMemoryStorageAdapter implements Storage<String, void> {
  final _map = <String, Object?>{};

  @override
  Future<void> clear([void options]) {
    _map.clear();
    return Future.value(null);
  }

  @override
  Future<bool> containsKey(String key, [void options]) =>
      Future.value(_map.containsKey(key));

  @override
  Future<T?> read<T extends Object>(String key, Decoder<T?> decoder,
          [void options]) =>
      Future.sync(() => decoder(_map[key]));

  @override
  Future<Map<String, Object?>> readAll([void options]) =>
      Future.value({..._map});

  @override
  Future<void> remove(String key, [void options]) {
    _map.remove(key);
    return Future.value(null);
  }

  @override
  Future<void> write<T extends Object>(
      String key, T? value, Encoder<T?> encoder,
      [void options]) {
    return Future.sync(() async {
      final encoded = await encoder(value);
      _map[key] = encoded;
    });
  }
}

Future<void> main() async {
  final adapter = InMemoryStorageAdapter();
  final rxStorage = RxStorage<String, void>(adapter);

  try {
    final key = 'key';
    rxStorage
        .observe(key, (v) => v as String?)
        .listen((String? s) => print('[Observe 1] Value: $s'));
    rxStorage
        .observe(key, (v) => v as String?)
        .listen((String? s) => print('[Observe 2] Value: $s'));

    await delay(1);
    print('--- START ---');

    await rxStorage.write(key, '<<1>>', (v) => v);
    print('Read: ${await rxStorage.read(key, (v) => v as String?)}');
    print('-' * 80);

    await rxStorage.write(key, '<<2>>', (v) => v);
    print('Read: ${await rxStorage.read(key, (v) => v as String?)}');
    print('-' * 80);

    await rxStorage.remove(key);
    print('Read: ${await rxStorage.read(key, (v) => v as String?)}');
    print('-' * 80);

    await delay(500);
  } finally {
    await rxStorage.dispose();
  }
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/Flutter-Dart-Open-Source/rx_storage/issues
