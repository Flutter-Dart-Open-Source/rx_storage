import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

import '../async_memoizer.dart';
import '../interface/rx_storage.dart';
import '../interface/storage.dart';
import '../logger/logger.dart';
import '../model/key_and_value.dart';

// ignore_for_file: unnecessary_null_comparison

/// Default [RxStorage] implementation.
class RealRxStorage<Key extends Object, Options,
    S extends Storage<Key, Options>> implements RxStorage<Key, Options> {
  static const _initialKeyValue =
      KeyAndValue('RealRxStorage', 'hoc081098@gmail.com');

  /// Trigger subject
  final _keyValuesSubject = PublishSubject<Map<Key, Object?>>();

  final _disposeMemo = AsyncMemoizer<void>();

  var _isDisposed = false;

  /// Logger subscription. Nullable
  StreamSubscription<Map<Key, Object?>>? _subscription;

  /// Nullable.
  S? _storage;

  late Future<S> _storageFuture;

  /// Nullable
  final Logger? _logger;

  /// Nullable
  final void Function()? _onDispose;

  /// Construct a [RealRxStorage].
  RealRxStorage(
    FutureOr<S> storageOrFuture, [
    this._logger,
    this._onDispose,
  ]) : assert(storageOrFuture != null) {
    if (storageOrFuture is Future<S>) {
      _storageFuture = storageOrFuture.then((value) => _storage = value);
    } else {
      _storage = storageOrFuture;
    }

    _subscription = _logger?.let((logger) {
      _keyValuesSubject.listen((map) {
        final pairs = [
          for (final entry in map.entries)
            KeyAndValue<Key, Object?>(
              entry.key,
              entry.value,
            ),
        ];
        logger.keysChanged(UnmodifiableListView(pairs));
      });
    });
  }

  //
  // Internal
  //

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_isDisposed && _disposeMemo.hasRun) {
        throw StateError('A $runtimeType was used after being disposed.\n'
            'Once you have called dispose() on a $runtimeType, it can no longer be used.');
      }
      return true;
    }());
    return true;
  }

  /// Add changed map to subject to trigger.
  @protected
  void sendChange(Map<Key, Object?> map) {
    try {
      _keyValuesSubject.add(map);
    } on StateError {
      assert(_debugAssertNotDisposed());
    }
  }

  /// Calling [block] with [S] as argument.
  @protected
  Future<R> useStorage<R>(Future<R> Function(S) block) =>
      _storage?.let(block) ?? _storageFuture.then(block);

  // Get and set methods (implements [Storage])

  @override
  Future<bool> containsKey(Key key, [Options? options]) async {
    assert(_debugAssertNotDisposed());
    assert(key != null);

    return useStorage((s) => s.containsKey(key, options));
  }

  @override
  Future<T?> read<T extends Object>(Key key, Decoder<T?> decoder,
      [Options? options]) async {
    assert(_debugAssertNotDisposed());
    assert(key != null);
    assert(decoder != null);

    final value = await useStorage((s) => s.read(key, decoder, options));
    _logger?.readValue(T, key, value);
    return value;
  }

  @override
  Future<Map<Key, Object?>> readAll([Options? options]) async {
    assert(_debugAssertNotDisposed());

    final all = await useStorage((s) => s.readAll(options));
    _logger?.let((logger) {
      all.forEach((key, value) => logger.readValue(dynamic, key, value));
    });
    return all;
  }

  @override
  Future<bool> clear([Options? options]) async {
    assert(_debugAssertNotDisposed());

    final keys = (await readAll()).keys;
    final result = await useStorage((s) => s.clear(options));

    // All values are set to null
    _logger?.let((logger) {
      for (final key in keys) {
        logger.writeValue(dynamic, key, null, result);
      }
    });
    if (result) {
      final map = {for (final k in keys) k: null};
      sendChange(map);
    }

    return result;
  }

  @override
  Future<bool> remove(Key key, [Options? options]) async {
    assert(_debugAssertNotDisposed());
    assert(key != null);

    final result = await useStorage((s) => s.remove(key, options));

    _logger?.writeValue(dynamic, key, null, result);
    if (result) {
      sendChange({key: null});
    }

    return result;
  }

  @override
  Future<bool> write<T extends Object>(Key key, T? value, Encoder<T?> encoder,
      [Options? options]) async {
    assert(_debugAssertNotDisposed());
    assert(key != null);
    assert(encoder != null);

    final result =
        await useStorage((s) => s.write(key, value, encoder, options));

    _logger?.writeValue(T, key, value, result);
    if (result) {
      sendChange({key: value});
    }

    return result;
  }

  // Get streams (implements [RxStorage])

  @override
  Stream<T?> observe<T extends Object>(Key key, Decoder<T?> decoder,
      [Options? options]) {
    assert(_debugAssertNotDisposed());
    assert(key != null);

    final stream = _keyValuesSubject
        .toSingleSubscriptionStream()
        .mapNotNull((map) => map.containsKey(key)
            ? KeyAndValue<Object, Object?>(key, map[key])
            : null)
        .startWith(_initialKeyValue) // Dummy value to trigger initial load.
        .asyncMap<T?>(
          (entry) => identical(entry, _initialKeyValue)
              ? read<T>(key, decoder, options)
              : entry.value as FutureOr<T?>,
        );

    return _logger?.let((logger) {
          return stream
              .doOnData(
                  (value) => logger.doOnDataStream(KeyAndValue(key, value)))
              .doOnError(
                  (e, s) => logger.doOnErrorStream(e, s ?? StackTrace.current));
        }) ??
        stream;
  }

  @override
  Stream<Map<Key, Object?>> observeAll([Options? options]) {
    assert(_debugAssertNotDisposed());

    return _keyValuesSubject
        .toSingleSubscriptionStream()
        .startWith(const {}).asyncMap((_) => readAll(options));
  }

  @override
  Future<void> dispose() {
    assert(_debugAssertNotDisposed());

    return _disposeMemo.runOnce(() async {
      final cancelFuture = _subscription?.cancel();

      if (cancelFuture == null) {
        await _keyValuesSubject.close();
      } else {
        await Future.wait(
          [_keyValuesSubject.close(), cancelFuture],
          eagerError: true,
        );
      }

      _isDisposed = true;
      _onDispose?.call();
    });
  }
}

/// Scope function extension
extension _ScopeFunctionExtension<T> on T {
  /// Returns result from calling [f].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  R let<R>(R Function(T) f) => f(this);
}
