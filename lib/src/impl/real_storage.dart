import 'dart:async';
import 'dart:collection';

import 'package:rxdart/rxdart.dart';

import '../interface/rx_storage.dart';
import '../interface/storage.dart';
import '../logger/logger.dart';
import '../model/key_and_value.dart';
import '../stream_extensions/map_not_null_stream_transformer.dart';
import '../stream_extensions/single_subscription.dart';

/// Default [RxStorage] implementation
class RealRxStorage implements RxStorage {
  /// Trigger subject
  final _keyValuesSubject = PublishSubject<Map<String, dynamic>>();

  /// Logger subscription. Nullable
  StreamSubscription<Map<String, dynamic>> _subscription;

  /// Nullable.
  Storage _storage;

  /// Nullable.
  Future<Storage> _storageFuture;

  /// Nullable
  final Logger _logger;

  /// Nullable
  final void Function() _onDispose;

  /// Construct a [RealRxStorage].
  RealRxStorage(
    FutureOr<Storage> storageOrFuture, [
    this._logger,
    this._onDispose,
  ]) : assert(storageOrFuture != null) {
    if (storageOrFuture is Future<Storage>) {
      _storageFuture = storageOrFuture.then((value) => _storage = value);
    } else {
      _storageFuture = null;
      _storage = storageOrFuture;
    }

    if (_logger == null) {
      return;
    }

    _subscription = _keyValuesSubject.listen((map) {
      final pairs = [
        for (final entry in map.entries)
          KeyAndValue(
            entry.key,
            entry.value,
          ),
      ];
      _logger.keysChanged(UnmodifiableListView(pairs));
    });
  }

  //
  // Internal
  //

  /// Workaround to capture generics
  static Type _typeOf<T>() => T;

  /// Read value from persistent [storage] by [key].
  static Future<dynamic> _readFromStorage<T>(Storage storage, String key) {
    assert(key != null);

    if (T == dynamic) {
      return storage.get(key);
    }
    if (T == double) {
      return storage.getDouble(key);
    }
    if (T == int) {
      return storage.getInt(key);
    }
    if (T == bool) {
      return storage.getBool(key);
    }
    if (T == String) {
      return storage.getString(key);
    }
    if (T == _typeOf<List<String>>()) {
      return storage.getStringList(key);
    }
    throw StateError('Unhandled type $T');
  }

  /// Write [value] to [storage] associated with [key]
  static Future<bool> _writeToStorage<T>(
    Storage storage,
    String key,
    T value,
  ) {
    assert(key != null);

    if (T == dynamic) {
      assert(value == null);
      return storage.remove(key);
    }

    // TODO(40014): Remove cast when type promotion works.
    // This would normally be `as T` but we use `as dynamic` to make the
    // unneeded check be implicit to match dart2js unsound optimizations in the
    // user code.
    final dynamicVal = value as dynamic;

    if (T == double) {
      return storage.setDouble(key, dynamicVal);
    }
    if (T == int) {
      return storage.setInt(key, dynamicVal);
    }
    if (T == bool) {
      return storage.setBool(key, dynamicVal);
    }
    if (T == String) {
      return storage.setString(key, dynamicVal);
    }
    if (T == _typeOf<List<String>>()) {
      return storage.setStringList(key, dynamicVal);
    }

    throw StateError('Unhandled type $T');
  }

  /// Get [Stream] from the persistent storage
  Stream<T> _getStream<T>(String key) {
    final stream = _keyValuesSubject
        .toSingleSubscriptionStream()
        .mapNotNull(
            (map) => map.containsKey(key) ? KeyAndValue(key, map[key]) : null)
        .startWith(null) // Dummy value to trigger initial load.
        .asyncMap<T>(
            (entry) => entry == null ? _getValue<T>(key) : entry.value as T);

    if (_logger == null) {
      return stream;
    }

    return stream
        .doOnData((value) => _logger.doOnDataStream(KeyAndValue(key, value)))
        .doOnError((e, StackTrace s) => _logger.doOnErrorStream(e, s));
  }

  /// Get value from the persistent [Storage] by [key].
  Future<T> _getValue<T>(String key) async {
    final storage = _storage ?? await _storageFuture;
    final T value = await _readFromStorage<T>(storage, key);

    _logger?.readValue(T, key, value);
    return value;
  }

  /// Set [value] associated with [key].
  Future<bool> _setValue<T>(String key, T value) async {
    final storage = _storage ?? await _storageFuture;
    final result = await _writeToStorage<T>(storage, key, value);

    _logger?.writeValue(T, key, value, result);
    if (result ?? false) {
      _sendKeyValueChanged({key: value});
    }

    return result;
  }

  /// Add pairs to subject to trigger.
  /// Do nothing if subject already closed.
  void _sendKeyValueChanged(Map<String, dynamic> map) {
    try {
      _keyValuesSubject.add(map);
    } catch (e) {
      print(e);
      // Do nothing
    }
  }

  // Get and set methods (implements [Storage])

  @override
  Future<bool> containsKey(String key) async {
    assert(key != null);
    final storage = _storage ?? await _storageFuture;
    return storage.containsKey(key);
  }

  @override
  Future<dynamic> get(String key) => _getValue<dynamic>(key);

  @override
  Future<bool> getBool(String key) => _getValue<bool>(key);

  @override
  Future<double> getDouble(String key) => _getValue<double>(key);

  @override
  Future<int> getInt(String key) => _getValue<int>(key);

  @override
  Future<Set<String>> getKeys() async {
    final storage = _storage ?? await _storageFuture;
    return storage.getKeys();
  }

  @override
  Future<String> getString(String key) => _getValue<String>(key);

  @override
  Future<List<String>> getStringList(String key) =>
      _getValue<List<String>>(key);

  @override
  Future<bool> clear() async {
    final storage = _storage ?? await _storageFuture;
    final keys = await storage.getKeys();
    final result = await storage.clear();

    // All values are set to null
    if (_logger != null) {
      for (final key in keys) {
        _logger.writeValue(dynamic, key, null, result);
      }
    }
    if (result ?? false) {
      final map = {for (final k in keys) k: null};
      _sendKeyValueChanged(map);
    }

    return result;
  }

  @override
  Future<void> reload() async {
    final storage = _storage ?? await _storageFuture;
    await storage.reload();

    final keys = await storage.getKeys();

    // Read new values from storage.
    final map = {for (final k in keys) k: await storage.get(k)};
    if (_logger != null) {
      for (final key in keys) {
        _logger.readValue(dynamic, key, map[key]);
      }
    }
    _sendKeyValueChanged(map);
  }

  @override
  Future<bool> remove(String key) => _setValue<dynamic>(key, null);

  @override
  Future<bool> setBool(String key, bool value) => _setValue<bool>(key, value);

  @override
  Future<bool> setDouble(String key, double value) =>
      _setValue<double>(key, value);

  @override
  Future<bool> setInt(String key, int value) => _setValue<int>(key, value);

  @override
  Future<bool> setString(String key, String value) =>
      _setValue<String>(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _setValue<List<String>>(key, value);

  // Get streams (implements [RxStorage])

  @override
  Stream<dynamic> getStream(String key) => _getStream<dynamic>(key);

  @override
  Stream<bool> getBoolStream(String key) => _getStream<bool>(key);

  @override
  Stream<double> getDoubleStream(String key) => _getStream<double>(key);

  @override
  Stream<int> getIntStream(String key) => _getStream<int>(key);

  @override
  Stream<String> getStringStream(String key) => _getStream<String>(key);

  @override
  Stream<List<String>> getStringListStream(String key) =>
      _getStream<List<String>>(key);

  @override
  Stream<Set<String>> getKeysStream() => _keyValuesSubject
      .toSingleSubscriptionStream()
      .startWith(null)
      .asyncMap((_) => getKeys());

  @override
  Future<void> dispose() async {
    final futures = [_keyValuesSubject.close(), _subscription?.cancel()]
        .where((future) => future != null)
        .toList(growable: false);

    if (futures.length == 1) {
      await futures[0];
    } else {
      await Future.wait(futures);
    }

    _onDispose?.call();
  }
}
