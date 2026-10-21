import 'dart:async';

import '../impl/real_storage.dart';
import '../logger/logger.dart';
import 'storage.dart';
import 'transactional_storage.dart';

/// Reactive streams over a [Storage] adapter.
///
/// The default implementation emits notifications for successful mutations
/// through this wrapper. Direct adapter changes and changes through other
/// wrappers are not automatically observed.
abstract interface class RxStorage<Key extends Object, Options>
    implements TransactionalStorage<Key, Options> {
  /// Wraps a [Storage], or a future that resolves to one, in a [RealRxStorage].
  ///
  /// Operations wait for [storageOrFuture] to resolve when necessary. If provided,
  /// [logger] receives operation and stream events, and [onDispose] is called
  /// after the wrapper releases its resources.
  factory RxStorage(
    FutureOr<Storage<Key, Options>> storageOrFuture, [
    RxStorageLogger<Key, Options>? logger,
    void Function()? onDispose,
  ]) =>
      RealRxStorage<Key, Options, Storage<Key, Options>>(
        storageOrFuture,
        logger,
        onDispose,
      );

  /// Returns a single-subscription stream of nullable values for [key].
  ///
  /// Listening triggers an initial [Storage.read] using [decoder] and [options],
  /// without first checking [containsKey]. A missing key and a stored null value
  /// both reach the decoder as null. The decoder determines the initial value,
  /// including any default for null, or produces a stream error if decoding fails.
  /// The stream does not convey whether the key exists.
  ///
  /// After a successful [write] or [update] through this wrapper, the stream emits
  /// the original value passed to the write, without reading or decoding it again.
  /// A successful [remove] emits null. A successful [clear] emits null for keys
  /// returned by the adapter's [Storage.readAll] before clearing. These null events
  /// bypass [decoder], even if it supplies a default for the initial read.
  ///
  /// Read and decoding failures, and subsequent values incompatible with [T],
  /// are emitted as stream errors. Equal consecutive values are not filtered;
  /// use [Stream.distinct] to suppress duplicates.
  Stream<T?> observe<T extends Object>(Key key, Decoder<T?> decoder,
      [Options options]);

  /// Returns a single-subscription stream of all stored entries.
  ///
  /// Listening triggers an initial [Storage.readAll] using [options]. Every
  /// successful [write], [update], [remove], or [clear] through this wrapper
  /// triggers another read, even if the resulting entries are unchanged.
  ///
  /// Map values are stored representations; no [Decoder] is applied. Each
  /// emission reflects the read when it runs, rather than a snapshot captured at
  /// the mutation. Read failures are emitted as stream errors.
  Stream<Map<Key, Object?>> observeAll([Options options]);

  /// Releases this wrapper's stream, logger, and write-queue resources.
  ///
  /// Call this when the wrapper is no longer needed, and do not use it afterward.
  /// Queued writing tasks that have not started are discarded, so await writes
  /// that must finish before disposing. Disposal does not roll back storage
  /// operations that have already started.
  ///
  /// This method does not clear the adapter's data or release resources owned by
  /// the adapter. The caller is responsible for any cleanup the adapter requires.
  Future<void> dispose();
}
