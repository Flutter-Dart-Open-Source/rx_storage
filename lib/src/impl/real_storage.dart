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

// TODO(assert)
// ignore_for_file: unnecessary_null_comparison

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
  final _writeQueue = AsyncQueue<Object?>();

  final _disposeMemo = AsyncMemoizer<void>();
  late final _bag =
      DisposeBag(const <Object>[], 'RealRxStorage#${_shortHash(this)}');

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

  //
  // Protected
  //

  /// Calling [block] with [S] as argument.
  Future<R> useStorageWithHandlers<R>(
    Future<R> Function(S) block,
    FutureOr<void> Function(R, S) onSuccess,
    FutureOr<void> Function(RxStorageError, S) onFailure,
  ) async {
    assert(_debugAssertNotDisposed());
    assert(block != null);
    assert(onSuccess != null);
    assert(onFailure != null);

    final storage = _storage ?? await _storageFuture;

    try {
      final value = await block(storage);
      final futureOrVoid = onSuccess(value, storage);
      if (futureOrVoid is Future<void>) {
        await futureOrVoid;
      }
      return value;
    } catch (e, s) {
      final futureOrVoid = onFailure(RxStorageError(e, s), storage);
      if (futureOrVoid is Future<void>) {
        await futureOrVoid;
      }
      rethrow;
    }
  }

  /// Add changed map to subject to trigger.
  @protected
  void sendChange(Map<Key, KeyAndValue<Key, Object?>> map) {
    assert(_debugAssertNotDisposed());
    assert(map != null);

    try {
      _keyValuesSubject.add(map);
    } on StateError {
      assert(_debugAssertNotDisposed());
    }
  }

  /// Log event if logging is enabled.
  @protected
  void logIfEnabled(LoggerEvent<Key, Options> event) {
    assert(_debugAssertNotDisposed());
    assert(event != null);

    if (_isLogEnabled) {
      _publishLog(event);
    }
  }

  /// Enqueue writing task to a [AsyncQueue].
  @protected
  Future<T> enqueueWritingTask<T>(AsyncQueueBlock<T> block) =>
      _writeQueue.enqueue(block).then((value) => value as T);

  //
  // Get and set methods (implements [Storage])
  //

  @override
  Future<bool> containsKey(Key key, [Options? options]) async {
    assert(_debugAssertNotDisposed());
    assert(key != null);

    return await _useStorage((s) => s.containsKey(key, options));
  }

  @override
  Future<T?> read<T extends Object>(Key key, Decoder<T?> decoder,
      [Options? options]) {
    assert(_debugAssertNotDisposed());
    assert(key != null);
    assert(decoder != null);

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

  @override
  Future<void> clear([Options? options]) {
    assert(_debugAssertNotDisposed());

    return enqueueWritingTask(() async {
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

  @override
  Future<void> remove(Key key, [Options? options]) {
    assert(_debugAssertNotDisposed());
    assert(key != null);

    return enqueueWritingTask(() {
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

  @override
  Future<void> write<T extends Object>(Key key, T? value, Encoder<T?> encoder,
      [Options? options]) {
    assert(_debugAssertNotDisposed());
    assert(key != null);
    assert(encoder != null);

    return enqueueWritingTask(() {
      return useStorageWithHandlers(
        (s) => s.write(key, value, encoder, options),
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
    });
  }

  //
  // Get streams (implements [RxStorage])
  //

  @override
  Stream<T?> observe<T extends Object>(Key key, Decoder<T?> decoder,
      [Options? options]) {
    assert(_debugAssertNotDisposed());
    assert(key != null);

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

  @override
  Stream<Map<Key, Object?>> observeAll([Options? options]) {
    assert(_debugAssertNotDisposed());

    return _keyValuesSubject
        .toSingleSubscriptionStream()
        .mapTo<void>(null)
        .startWith(null)
        .asyncMap((_) => _useStorage((s) => s.readAll(options)));
  }

  @override
  Future<void> dispose() {
    assert(_debugAssertNotDisposed());

    return _disposeMemo
        .runOnce(() => _writeQueue.dispose().then((_) => _bag.dispose()))
        .then((_) => _onDispose?.call());
  }
}

/// Scope function extension
extension _ScopeFunctionExtension<T> on T {
  /// Returns result from calling [f].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  R let<R>(R Function(T) block) => block(this);
}

/// Returns a 5 character long hexadecimal string generated from
/// [Object.hashCode]'s 20 least-significant bits.
String _shortHash(Object? object) =>
    object.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
