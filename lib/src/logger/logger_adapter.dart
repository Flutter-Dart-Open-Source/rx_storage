import '../model/key_and_value.dart';
import 'logger.dart';

/// Logger's implementation with empty methods.
class LoggerAdapter implements Logger {
  /// Constructs a [LoggerAdapter].
  const LoggerAdapter();

  @override
  void doOnDataStream(KeyAndValue<Object?> pair) {}

  @override
  void doOnErrorStream(Object error, StackTrace stackTrace) {}

  @override
  void keysChanged(Iterable<KeyAndValue<Object?>> pairs) {}

  @override
  void readValue(Type type, String key, Object? value) {}

  @override
  void writeValue(Type type, String key, Object? value, bool writeResult) {}
}
