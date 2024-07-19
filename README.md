# rx_storage ![alt text](https://avatars3.githubusercontent.com/u/6407041?s=32&v=4)

Reactive storage for Dart/Flutter. RxDart Storage for Dart/Flutter.

## [rx_shared_preferences](https://github.com/hoc081098/rx_shared_preferences) is an extension of this package, check it out!

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)
[![Pub Version](https://img.shields.io/pub/v/rx_storage?style=flat)](https://pub.dev/packages/rx_storage)
[![Pub Version](https://img.shields.io/pub/v/rx_storage?style=flat&include_prereleases)](https://pub.dev/packages/rx_storage)
[![codecov](https://codecov.io/gh/Flutter-Dart-Open-Source/rx_storage/branch/master/graph/badge.svg?token=6eORcR6Web)](https://codecov.io/gh/Flutter-Dart-Open-Source/rx_storage)
[![Dart CI](https://github.com/Flutter-Dart-Open-Source/rx_storage/actions/workflows/dart.yml/badge.svg)](https://github.com/Flutter-Dart-Open-Source/rx_storage/actions/workflows/dart.yml)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FFlutter-Dart-Open-Source%2Frx_storage&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Style](https://img.shields.io/badge/style-lints-40c4ff.svg)](https://pub.dev/packages/lints)

<p align="center">
<img src="https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/master/screenshots/logo.png?raw=true" height="200" alt="RxDart" />
</p>

Liked some of my work? Buy me a coffee (or more likely a beer).

<a href="https://www.buymeacoffee.com/hoc081098" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" height=64></a>

## More detail about returned `Stream`

-   It's a **single-subscription `Stream`** (ie. it can only be listened once).

-   `Stream` will emit the **value (nullable)** or **a `TypeError`** as its first event when it is listen to.

-   It will automatically emit value when value associated with key was changed successfully
    (**emit `null`** when value associated with key was `removed` or set to `null`).

-   When value read from Storage has a type other than expected type:
    -   If value is `null`, the `Stream` will **emit `null`** (this occurred because `null` can be cast to any nullable type).
    -   Otherwise, the `Stream` will **emit a `TypeError`**.

-   **Can emit** two consecutive data events that are equal. You should use Rx operator like `distinct` (More commonly known as `distinctUntilChanged` in other Rx implementations) to create an `Stream` where data events are skipped if they are equal to the previous data event.

```text
Key changed:  |----------K1---K2------K1----K1-----K2---------> time
              |                                                
Value stream: |-----@----@------------@-----@-----------------> time
              |    ^                                      
              |    |
              |  Listen(key=K1)
              |
              |  @: nullable value or TypeError
```
## Usage

A simple usage example:

```dart
import 'package:rx_storage/rx_storage.dart';

class StorageAdapter implements Storage<String, void> { ... }

main() async {
  final adapter = StorageAdapter();
  final rxStorage = RxStorage<String, void>(adapter);

  rxStorage.observe('key', (v) => v as String?).listen((String? s) { ... });
  await rxStorage.write('key', 'a String', (v) => v);
  await rxStorage.read('key', (v) => v as String?);
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/Flutter-Dart-Open-Source/rx_storage/issues
