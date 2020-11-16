import 'dart:async';

import 'package:rx_storage/rx_storage.dart';

import 'fake_storage.dart';

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
      Future.delayed(const Duration(milliseconds: 100), () => storage));

  final stopwatch = Stopwatch();
  final list = kTestValues.keys.toList();

  stopwatch
    ..reset()
    ..start();
  print('Start...');
  for (var i = 0; i < 10000; i++) {
    await rxStorage.get(list[i % list.length]);
  }
  print('End...');

  stopwatch.stop();
  print(stopwatch.elapsedMilliseconds);

  final completer = Completer<void>.sync();
  stopwatch
    ..reset()
    ..start();
  print('Start 2...');
  rxStorage.getStringStream('key').listen((event) {
    if (event == 10000.toString()) {
      print('End 2...');

      stopwatch.stop();
      print(stopwatch.elapsedMilliseconds);
      completer.complete();
    }
  });
  for (var i = 0; i <= 10000; i++) {
    await rxStorage.setString('key', i.toString());
  }

  await completer.future;

  /*for (var i = 0; i < 10000; i++) {
      await Future.value(1)
          .then((value) => SynchronousFuture(value + 1))
          .then((value) {})
          .then((value) {})
          .then((value) => SynchronousFuture('22'));
      print(i);
    }
    print('done');*/
}
