import '../model/key_and_value.dart';
import 'logger.dart';

/// Logger's implementation with empty methods.
class LoggerAdapter implements Logger {
  /// Constructs a [LoggerAdapter].
  const LoggerAdapter();

  @override
  void doOnDataStream(KeyAndValue pair) {}

  @override
  void doOnErrorStream(Object error, StackTrace stackTrace) {}

  @override
  void keysChanged(Iterable<KeyAndValue> pairs) {}

  @override
  void readValue(Type type, Object key, dynamic value) {}

  @override
  void writeValue(Type type, Object key, dynamic value, bool writeResult) {}
}
