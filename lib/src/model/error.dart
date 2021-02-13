/// An Object which acts as a tuple containing both an error and the
/// corresponding stack trace.
class RxStorageError {
  /// A reference to the wrapped error object.
  final Object error;

  /// A reference to the wrapped [StackTrace]
  final StackTrace stackTrace;

  /// Constructs an object containing both an [error] and the
  /// corresponding [stackTrace].
  const RxStorageError(this.error, this.stackTrace);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RxStorageError &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode;

  @override
  String toString() => '$error, $stackTrace';
}
