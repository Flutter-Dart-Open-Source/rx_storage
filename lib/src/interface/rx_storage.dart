import 'dart:async';

import '../impl/real_storage.dart';
import '../logger/logger.dart';
import 'storage.dart';

/// Get [Stream]s by key from persistent storage.
abstract class RxStorage<Key> implements Storage<Key> {
  /// TODO
  factory RxStorage(
    FutureOr<Storage<Key>> storageOrFuture, [
    Logger logger,
    void Function() onDispose,
  ]) =>
      RealRxStorage<Key>(storageOrFuture, logger, onDispose);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with key was changed.
  Stream<T> observe<T>(Key key, Decoder<T> decoder);

  /// Return [Stream] that will emit all values associated with key read from persistent storage.
  /// It will automatic emit all keys when any value was changed.
  Stream<Map<Key, dynamic>> observeAll();

  /// Clean up resources - Closes the streams.
  /// This method should be called when a [RxStorage] is no longer needed.
  /// Once `dispose` is called, all streams will `not` emit changed value when value changed.
  Future<void> dispose();
}
