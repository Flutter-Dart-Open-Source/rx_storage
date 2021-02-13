import 'dart:async';

import 'package:rx_storage/rx_storage.dart';

import 'utils/synchronous_future.dart';

Future<T> _wrap<T>(T value) => SynchronousFuture(value);

abstract class StringKeyStorage extends Storage<String, void> {
  Future<Map<String, Object?>> reload();
}

abstract class StringKeyRxStorage extends StringKeyStorage
    implements RxStorage<String, void> {}

class FakeDefaultLogger extends DefaultLogger<String, void> {
  const FakeDefaultLogger();

  @override
  void log(LoggerEvent<String, void> event) {
    if (event is ReloadSuccessEvent) {
      print('ReloadSuccessEvent ${event.map}');
      return;
    }
    if (event is ReloadFailureEvent) {
      print('ReloadFailureEvent ${event.error}');
      return;
    }

    super.log(event);
  }
}

class ReloadSuccessEvent implements LoggerEvent<String, void> {
  final Map<String, Object?> map;

  ReloadSuccessEvent(this.map);
}

class ReloadFailureEvent implements LoggerEvent<String, void> {
  final RxStorageError error;

  ReloadFailureEvent(this.error);
}

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
  Future<Map<String, Object?>> reload() {
    if (_pendingMap != null) {
      _map = _pendingMap!;
      _pendingMap = null;
      return _wrap(_map);
    } else {
      throw StateError('Cannot reload');
    }
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
    implements StringKeyRxStorage, StringKeyStorage {
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
  Future<Map<String, Object?>> reload() async {
    final handler = (Object? _, Object? __) => null;
    final before =
        await useStorageWithHandlers((s) => s.readAll(), handler, handler);

    return useStorageWithHandlers(
      (s) => s.reload(),
      (value, s) {
        sendChange(computeMap(before, value));
        log(ReloadSuccessEvent(value));
      },
      (error, _) => log(ReloadFailureEvent(error)),
    );
  }
}

Map<String, Object?> computeMap(
  Map<String, Object?> before,
  Map<String, Object?> after,
) {
  final deletedKeys = before.keys.toSet().difference(after.keys.toSet());
  return <String, Object?>{
    ...after,
    for (final k in deletedKeys) k: null,
  };
}
