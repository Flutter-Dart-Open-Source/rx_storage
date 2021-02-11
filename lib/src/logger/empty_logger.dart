import 'event.dart';
import 'logger.dart';

/// Logger's implementation with empty methods.
class EmptyLogger<Key extends Object, Options> implements Logger<Key, Options> {
  /// Constructs a [EmptyLogger].
  const EmptyLogger();

  @override
  void log(LoggerEvent<Key, Options> event) {}
}
