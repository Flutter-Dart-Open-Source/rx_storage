import 'package:meta/meta.dart';

import '../model/error.dart';
import '../model/key_and_value.dart';

/// Event when reading, writing storage.
@immutable
abstract class LoggerEvent<Key extends Object, Options> {}

//
// BEGIN: STREAM
//

/// Key changed when mutating storage.
class KeysChangedEvent<Key extends Object, Options>
    implements LoggerEvent<Key, Options> {
  /// An iterable containing all changed values associated with keys.
  final Iterable<KeyAndValue<Key, Object?>> pairs;

  /// Construct a [KeysChangedEvent].
  KeysChangedEvent(this.pairs);
}

/// Stream emits new data event.
class OnDataStreamEvent<Key extends Object, Options>
    implements LoggerEvent<Key, Options> {
  /// Changed value with key.
  final KeyAndValue<Key, Object?> pair;

  /// Construct a [OnDataStreamEvent].
  OnDataStreamEvent(this.pair);
}

/// Stream emits error event.
class OnErrorStreamEvent<Key extends Object, Options>
    implements LoggerEvent<Key, Options> {
  /// Error from upstream (eg. cast error, ...)
  final RxStorageError error;

  /// Construct a [OnErrorStreamEvent].
  OnErrorStreamEvent(this.error);
}

//
// END: STREAM
//

//
// BEGIN: READ
//

/// Read value successfully.
class ReadValueSuccessEvent<Key extends Object, Options>
    implements LoggerEvent<Key, Options> {
  /// Read value with key.
  final KeyAndValue<Key, Object?> pair;

  /// The type
  final Type type;

  /// The options.
  final Options? options;

  /// Construct a [ReadValueSuccessEvent].
  ReadValueSuccessEvent(this.pair, this.type, this.options);
}

/// Read value failed.
class ReadValueFailureEvent<Key extends Object, Options>
    implements LoggerEvent<Key, Options> {
  /// The key.
  final Key key;

  /// The type
  final Type type;

  /// The error occurred when reading.
  final RxStorageError error;

  /// The options.
  final Options? options;

  /// Construct a [ReadValueFailureEvent].
  ReadValueFailureEvent(this.key, this.type, this.error, this.options);
}

/// Read all values successfully.
class ReadAllSuccessEvent<Key extends Object, Options>
    implements LoggerEvent<Key, Options> {
  /// All values read from storage.
  final Iterable<KeyAndValue<Key, Object?>> all;

  /// The options.
  final Options? options;

  /// Construct a [ReadAllSuccessEvent].
  ReadAllSuccessEvent(this.all, this.options);
}

/// Read all values failed.
class ReadAllFailureEvent<Key extends Object, Options>
    implements LoggerEvent<Key, Options> {
  /// The error occurred when reading.
  final RxStorageError error;

  /// The options.
  final Options? options;

  /// Construct a [ReadAllFailureEvent].
  ReadAllFailureEvent(this.error, this.options);
}

//
// END: READ
//

//
// BEGIN: WRITE
//

/// Clear storage successfully.
class ClearSuccessEvent<Key extends Object, Options>
    implements LoggerEvent<Key, Options> {
  /// The options.
  final Options? options;

  /// Construct a [ClearSuccessEvent].
  ClearSuccessEvent(this.options);
}

/// Clear storage failed.
class ClearFailureEvent<Key extends Object, Options>
    implements LoggerEvent<Key, Options> {
  /// The error occurred while clearing.
  final RxStorageError error;

  /// The options.
  final Options? options;

  /// Construct a [ClearFailureEvent].
  ClearFailureEvent(this.error, this.options);
}

/// Remove successfully.
class RemoveSuccessEvent<Key extends Object, Options>
    implements LoggerEvent<Key, Options> {
  /// The key.
  final Key key;

  /// The options.
  final Options? options;

  /// Construct a [RemoveSuccessEvent].
  RemoveSuccessEvent(this.key, this.options);
}

/// Remove successfully.
class RemoveFailureEvent<Key extends Object, Options>
    implements LoggerEvent<Key, Options> {
  /// The key.
  final Key key;

  /// The options.
  final Options? options;

  /// The error occurred when removing.
  final RxStorageError error;

  /// Construct a [RemoveFailureEvent].
  RemoveFailureEvent(this.key, this.options, this.error);
}

/// Remove successfully.
class WriteSuccessEvent<Key extends Object, Options>
    implements LoggerEvent<Key, Options> {
  /// The key and value.
  final KeyAndValue<Key, Object?> pair;

  /// The type.
  final Type type;

  /// The options.
  final Options? options;

  /// Construct a [WriteSuccessEvent].
  WriteSuccessEvent(this.pair, this.type, this.options);
}

/// Remove successfully.
class WriteFailureEvent<Key extends Object, Options>
    implements LoggerEvent<Key, Options> {
  /// The key and value.
  final KeyAndValue<Key, Object?> pair;

  /// The type.
  final Type type;

  /// The options.
  final Options? options;

  /// The error occurred when writing.
  final RxStorageError error;

  /// Construct a [WriteFailureEvent].
  WriteFailureEvent(this.pair, this.type, this.options, this.error);
}

//
// END: WRITE
//
