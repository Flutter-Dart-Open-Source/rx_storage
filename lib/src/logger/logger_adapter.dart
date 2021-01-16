import '../model/key_and_value.dart';
import 'logger.dart';

/// Logger's implementation with empty methods.
class LoggerAdapter implements Logger {
  /// Constructs a [LoggerAdapter].
  const LoggerAdapter();

  @override
  void doOnDataStream(KeyAndValue<Object, Object?> pair) {}

  @override
  void doOnErrorStream(Object error, StackTrace stackTrace) {}

  @override
  void keysChanged(Iterable<KeyAndValue<Object, Object?>> pairs) {}

  @override
  void readValue(Type type, Object key, Object? value) {}

  @override
  void writeValue(Type type, Object key, Object? value, bool writeResult) {}
}
