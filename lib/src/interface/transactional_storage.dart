import 'package:meta/meta.dart';
import 'dart:async';

import 'storage.dart';

/// Transforms a value into another value of the same type.
///
/// Used by [TransactionalStorage.update]. The transformation may be synchronous
/// or asynchronous.
typedef Transformer<T> = FutureOr<T> Function(T);

/// A [Storage] that supports asynchronous read-modify-write operations.
///
/// Implementations define the synchronization scope. This interface alone does
/// not guarantee multi-key transactions, rollback, or durable disk persistence.
abstract interface class TransactionalStorage<Key extends Object, Options>
    implements Storage<Key, Options> {
  /// `Read–modify–write`.
  ///
  /// Performs these steps in order:
  /// - Read the stored representation and decode it with [decoder].
  /// - Transform the decoded value with [transformer].
  /// - Encode the transformed value with [encoder] and write it to storage.
  ///
  /// Each callback may perform synchronous or asynchronous work. The returned
  /// future completes after the write finishes. A failure stops subsequent steps
  /// and completes the future with that error. Rollback of callback side effects
  /// or partially completed storage writes is not guaranteed by this interface.
  ///
  /// In the default `RxStorage` implementation, the entire operation shares a
  /// queue with [write], [remove], and other updates for the same key on the same
  /// wrapper instance. Reads, [clear], operations on other keys, direct adapter
  /// access, and other wrappers are not serialized by that queue. Stronger
  /// isolation and durability require support from the adapter.
  @experimental
  Future<void> update<T extends Object>({
    required Key key,
    required Decoder<T?> decoder,
    required Transformer<T?> transformer,
    required Encoder<T?> encoder,
    Options? options,
  });
}
