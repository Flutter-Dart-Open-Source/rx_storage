import 'package:stack_trace/stack_trace.dart';

/// An Object which acts as a tuple containing both an error and the
/// corresponding stack trace.
class RxStorageError {
  /// A reference to the wrapped error object.
  final Object error;

  /// A reference to the wrapped [StackTrace]
  late final Trace trace = Trace.from(_stackTrace).terse;

  final StackTrace _stackTrace;

  /// Constructs an object containing both an [error] and the
  /// corresponding [stackTrace].
  RxStorageError(this.error, StackTrace stackTrace) : _stackTrace = stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RxStorageError &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          trace == other.trace;

  @override
  int get hashCode => error.hashCode ^ trace.hashCode;

  @override
  String toString() => '$error\n$trace';
}
