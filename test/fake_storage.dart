import 'dart:async';

import 'package:rx_storage/rx_storage.dart';
import 'package:rx_storage/src/interface/storage.dart';

import 'utils/synchronous_future.dart';

Future<T> _wrap<T>(T value) => SynchronousFuture(value);

abstract class StringKeyStorage extends Storage<String> {
  Future<void> reload();
}

abstract class StringKeyRxStorage extends StringKeyStorage
    implements RxStorage<String> {}

class FakeStorage implements StringKeyStorage {
  Map<String, dynamic> _map;
  Map<String, dynamic> _pendingMap;

  FakeStorage(Map<String, dynamic> map) : _map = Map.of(map);

  set map(Map<String, dynamic> map) => _pendingMap = Map.of(map);

  Future<bool> _setValue(String key, dynamic value) {
    if (value is List<String>) {
      _map[key] = value?.toList();
    } else {
      _map[key] = value;
    }
    return _wrap(true);
  }

  Future<T> _getValue<T>(String key) {
    final value = _map[key] as T;
    return value is List<String>
        ? _wrap(value.toList() as dynamic)
        : _wrap(value);
  }

  //
  //
  //

  @override
  Future<bool> clear() {
    _map.clear();
    return _wrap(true);
  }

  @override
  Future<bool> containsKey(String key) => _wrap(_map.containsKey(key));

  @override
  Future<bool> write<T>(String key, T value, Encoder<T> encoder) =>
      _setValue(key, encoder(value));

  @override
  Future<void> reload() {
    if (_pendingMap != null) {
      _map = _pendingMap;
      _pendingMap = null;
    }
    return _wrap(null);
  }

  @override
  Future<bool> remove(String key) => _setValue(key, null);

  @override
  Future<T> read<T>(String key, Decoder<T> decoder) =>
      _getValue(key).then(decoder);

  @override
  Future<Map<String, dynamic>> readAll() => _wrap({..._map});
}

class FakeRxStorage extends RealRxStorage<String>
    implements StringKeyRxStorage {
  final FutureOr<StringKeyStorage> storageOrFuture;
  final Logger logger;

  FakeRxStorage(
    this.storageOrFuture, [
    this.logger,
    void Function() onDispose,
  ]) : super(
          storageOrFuture,
          logger,
          onDispose,
        );

  @override
  Future<void> reload() async {
    final s = await storageOrFuture;
    await s.reload();

    final map = await s.readAll();
    sendChange(map);
    if (logger != null) {
      map.forEach((key, value) => logger.readValue(dynamic, key, value));
    }
  }
}
