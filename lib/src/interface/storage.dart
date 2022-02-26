import 'dart:async';

/// Convert [T] to a value of type that can be persisted in [Storage].
/// This is used in [Storage.write].
typedef Encoder<T> = FutureOr<Object?> Function(T t);

/// Convert storage persisted type to [T].
/// This is used in [Storage.read].
typedef Decoder<T> = FutureOr<T> Function(Object? o);

/// A persistent store for simple data. Data is persisted to disk asynchronously.
abstract class Storage<Key extends Object, Options> {
  /// Returns a future complete with value true if the persistent storage
  /// contains the given [key].
  Future<bool> containsKey(Key key, [Options? options]);

  /// Reads a value of any type from persistent storage.
  Future<T?> read<T extends Object>(Key key, Decoder<T?> decoder,
      [Options? options]);

  /// Returns all keys in the persistent storage.
  Future<Map<Key, Object?>> readAll([Options? options]);

  /// Completes with true once the storage for the app has been cleared.
  Future<void> clear([Options? options]);

  /// Removes an entry from persistent storage.
  Future<void> remove(Key key, [Options? options]);

  /// Saves a [value] to persistent storage.
  Future<void> write<T extends Object>(Key key, T? value, Encoder<T?> encoder,
      [Options? options]);
}
