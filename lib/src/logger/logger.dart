import 'event.dart';

/// Log messages about operations (such as read, write, value change) and stream events.
abstract class RxStorageLogger<Key extends Object, Options> {
  /// Logs event.
  void log(RxStorageLoggerEvent<Key, Options> event);
}
