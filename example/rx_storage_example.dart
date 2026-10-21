import 'package:rx_storage/rx_storage.dart';

Future<void> main() async {
  final adapter = InMemoryStorage<String>();
  final rxStorage = RxStorage<String, void>(adapter);

  try {
    final key = 'key';
    rxStorage
        .observe(key, (v) => v as String?)
        .listen((String? s) => print('[Observe 1] Value: $s'));
    rxStorage
        .observe(key, (v) => v as String?)
        .listen((String? s) => print('[Observe 2] Value: $s'));

    await Future<void>.delayed(const Duration(milliseconds: 1));
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

    await Future<void>.delayed(const Duration(milliseconds: 500));
  } finally {
    await rxStorage.dispose();
  }
}
