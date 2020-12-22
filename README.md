# rx_storage ![alt text](https://avatars3.githubusercontent.com/u/6407041?s=32&v=4)

Reactive storage for Dart/Flutter. RxDart Storage for Dart/Flutter.

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

[![Pub Version](https://img.shields.io/pub/v/rx_storage?style=plastic)](https://pub.dev/packages/rx_storage)
[![codecov](https://codecov.io/gh/Flutter-Dart-Open-Source/rx_storage/branch/master/graph/badge.svg?token=6eORcR6Web)](https://codecov.io/gh/Flutter-Dart-Open-Source/rx_storage)
[![Build Status](https://travis-ci.com/Flutter-Dart-Open-Source/rx_storage.svg?branch=master)](https://travis-ci.com/Flutter-Dart-Open-Source/rx_storage)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Style](https://img.shields.io/badge/style-pedantic-40c4ff.svg)](https://github.com/dart-lang/pedantic)

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
