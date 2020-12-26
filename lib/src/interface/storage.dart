/// Convert [T] to type that [Storage] can be persisted.
/// This used in [Storage.write].
typedef Encoder<T> = dynamic Function(T);

/// Convert storage persisted type to [T].
/// This used in [Storage.read].
typedef Decoder<T> = T Function(dynamic);

/// A persistent store for simple data. Data is persisted to disk asynchronously.
abstract class Storage<Key, Options> {
  /// Returns a future complete with value true if the persistent storage
  /// contains the given [key].
  Future<bool> containsKey(Key key, [Options options]);

  /// Reads a value of any type from persistent storage.
  Future<T> read<T>(Key key, Decoder<T> decoder, [Options options]);

  /// Returns all keys in the persistent storage.
  Future<Map<Key, dynamic>> readAll([Options options]);

  /// Completes with true once the storage for the app has been cleared.
  Future<bool> clear([Options options]);

  /// Removes an entry from persistent storage.
  Future<bool> remove(Key key, [Options options]);

  /// Saves a [value] to persistent storage.
  Future<bool> write<T>(Key key, T value, Encoder<T> encoder,
      [Options options]);
}
