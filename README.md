# rx_storage ![alt text](https://avatars3.githubusercontent.com/u/6407041?s=32&v=4)

Reactive storage for Dart/Flutter. RxDart Storage for Dart/Flutter.

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

[![Pub Version](https://img.shields.io/pub/v/rx_storage?style=plastic)](https://pub.dev/packages/rx_storage)
[![codecov](https://codecov.io/gh/Flutter-Dart-Open-Source/rx_storage/branch/master/graph/badge.svg?token=6eORcR6Web)](https://codecov.io/gh/Flutter-Dart-Open-Source/rx_storage)
[![Build Status](https://travis-ci.com/Flutter-Dart-Open-Source/rx_storage.svg?branch=master)](https://travis-ci.com/Flutter-Dart-Open-Source/rx_storage)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Style](https://img.shields.io/badge/style-pedantic-40c4ff.svg)](https://github.com/dart-lang/pedantic)

## Note: [rx_shared_preferences](https://github.com/hoc081098/rx_shared_preferences) is an extension of this package.

## More detail about returned `Stream`
-   It's a **single-subscription `Stream`** (ie. it can only be listened once).

-   `Stream` will emit the **value (nullable)** or **a `TypeError`** as its first event when it is listen to.

-   It will automatic emits value when value associated with key was changed successfully
    (**emit `null`** when value associated with key was `removed` or set to `null`).

-   When value read from Storage has a type other than expected type:
    -   If value is `null`, the `Stream` will **emit `null`** (this occurred because `null` can be cast to any nullable type).
    -   Otherwise, the `Stream` will **emit a `TypeError`**.

-   **Can emit** two consecutive data events that are equal. You should use Rx operator like `distinct` (More commonly known as `distinctUntilChanged` in other Rx implementations) to create an `Stream` where data events are skipped if they are equal to the previous data event.

```
Key changed:  |----------K1---K2------K1----K1-----K2---------
              |                                                
Value stream: |-----@----@------------@-----@-----------------
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

class StorageAdapter implements Storage { ... }

main() {
  final Storage adapter = StorageAdapter();
  final RxStorage rxStorage = RxStorage(adapter);

  rxStorage.getStringStream('key').listen((value) { ... });
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/Flutter-Dart-Open-Source/rx_storage/issues
