import 'dart:async';

import 'package:disposebag/disposebag.dart' hide Logger;
import 'package:meta/meta.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

import '../async_memoizer.dart';
import '../interface/rx_storage.dart';
import '../interface/storage.dart';
import '../logger/event.dart';
import '../logger/logger.dart';
import '../model/error.dart';
import '../model/key_and_value.dart';

// ignore_for_file: unnecessary_null_comparison

/// Default [RxStorage] implementation.
class RealRxStorage<Key extends Object, Options,
    S extends Storage<Key, Options>> implements RxStorage<Key, Options> {
  static const _initialKeyValue =
      KeyAndValue('rx_storage', 'Petrus Nguyen Thai Hoc <hoc081098@gmail.com>');

  /// Trigger subject
  final _keyValuesSubject = PublishSubject<Map<Key, Object?>>();

  final _disposeMemo = AsyncMemoizer<void>();
  final _bag = DisposeBag();

  /// Logger controller. Nullable
  StreamController<LoggerEvent<Key, Options>>? _loggerEventController;

  /// Nullable.
  S? _storage;

  late Future<S> _storageFuture;

  /// Nullable
  final void Function()? _onDispose;

  /// Construct a [RealRxStorage].
  RealRxStorage(
    FutureOr<S> storageOrFuture, [
    final Logger<Key, Options>? logger,
    this._onDispose,
  ]) : assert(storageOrFuture != null) {
    if (storageOrFuture is Future<S>) {
      _storageFuture = storageOrFuture.then((value) => _storage = value);
    } else {
      _storage = storageOrFuture;
    }

    _keyValuesSubject.disposedBy(_bag);
    logger?.let(_setupLogger);
  }

  //
  // Internal
  //

  void _setupLogger(Logger logger) {
    _loggerEventController = StreamController(sync: true)
      ..disposedBy(_bag)
      ..stream.listen(logger.log).disposedBy(_bag);

    _keyValuesSubject
        .map<LoggerEvent<Key, Options>>((map) {
          final pairs =
              map.entries.map((e) => KeyAndValue<Key, Object?>(e.key, e.value));
          return KeysChangedEvent(List.unmodifiable(pairs));
        })
        .listen(_loggerEventController!.add)
        .disposedBy(_bag);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  bool get _isLogEnabled => _loggerEventController != null;

  /// Crash if [_loggerEventController] is null.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _publishLog(LoggerEvent<Key, Options> event) {
    assert(_debugAssertNotDisposed());

    try {
      _loggerEventController!.add(event);
    } on StateError {
      assert(_debugAssertNotDisposed());
    }
  }

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_bag.isDisposed && _disposeMemo.hasRun) {
        throw StateError('A $runtimeType was used after being disposed.\n'
            'Once you have called dispose() on a $runtimeType, it can no longer be used.');
      }
      return true;
    }());
    return true;
  }

  /// Calling [block] with [S] as argument.
  Future<R> _useStorageWithHandlers<R>(
    Future<R> Function(S) block,
    void Function(R) onSuccess,
    void Function(RxStorageError) onFailure,
  ) async {
    try {
      final value = await useStorage(block);
      onSuccess(value);
      return value;
    } catch (e, s) {
      onFailure(RxStorageError(e, s));
      rethrow;
    }
  }

  //
  // Protected
  //

  /// Add changed map to subject to trigger.
  @protected
  void sendChange(Map<Key, Object?> map) {
    assert(_debugAssertNotDisposed());

    if (map.isEmpty) {
      return;
    }

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

  //
  // Get and set methods (implements [Storage])
  //

  @override
  Future<bool> containsKey(Key key, [Options? options]) async {
    assert(_debugAssertNotDisposed());
    assert(key != null);

    return await useStorage((s) => s.containsKey(key, options));
  }

  @override
  Future<T?> read<T extends Object>(Key key, Decoder<T?> decoder,
      [Options? options]) {
    assert(_debugAssertNotDisposed());
    assert(key != null);
    assert(decoder != null);

    return _useStorageWithHandlers(
      (s) => s.read(key, decoder, options),
      (value) {
        if (_isLogEnabled) {
          _publishLog(ReadValueSuccessEvent(KeyAndValue(key, value), options));
        }
      },
      (error) {
        if (_isLogEnabled) {
          _publishLog(ReadValueFailureEvent(key, error, options));
        }
      },
    );
  }

  @override
  Future<Map<Key, Object?>> readAll([Options? options]) {
    assert(_debugAssertNotDisposed());

    return _useStorageWithHandlers(
      (s) => s.readAll(options),
      (value) {
        if (_isLogEnabled) {
          _publishLog(ReadAllSuccessEvent(value, options));
        }
      },
      (error) {
        if (_isLogEnabled) {
          _publishLog(ReadAllFailureEvent(error, options));
        }
      },
    );
  }

  @override
  Future<void> clear([Options? options]) async {
    assert(_debugAssertNotDisposed());

    final keys = (await useStorage((s) => s.readAll(options))).keys;

    return await _useStorageWithHandlers(
      (s) => s.clear(options),
      (_) {
        sendChange({for (final k in keys) k: null});
        if (_isLogEnabled) {
          _publishLog(ClearSuccessEvent(options));
        }
      },
      (error) {
        if (_isLogEnabled) {
          _publishLog(ClearFailureEvent(error, options));
        }
      },
    );
  }

  @override
  Future<void> remove(Key key, [Options? options]) {
    assert(_debugAssertNotDisposed());
    assert(key != null);

    return _useStorageWithHandlers(
      (s) => s.remove(key, options),
      (_) {
        sendChange({key: null});
        if (_isLogEnabled) {
          _publishLog(RemoveSuccessEvent(key, options));
        }
      },
      (error) {
        if (_isLogEnabled) {
          _publishLog(RemoveFailureEvent(key, options, error));
        }
      },
    );
  }

  @override
  Future<void> write<T extends Object>(Key key, T? value, Encoder<T?> encoder,
      [Options? options]) {
    assert(_debugAssertNotDisposed());
    assert(key != null);
    assert(encoder != null);

    return _useStorageWithHandlers(
      (s) => s.write(key, value, encoder, options),
      (_) {
        sendChange({key: value});
        if (_isLogEnabled) {
          _publishLog(WriteSuccessEvent(key, value, options));
        }
      },
      (error) {
        if (_isLogEnabled) {
          _publishLog(WriteFailureEvent(key, value, options, error));
        }
      },
    );
  }

  //
  // Get streams (implements [RxStorage])
  //

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
              ? useStorage((s) => s.read<T>(key, decoder, options))
              : entry.value as FutureOr<T?>,
        );

    return _isLogEnabled
        ? stream
            .doOnData((value) =>
                _publishLog(OnDataStreamEvent(KeyAndValue(key, value))))
            .doOnError((e, s) => _publishLog(
                OnErrorStreamEvent(RxStorageError(e, s ?? StackTrace.empty))))
        : stream;
  }

  @override
  Stream<Map<Key, Object?>> observeAll([Options? options]) {
    assert(_debugAssertNotDisposed());

    return _keyValuesSubject
        .toSingleSubscriptionStream()
        .mapTo<void>(null)
        .startWith(null)
        .asyncMap((_) => useStorage((s) => s.readAll(options)));
  }

  @override
  Future<void> dispose() {
    assert(_debugAssertNotDisposed());

    return _disposeMemo.runOnce(_bag.dispose).then((_) => _onDispose?.call());
  }
}

/// Scope function extension
extension _ScopeFunctionExtension<T> on T {
  /// Returns result from calling [f].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  R let<R>(R Function(T) block) => block(this);
}
