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

void main() async {
  final adapter = InMemoryStorageAdapter();
  final rxStorage = RxStorage<String, void>(adapter);

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
  await rxStorage.dispose();
}
