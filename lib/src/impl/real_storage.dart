import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import '../async_memoizer.dart';
import '../interface/rx_storage.dart';
import '../interface/storage.dart';
import '../logger/logger.dart';
import '../model/key_and_value.dart';
import '../stream_extensions/map_not_null.dart';
import '../stream_extensions/single_subscription.dart';

/// Default [RxStorage] implementation.
class RealRxStorage<Key> implements RxStorage<Key> {
  /// Trigger subject
  final _keyValuesSubject = PublishSubject<Map<Key, dynamic>>();

  final _disposeMemo = AsyncMemoizer<void>();

  /// Logger subscription. Nullable
  StreamSubscription<Map<Key, dynamic>> _subscription;

  /// Nullable.
  Storage<Key> _storage;

  /// Nullable.
  Future<Storage<Key>> _storageFuture;

  /// Nullable
  final Logger _logger;

  /// Nullable
  final void Function() _onDispose;

  /// Construct a [RealRxStorage].
  RealRxStorage(
    FutureOr<Storage<Key>> storageOrFuture, [
    this._logger,
    this._onDispose,
  ]) : assert(storageOrFuture != null) {
    if (storageOrFuture is Future<Storage<Key>>) {
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

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_disposeMemo.hasRun) {
        throw StateError('A $runtimeType was used after being disposed.\n'
            'Once you have called dispose() on a $runtimeType, it can no longer be used.');
      }
      return true;
    }());
    return true;
  }

  /// Add changed map to subject to trigger.
  @protected
  void sendChange(Map<Key, dynamic> map) {
    try {
      _keyValuesSubject.add(map);
    } catch (e) {
      assert(_debugAssertNotDisposed());
    }
  }

  // Get and set methods (implements [Storage])

  @override
  Future<bool> containsKey(Key key) async {
    assert(_debugAssertNotDisposed());
    assert(key != null);

    final storage = _storage ?? await _storageFuture;
    return storage.containsKey(key);
  }

  @override
  Future<T> read<T>(Key key, Decoder<T> decoder) async {
    assert(_debugAssertNotDisposed());

    final storage = _storage ?? await _storageFuture;
    final value = await storage.read(key, decoder);

    _logger?.readValue(T, key, value);
    return value;
  }

  @override
  Future<Map<Key, dynamic>> readAll() async {
    assert(_debugAssertNotDisposed());

    final storage = _storage ?? await _storageFuture;
    final all = await storage.readAll();

    if (_logger != null) {
      all.forEach((key, value) => _logger.readValue(dynamic, key, value));
    }
    return all;
  }

  @override
  Future<bool> clear() async {
    assert(_debugAssertNotDisposed());

    final storage = _storage ?? await _storageFuture;
    final keys = (await readAll()).keys;
    final result = await storage.clear();

    // All values are set to null
    if (_logger != null) {
      for (final key in keys) {
        _logger.writeValue(dynamic, key, null, result);
      }
    }
    if (result ?? false) {
      final map = {for (final k in keys) k: null};
      sendChange(map);
    }

    return result;
  }

  @override
  Future<bool> remove(Key key) async {
    assert(_debugAssertNotDisposed());

    final storage = _storage ?? await _storageFuture;
    final result = await storage.remove(key);

    _logger?.writeValue(dynamic, key, null, result);
    if (result ?? false) {
      sendChange({key: null});
    }

    return result;
  }

  @override
  Future<bool> write<T>(Key key, T value, Encoder<T> encoder) async {
    assert(_debugAssertNotDisposed());

    final storage = _storage ?? await _storageFuture;
    final result = await storage.write(key, value, encoder);

    _logger?.writeValue(T, key, value, result);
    if (result ?? false) {
      sendChange({key: value});
    }

    return result;
  }

  // Get streams (implements [RxStorage])

  @override
  Stream<T> observe<T>(Key key, Decoder<T> decoder) {
    assert(_debugAssertNotDisposed());

    final stream = _keyValuesSubject
        .toSingleSubscriptionStream()
        .mapNotNull(
            (map) => map.containsKey(key) ? KeyAndValue(key, map[key]) : null)
        .startWith(null) // Dummy value to trigger initial load.
        .asyncMap<T>((entry) =>
            entry == null ? read<T>(key, decoder) : entry.value as T);

    if (_logger == null) {
      return stream;
    }

    return stream
        .doOnData((value) => _logger.doOnDataStream(KeyAndValue(key, value)))
        .doOnError((e, StackTrace s) => _logger.doOnErrorStream(e, s));
  }

  @override
  Stream<Map<Key, dynamic>> observeAll() {
    assert(_debugAssertNotDisposed());

    return _keyValuesSubject
        .toSingleSubscriptionStream()
        .startWith(null)
        .asyncMap((_) => readAll());
  }

  @override
  Future<void> dispose() {
    return _disposeMemo.runOnce(() async {
      assert(_debugAssertNotDisposed());

      final cancelFuture = _subscription?.cancel();

      if (cancelFuture == null) {
        await _keyValuesSubject.close();
      } else {
        await Future.wait(
          [_keyValuesSubject.close(), cancelFuture],
          eagerError: true,
        );
      }

      _onDispose?.call();
    });
  }
}
