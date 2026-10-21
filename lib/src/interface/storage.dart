import 'dart:async';

/// Converts a value of type [T] to a representation supported by a [Storage].
///
/// Used by [Storage.write]. Conversion may be synchronous or asynchronous.
typedef Encoder<T> = FutureOr<Object?> Function(T t);

/// Converts a stored representation to a value of type [T].
///
/// Used by [Storage.read]. Conversion may be synchronous or asynchronous.
/// A null input can represent either a missing key or a stored null value.
typedef Decoder<T> = FutureOr<T> Function(Object? o);

/// An asynchronous key-value storage interface.
///
/// Adapters define the backing store, supported encoded values, and the meaning
/// of [Options]. Data may be held in memory or persisted; completing an operation
/// does not by itself guarantee durable disk storage.
///
/// Null retention, value copying, and synchronization depend on the adapter.
abstract interface class Storage<Key extends Object, Options> {
  /// Returns whether the storage contains an entry for [key].
  ///
  /// An adapter that retains null-valued entries returns true for such entries.
  /// Use this to distinguish a missing key from a stored null value, since
  /// [read] alone does not distinguish them. Separate calls to [containsKey] and
  /// [read] do not form an atomic operation.
  Future<bool> containsKey(Key key, [Options? options]);

  /// Reads the stored representation for [key] and converts it with [decoder].
  ///
  /// A missing key is passed to [decoder] as null, just like a stored null value.
  /// The decoder may return null, supply a default value, or throw.
  /// Reading and decoding failures complete the returned future with an error.
  Future<T?> read<T extends Object>(Key key, Decoder<T?> decoder,
      [Options? options]);

  /// Returns all entries as a map of keys to their stored representations.
  ///
  /// Values are encoded values; no [Decoder] is applied. Map mutability and
  /// copying of contained values depend on the adapter.
  Future<Map<Key, Object?>> readAll([Options? options]);

  /// Removes all entries in the storage scope selected by [options].
  ///
  /// The returned future completes when the adapter finishes clearing them.
  Future<void> clear([Options? options]);

  /// Removes the entry for [key], if present.
  ///
  /// This removes the entry rather than writing a null value.
  Future<void> remove(Key key, [Options? options]);

  /// Converts [value] with [encoder] and stores the encoded result under [key].
  ///
  /// A null [value] is still passed to [encoder]. Whether an encoded null is
  /// retained as an entry or removes the key depends on the adapter.
  /// The returned future completes after encoding and writing finish, or with
  /// an error if either fails. Persistence and durability depend on the adapter.
  Future<void> write<T extends Object>(Key key, T? value, Encoder<T?> encoder,
      [Options? options]);
}
