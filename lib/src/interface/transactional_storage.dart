import 'package:meta/meta.dart';
import 'dart:async';

import 'storage.dart';

/// Transform a value to another value of the same type.
typedef Transformer<T> = FutureOr<T> Function(T);

/// A persistent store for simple data.
/// Data is persisted to disk asynchronously and transactionally.
abstract class TransactionalStorage<Key extends Object, Options>
    implements Storage<Key, Options> {
  /// `Read–modify–write`.
  ///
  /// Updates the data transactionally in an atomic read-modify-write operation.
  /// All operations are serialized, and the [transformer] can perform asynchronous computations
  /// such as RPCs, database queries, API calls, etc.
  ///
  /// The future completes when the data has been persisted durably to disk.
  /// If the transform or write to disk fails, the transaction is aborted and the error is rethrown.
  ///
  /// When calling this, logic will be executed in the following order:
  /// - Read raw value by [key], then decode it with [decoder].
  /// - Transform the decoded value with [transformer].
  /// - Encode the transformed value with [encoder].
  /// - Finally, save encoded value to persistent storage.
  @experimental
  Future<void> update<T extends Object>({
    required Key key,
    required Decoder<T?> decoder,
    required Transformer<T?> transformer,
    required Encoder<T?> encoder,
    Options? options,
  });
}
