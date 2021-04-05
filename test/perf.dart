import 'dart:async';

import 'fake_storage.dart';
import 'utils/compat.dart';

Future<void> main() async {
  const kTestValues = <String, dynamic>{
    'String': 'hello world',
    'bool': true,
    'int': 42,
    'double': 3.14159,
    'List': <String>['foo', 'bar'],
  };

  final storage = FakeStorage(kTestValues);
  final rxStorage = FakeRxStorage(
    Future.delayed(
      const Duration(milliseconds: 100),
      () => storage,
    ),
    null,
  );

  final sub = rxStorage
      .getStringStream('String')
      .listen((v) => print(">>>>> key 'String': $v"));

  final stopwatch = Stopwatch();
  final list = kTestValues.keys.toList();
  final max = 500;

  // wake up
  for (var i = 0; i < max / 2; i++) {
    await rxStorage.get(list[i % list.length]);
  }

  stopwatch
    ..reset()
    ..start();
  print('>>> Start 1...');

  final fs = <Future<void>>[];
  for (var i = 0; i < max; i++) {
    final key = list[i % list.length];
    final value = await rxStorage.get(key);
    fs.add(rxStorage.write(key, value, (i) => i));
  }

  await Future.wait(fs);
  stopwatch.stop();
  print('<<< End 1... ${stopwatch.elapsedMilliseconds}');
  print('-------------------------------------------');

  //
  //
  //

  print('Start waiting 31 seconds to making timeout');
  await Future<void>.delayed(const Duration(seconds: 31));
  print('Timeout should be occurred!');

  final completer = Completer<void>.sync();
  stopwatch
    ..reset()
    ..start();
  print('>>> Start 2...');

  late StreamSubscription<String?> sub2;
  sub2 = rxStorage.getStringStream('key').listen((event) {
    if (event == max.toString()) {
      stopwatch.stop();
      print('<<< End 2... ${stopwatch.elapsedMilliseconds}');

      sub2.cancel();
      completer.complete();
    }
  });

  final fs2 = <Future<void>>[];
  for (var i = 0; i <= max; i++) {
    fs2.add(rxStorage.setString('key', i.toString()));
  }

  await Future.wait(fs2);
  await completer.future;
  await sub.cancel();

  await Future<void>.delayed(const Duration(seconds: 2));

  stopwatch
    ..reset()
    ..start();
  print('>>> Start 3...');

  for (var i = 0; i < max; i++) {
    final key = list[i % list.length];
    final value = await rxStorage.get(key);
    await rxStorage.write(key, value, (i) => i);
  }

  await rxStorage.dispose();

  print('<<< End 3... ${stopwatch.elapsedMilliseconds}');
}
