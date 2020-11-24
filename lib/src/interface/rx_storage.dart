import 'dart:async';

import '../impl/real_storage.dart';
import '../logger/logger.dart';
import 'storage.dart';

/// Get [Stream]s by key from persistent storage.
abstract class RxStorage implements Storage {
  /// TODO
  factory RxStorage(
    FutureOr<Storage> storageOrFuture, [
    Logger? logger,
    void Function()? onDispose,
  ]) =>
      RealRxStorage(storageOrFuture, logger, onDispose);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with key was changed.
  Stream<Object?> getStream(String key);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a bool.
  Stream<bool?> getBoolStream(String key);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a double.
  Stream<double?> getDoubleStream(String key);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a int.
  Stream<int?> getIntStream(String key);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a String.
  Stream<String?> getStringStream(String key);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a string set.
  Stream<List<String>?> getStringListStream(String key);

  /// Return [Stream] that will emit all keys read from persistent storage.
  /// It will automatic emit all keys when any value was changed.
  Stream<Set<String>> getKeysStream();

  /// Clean up resources - Closes the streams.
  /// This method should be called when a [RxStorage] is no longer needed.
  /// Once `dispose` is called, all streams will `not` emit changed value when value changed.
  Future<void> dispose();
}
