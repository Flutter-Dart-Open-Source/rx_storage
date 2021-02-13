/// TODO
class RxStorageError {
  /// TODO
  final Object error;

  /// TODO
  final StackTrace stackTrace;

  /// TODO
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
