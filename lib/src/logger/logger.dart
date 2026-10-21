import 'event.dart';

/// Receives storage-operation and stream events for an `RxStorage` wrapper.
abstract interface class RxStorageLogger<Key extends Object, Options> {
  /// Handles a storage-operation or stream [event].
  void log(RxStorageLoggerEvent<Key, Options> event);
}
