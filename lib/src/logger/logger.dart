import 'event.dart';

/// Log messages about operations (such as read, write, value change) and stream events.
abstract class Logger<Key extends Object, Options> {
  /// Logs event.
  void log(LoggerEvent<Key, Options> event);
}
