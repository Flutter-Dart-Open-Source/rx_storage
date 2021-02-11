import 'dart:async';

import 'package:rx_storage/rx_storage.dart';
import 'package:rx_storage/src/interface/storage.dart';

import 'utils/synchronous_future.dart';

Future<T> _wrap<T>(T value) => SynchronousFuture(value);

abstract class StringKeyStorage extends Storage<String, void> {
  Future<void> reload();
}

abstract class StringKeyRxStorage extends StringKeyStorage
    implements RxStorage<String, void> {}

class FakeStorage implements StringKeyStorage {
  Map<String, Object?> _map;
  Map<String, Object?>? _pendingMap;

  FakeStorage(Map<String, Object?> map) : _map = Map<String, Object?>.of(map);

  set map(Map<String, Object?> map) =>
      _pendingMap = Map<String, Object?>.of(map);

  Future<bool> _setValue(String key, Object? value) {
    if (value is List<String>?) {
      _map[key] = value?.toList();
    } else {
      _map[key] = value;
    }
    return _wrap(true);
  }

  Future<T?> _getValue<T>(String key) {
    final value = _map[key] as T?;
    return value is List<String> ? _wrap(value.toList() as T) : _wrap(value);
  }

  //
  //
  //

  @override
  Future<void> clear([void _]) {
    _map.clear();
    return _wrap(true);
  }

  @override
  Future<bool> containsKey(String key, [void _]) =>
      _wrap(_map.containsKey(key));

  @override
  Future<void> write<T extends Object>(
          String key, T? value, Encoder<T?> encoder,
          [void _]) =>
      _setValue(key, encoder(value));

  @override
  Future<void> reload() {
    if (_pendingMap != null) {
      _map = _pendingMap!;
      _pendingMap = null;
    }
    return _wrap(null);
  }

  @override
  Future<void> remove(String key, [void _]) => _setValue(key, null);

  @override
  Future<T?> read<T extends Object>(String key, Decoder<T?> decoder,
          [void _]) =>
      _getValue<Object>(key).then(decoder);

  @override
  Future<Map<String, Object?>> readAll([void _]) =>
      _wrap(<String, Object?>{..._map});
}

class FakeRxStorage extends RealRxStorage<String, void, StringKeyStorage>
    implements StringKeyRxStorage {
  FakeRxStorage(
    FutureOr<StringKeyStorage> storageOrFuture, [
    Logger<String, void>? logger,
    void Function()? onDispose,
  ]) : super(
          storageOrFuture,
          logger,
          onDispose,
        );

  @override
  Future<void> reload() async {
    await useStorage((s) => s.reload());
    sendChange(await readAll());
  }
}
