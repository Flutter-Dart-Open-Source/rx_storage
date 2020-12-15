# rx_storage

Reactive storage for Dart/Flutter. RxDart Storage for Dart/Flutter.

![Pub Version](https://img.shields.io/pub/v/rx_storage?style=plastic)
[![codecov](https://codecov.io/gh/Flutter-Dart-Open-Source/rx_storage/branch/master/graph/badge.svg?token=6eORcR6Web)](https://codecov.io/gh/Flutter-Dart-Open-Source/rx_storage)

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
