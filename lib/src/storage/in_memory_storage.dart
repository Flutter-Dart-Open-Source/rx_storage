import '../interface/storage.dart';

/// An in-memory [Storage] adapter with no options.
///
/// Each instance starts empty and stores the representations returned by
/// [Encoder]. Encoded null values retain their keys; [remove] deletes entries.
/// Data is not persisted between application runs.
///
/// [readAll] captures a shallow entry snapshot before invoking its decoders.
/// Entry decoders may run concurrently. Stored objects are kept by reference,
/// without cloning on write or read; decoders may choose to copy them. Mutating
/// stored objects directly does not notify an `RxStorage` wrapper.
///
/// This adapter does not serialize asynchronous operations. Wrap it in
/// `RxStorage` for per-key write and update serialization within one wrapper.
final class InMemoryStorage<Key extends Object> implements Storage<Key, void> {
  final _map = <Key, Object?>{};

  /// Creates an empty in-memory storage adapter.
  InMemoryStorage();

  @override
  Future<bool> containsKey(Key key, [void options]) =>
      Future.value(_map.containsKey(key));

  @override
  Future<T?> read<T extends Object>(Key key, Decoder<T?> decoder,
          [void options]) =>
      Future.sync(() => decoder(_map[key]));

  @override
  Future<Map<Key, Object?>> readAll(EntryDecoder<Key> decoder, [void options]) {
    final entries = _map.entries.toList(growable: false);
    return Future.wait(entries.map((entry) =>
            Future<Object?>.sync(() => decoder(entry.key, entry.value))
                .then((value) => MapEntry(entry.key, value))))
        .then((entries) => Map<Key, Object?>.fromEntries(entries));
  }

  @override
  Future<void> clear([void options]) {
    _map.clear();
    return Future.value();
  }

  @override
  Future<void> remove(Key key, [void options]) {
    _map.remove(key);
    return Future.value();
  }

  @override
  Future<void> write<T extends Object>(Key key, T? value, Encoder<T?> encoder,
          [void options]) =>
      Future.sync(() => encoder(value)).then((encoded) {
        _map[key] = encoded;
      });
}
