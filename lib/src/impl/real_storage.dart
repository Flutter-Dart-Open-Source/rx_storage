import 'dart:async';

import 'package:disposebag/disposebag.dart' hide Logger;
import 'package:meta/meta.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

import '../async/async_memoizer.dart';
import '../async/async_queue.dart';
import '../interface/rx_storage.dart';
import '../interface/storage.dart';
import '../logger/event.dart';
import '../logger/logger.dart';
import '../model/error.dart';
import '../model/key_and_value.dart';
import '../util.dart';

/// Default [RxStorage] implementation.
class RealRxStorage<Key extends Object, Options,
    S extends Storage<Key, Options>> implements RxStorage<Key, Options> {
  static const _initialKeyValue = KeyAndValue<Object, Object>(
      'rx_storage', 'Petrus Nguyen Thai Hoc <hoc081098@gmail.com>', String);

  /// Trigger subject
  final _keyValuesSubject =
      PublishSubject<Map<Key, KeyAndValue<Key, Object?>>>();

  /// Write queue.
  /// Basic lock mechanism to prevent concurrent access to asynchronous code.
  final _writeQueueResources = <Object, AsyncQueue<Object?>>{};

  final _disposeMemo = AsyncMemoizer<void>();
  late final _bag =
      DisposeBag(const <Object>[], 'RealRxStorage#${shortHash(this)}');

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
  ]) {
    if (storageOrFuture is Future<S>) {
      _storageFuture = storageOrFuture.then((value) {
        assert(_storage is! RxStorage<Key, Options>);
        return _storage = value;
      });
    } else {
      _storage = storageOrFuture;
      assert(_storage is! RxStorage<Key, Options>);
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
        .map<LoggerEvent<Key, Options>>(
            (map) => KeysChangedEvent(map.toListOfKeyAndValues()))
        .listen(_loggerEventController!.add)
        .disposedBy(_bag);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  bool get _isLogEnabled => _loggerEventController != null;

  /// Crash if [_loggerEventController] is null.
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
  Future<R> _useStorage<R>(Future<R> Function(S) block) =>
      _storage?.let(block) ?? _storageFuture.then(block);

  Future<T> _enqueueWritingTask<T>(Object key, AsyncQueueBlock<T> block) {
    return _writeQueueResources
        .putIfAbsent(
          key,
          () => AsyncQueue<Object?>(
              () => _writeQueueResources.remove(key)?.dispose()),
        )
        .enqueue(block)
        .then((value) => value as T);
  }

  Future<void> _writeWithoutSynchronization<T extends Object>(
    Key key,
    T? value,
    Encoder<T?> encoder,
    Options? options,
  ) {
    return useStorageWithHandlers(
      (s) => s.write<T>(key, value, encoder, options),
      (_, __) {
        final keyAndValue = KeyAndValue(key, value, T);

        sendChange({key: keyAndValue});

        if (_isLogEnabled) {
          _publishLog(WriteSuccessEvent(keyAndValue, options));
        }
      },
      (error, __) {
        if (_isLogEnabled) {
          _publishLog(
              WriteFailureEvent(KeyAndValue(key, value, T), options, error));
        }
      },
    );
  }

  //
  // Protected
  //

  /// Calling [block] with [S] as argument.
  @protected
  @nonVirtual
  Future<R> useStorageWithHandlers<R>(
    Future<R> Function(S) block,
    FutureOr<void> Function(R, S)? onSuccess,
    FutureOr<void> Function(RxStorageError, S)? onFailure,
  ) async {
    assert(_debugAssertNotDisposed());

    final storage = _storage ?? await _storageFuture;
    if (onSuccess == null && onFailure == null) {
      return await block(storage);
    }

    try {
      final value = await block(storage);
      final futureOrVoid = onSuccess?.call(value, storage);
      if (futureOrVoid is Future<void>) {
        await futureOrVoid;
      }
      return value;
    } catch (e, s) {
      final futureOrVoid = onFailure?.call(RxStorageError(e, s), storage);
      if (futureOrVoid is Future<void>) {
        await futureOrVoid;
      }
      rethrow;
    }
  }

  /// Add changed map to subject to trigger.
  @protected
  @nonVirtual
  void sendChange(Map<Key, KeyAndValue<Key, Object?>> map) {
    assert(_debugAssertNotDisposed());

    try {
      _keyValuesSubject.add(map);
    } on StateError {
      assert(_debugAssertNotDisposed());
    }
  }

  /// Log event if logging is enabled.
  @protected
  @nonVirtual
  void logIfEnabled(LoggerEvent<Key, Options> Function() eventProducer) {
    assert(_debugAssertNotDisposed());

    if (_isLogEnabled) {
      _publishLog(eventProducer());
    }
  }

  /// Enqueue writing task to a [AsyncQueue].
  @protected
  @nonVirtual
  Future<T> enqueueWritingTask<T>(Key? key, AsyncQueueBlock<T> block) =>
      _enqueueWritingTask(key ?? this, block);

  //
  // Get and set methods (implements [Storage])
  //

  @nonVirtual
  @override
  Future<bool> containsKey(Key key, [Options? options]) async {
    assert(_debugAssertNotDisposed());

    return await _useStorage((s) => s.containsKey(key, options));
  }

  @nonVirtual
  @override
  Future<T?> read<T extends Object>(Key key, Decoder<T?> decoder,
      [Options? options]) {
    assert(_debugAssertNotDisposed());

    return useStorageWithHandlers(
      (s) => s.read(key, decoder, options),
      (value, _) {
        if (_isLogEnabled) {
          _publishLog(
              ReadValueSuccessEvent(KeyAndValue(key, value, T), options));
        }
      },
      (error, _) {
        if (_isLogEnabled) {
          _publishLog(ReadValueFailureEvent(key, T, error, options));
        }
      },
    );
  }

  @nonVirtual
  @override
  Future<Map<Key, Object?>> readAll([Options? options]) {
    assert(_debugAssertNotDisposed());

    return useStorageWithHandlers(
      (s) => s.readAll(options),
      (value, _) {
        if (_isLogEnabled) {
          _publishLog(
              ReadAllSuccessEvent(value.toListOfKeyAndValues(), options));
        }
      },
      (error, _) {
        if (_isLogEnabled) {
          _publishLog(ReadAllFailureEvent(error, options));
        }
      },
    );
  }

  @nonVirtual
  @override
  Future<void> clear([Options? options]) {
    assert(_debugAssertNotDisposed());

    return _enqueueWritingTask(this, () async {
      final keys = (await _useStorage((s) => s.readAll(options))).keys;

      return await useStorageWithHandlers(
        (s) => s.clear(options),
        (_, __) {
          sendChange({for (final k in keys) k: KeyAndValue(k, null, Null)});

          if (_isLogEnabled) {
            _publishLog(ClearSuccessEvent(options));
          }
        },
        (error, _) {
          if (_isLogEnabled) {
            _publishLog(ClearFailureEvent(error, options));
          }
        },
      );
    });
  }

  @nonVirtual
  @override
  Future<void> remove(Key key, [Options? options]) {
    assert(_debugAssertNotDisposed());

    return _enqueueWritingTask(key, () {
      return useStorageWithHandlers(
        (s) => s.remove(key, options),
        (_, __) {
          sendChange({key: KeyAndValue(key, null, Null)});

          if (_isLogEnabled) {
            _publishLog(RemoveSuccessEvent(key, options));
          }
        },
        (error, _) {
          if (_isLogEnabled) {
            _publishLog(RemoveFailureEvent(key, options, error));
          }
        },
      );
    });
  }

  @nonVirtual
  @override
  Future<void> write<T extends Object>(Key key, T? value, Encoder<T?> encoder,
      [Options? options]) {
    assert(_debugAssertNotDisposed());

    return _enqueueWritingTask(key,
        () => _writeWithoutSynchronization<T>(key, value, encoder, options));
  }

  //
  // Get streams (implements [RxStorage])
  //

  @experimental
  @nonVirtual
  @override
  Future<void> executeUpdate<T extends Object>(
    Key key,
    Decoder<T?> decoder,
    Transformer<T?> transformer,
    Encoder<T?> encoder, [
    Options? options,
  ]) {
    assert(_debugAssertNotDisposed());

    return _enqueueWritingTask<void>(
      key,
      () async {
        // Read
        final value = await read<T>(key, decoder, options);
        // Modify
        final transformed = transformer(value);
        // Write
        await _writeWithoutSynchronization(key, transformed, encoder, options);
      },
    );
  }

  @nonVirtual
  @override
  Stream<T?> observe<T extends Object>(Key key, Decoder<T?> decoder,
      [Options? options]) {
    assert(_debugAssertNotDisposed());

    FutureOr<T?> convert(KeyAndValue<Object, Object?> entry) =>
        identical(entry, _initialKeyValue)
            ? _useStorage((s) => s.read<T>(key, decoder, options))
            : entry.value as FutureOr<T?>;

    final stream = _keyValuesSubject
        .toSingleSubscriptionStream()
        .mapNotNull<KeyAndValue<Object, Object?>>((map) => map[key])
        .startWith(_initialKeyValue) // Dummy value to trigger initial load.
        .asyncMap<T?>(convert);

    return _isLogEnabled
        ? stream
            .doOnData((value) =>
                _publishLog(OnDataStreamEvent(KeyAndValue(key, value, T))))
            .doOnError((e, s) => _publishLog(
                OnErrorStreamEvent(RxStorageError(e, s ?? StackTrace.empty))))
        : stream;
  }

  @nonVirtual
  @override
  Stream<Map<Key, Object?>> observeAll([Options? options]) {
    assert(_debugAssertNotDisposed());

    return _keyValuesSubject
        .toSingleSubscriptionStream()
        .mapTo<void>(null)
        .startWith(null)
        .asyncMap((_) => _useStorage((s) => s.readAll(options)));
  }

  @nonVirtual
  @override
  Future<void> dispose() {
    assert(_debugAssertNotDisposed());

    final dispose = () =>
        Future.wait(_writeQueueResources.values.map((q) => q.dispose()))
            .then((_) => _writeQueueResources.clear())
            .then((_) => _bag.dispose());
    final future = _disposeMemo.runOnce(dispose);
    return _onDispose?.let((onDispose) => future.then((_) => onDispose())) ?? future;
  }
}

/// Scope function extension
extension _ScopeFunctionExtension<T> on T {
  /// Returns result from calling [f].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  R let<R>(R Function(T) block) => block(this);
}
