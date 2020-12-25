/// TODO
typedef Encoder<T> = dynamic Function(T);

/// TODO
typedef Decoder<T> = T Function(dynamic);

/// A persistent store for simple data. Data is persisted to disk asynchronously.
abstract class Storage<Key> {
  /// Returns a future complete with value true if the persistent storage
  /// contains the given [key].
  Future<bool> containsKey(Key key);

  /// Reads a value of any type from persistent storage.
  Future<T> read<T>(Key key, Decoder<T> decoder);

  /// Returns all keys in the persistent storage.
  Future<Map<Key, dynamic>> readAll();

  /// Completes with true once the storage for the app has been cleared.
  Future<bool> clear();

  /// Removes an entry from persistent storage.
  Future<bool> remove(Key key);

  /// Saves a [value] to persistent storage.
  Future<bool> write<T>(Key key, T value, Encoder<T> encoder);
}
