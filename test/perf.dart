import 'dart:async';

import 'package:rx_storage/rx_storage.dart';

import 'fake_storage.dart';
import 'utils/compat.dart';

void main() async {
  const kTestValues = <String, dynamic>{
    'String': 'hello world',
    'bool': true,
    'int': 42,
    'double': 3.14159,
    'List': <String>['foo', 'bar'],
  };

  //
  // const kTestValues2 = <String, dynamic>{
  //   'String': 'goodbye world',
  //   'bool': false,
  //   'int': 1337,
  //   'double': 2.71828,
  //   'List': <String>['baz', 'quox'],
  // };

  final storage = FakeStorage(kTestValues);
  final rxStorage = RxStorage(
    Future.delayed(
      const Duration(milliseconds: 100),
      () => storage,
    ),
    null,
  );

  final stopwatch = Stopwatch();
  final list = kTestValues.keys.toList();
  final max = 100000;

  // wake up
  for (var i = 0; i < max / 2; i++) {
    await rxStorage.get(list[i % list.length]);
  }

  stopwatch
    ..reset()
    ..start();
  print('>>> Start...');

  for (var i = 0; i < max; i++) {
    await rxStorage.get(list[i % list.length]);
  }

  stopwatch.stop();
  print('<<< End... ${stopwatch.elapsedMilliseconds}');
  print('-------------------------------------------');

  //
  //
  //

  final completer = Completer<void>.sync();
  stopwatch
    ..reset()
    ..start();
  print('>>> Start...');

  rxStorage.getStringStream('key').listen((event) {
    if (event == max.toString()) {
      stopwatch.stop();
      print('<<< End... ${stopwatch.elapsedMilliseconds}');
      completer.complete();
    }
  });
  for (var i = 0; i <= max; i++) {
    await rxStorage.setString('key', i.toString());
  }

  await completer.future;
  print('END');
}
