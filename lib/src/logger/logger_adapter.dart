import '../model/key_and_value.dart';
import 'logger.dart';

/// Logger's implementation with empty methods.
class LoggerAdapter implements Logger {
  /// Constructs a [LoggerAdapter].
  const LoggerAdapter();

  @override
  void doOnDataStream(KeyAndValue<dynamic, dynamic> pair) {}

  @override
  void doOnErrorStream(Object error, StackTrace stackTrace) {}

  @override
  void keysChanged(Iterable<KeyAndValue<dynamic, dynamic>> pairs) {}

  @override
  void readValue(Type type, Object key, dynamic value) {}

  @override
  void writeValue(Type type, Object key, dynamic value, bool writeResult) {}
}
