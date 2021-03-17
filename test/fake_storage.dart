import 'dart:async';

import 'package:rx_storage/rx_storage.dart';

import 'utils/synchronous_future.dart';

abstract class StringKeyStorage extends Storage<String, void> {
  Future<Map<String, Object?>> reload();
}

abstract class StringKeyRxStorage extends StringKeyStorage
    implements RxStorage<String, void> {}

abstract class FakeLogger extends Logger<String, void> {}

class FakeDefaultLogger extends DefaultLogger<String, void>
    implements FakeLogger {
  const FakeDefaultLogger();

  @override
  void logOther(LoggerEvent<String, void> event) {
    if (event is ReloadSuccessEvent) {
      print(
          '$tag ${DefaultLogger.rightArrow} ReloadSuccessEvent ${DefaultLogger.rightArrow} ${event.map}');
      return;
    }
    if (event is ReloadFailureEvent) {
      print(
          '$tag ${DefaultLogger.rightArrow} ReloadFailureEvent ${DefaultLogger.rightArrow} ${event.error}');
      return;
    }
    super.logOther(event);
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
  var _throws = false;
  var _readAllThrows = false;

  FakeStorage(Map<String, Object?> map) : _map = Map<String, Object?>.of(map);

  set map(Map<String, Object?> map) =>
      _pendingMap = Map<String, Object?>.of(map);

  set throws(bool b) => _throws = b;

  set readAllThrows(bool b) => _readAllThrows = b;

  Future<T>? _wrapCanThrows<T>(T Function() value) => _throws
      ? Future.error(Exception('Throws...'))
      : SynchronousFuture(value());

  Future<void> _setValue(String key, Object? value) {
    return _wrapCanThrows(() {
      if (value is List<String>?) {
        _map[key] = value?.toList();
      } else {
        _map[key] = value;
      }
    })!;
  }

  Future<T?> _getValue<T>(String key) {
    return _wrapCanThrows(() {
      final value = _map[key] as T?;
      return value is List<String> ? value.toList() as T? : value;
    })!;
  }

  //
  //
  //

  @override
  Future<void> clear([void _]) => _wrapCanThrows(_map.clear)!;

  @override
  Future<bool> containsKey(String key, [void _]) =>
      _wrapCanThrows(() => _map.containsKey(key))!;

  @override
  Future<void> write<T extends Object>(
          String key, T? value, Encoder<T?> encoder,
          [void _]) =>
      _setValue(key, encoder(value));

  @override
  Future<Map<String, Object?>> reload() {
    if (_pendingMap != null) {
      return _wrapCanThrows(() {
        _map = _pendingMap!;
        _pendingMap = null;
        return _map;
      })!;
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
  Future<Map<String, Object?>> readAll([void _]) => _readAllThrows
      ? Future.error(Exception('Cannot read all'))
      : SynchronousFuture(<String, Object?>{..._map});
}

class FakeRxStorage extends RealRxStorage<String, void, StringKeyStorage>
    implements StringKeyRxStorage, StringKeyStorage {
  final _reload = Object();

  FakeRxStorage(
    FutureOr<StringKeyStorage> storageOrFuture, [
    FakeLogger? logger,
    void Function()? onDispose,
  ]) : super(
          storageOrFuture,
          logger,
          onDispose,
        );

  @override
  Future<Map<String, Object?>> reload() {
    return enqueueWritingTask(_reload, () async {
      final handler = (Object? _, Object? __) => null;
      final before =
          await useStorageWithHandlers((s) => s.readAll(), handler, handler);

      return useStorageWithHandlers(
        (s) => s.reload(),
        (value, _) {
          sendChange(computeMap(before, value));
          logIfEnabled(ReloadSuccessEvent(value));
        },
        (error, _) => logIfEnabled(ReloadFailureEvent(error)),
      );
    });
  }
}

Map<String, KeyAndValue<String, Object?>> computeMap(
  Map<String, Object?> before,
  Map<String, Object?> after,
) {
  final deletedKeys = before.keys.toSet().difference(after.keys.toSet());
  return <String, Object?>{
    ...after,
    for (final k in deletedKeys) k: null,
  }.map((key, value) => MapEntry(key, KeyAndValue(key, value, dynamic)));
}
