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
  /// Operations wait for [storageOrFuture] to resolve when necessary.
  /// Initialization failures are retained for operations, including when
  /// initialization fails before the first operation starts.
  ///
  /// If provided, [logger] receives operation and stream events. [onDispose]
  /// runs at most once, after the wrapper releases its resources.
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
  /// returned by [Storage.readAll] before clearing. These events bypass
  /// [decoder], even if it supplies a default for the initial read.
  ///
  /// Read and decoding failures, and subsequent values incompatible with [T],
  /// are emitted as stream errors. Equal consecutive values are not filtered;
  /// use [Stream.distinct] to suppress duplicates.
  Stream<T?> observe<T extends Object>(Key key, Decoder<T?> decoder,
      [Options options]);

  /// Returns a single-subscription stream of all decoded entries.
  ///
  /// Listening triggers an initial [Storage.readAll] with [decoder] and
  /// [options]. Every successful [write], [update], [remove], or [clear] through
  /// this wrapper triggers another read, even if the entries are unchanged.
  ///
  /// Every read applies [decoder] to each existing entry, including null-valued
  /// entries. Removed keys are omitted, and empty storage emits an empty map.
  /// Reads and their asynchronous decoding complete in stream order. Each
  /// emission reflects the read when it runs, rather than the exact state at the
  /// mutation. Read or decoding failures are emitted as stream errors.
  ///
  /// To observe stored representations, use
  /// `observeAll((_, raw) => raw)`.
  Stream<Map<Key, Object?>> observeAll(EntryDecoder<Key> decoder,
      [Options? options]);

  /// Releases this wrapper's stream, logger, and write-queue resources.
  ///
  /// Call this when the wrapper is no longer needed, and do not use it afterward.
  /// Queued writing tasks that have not started complete with a [StateError],
  /// so await writes that must finish before disposing. Storage operations that
  /// have already started can finish after disposal, without further change
  /// notifications or log events. Disposal does not roll back those operations.
  ///
  /// Repeated calls return the same future, including any cleanup error.
  ///
  /// This method does not clear the adapter's data or release resources owned by
  /// the adapter. The caller is responsible for any cleanup the adapter requires.
  Future<void> dispose();
}
