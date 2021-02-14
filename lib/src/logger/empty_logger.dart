import 'event.dart';
import 'logger.dart';

/// Log nothing :)
class EmptyLogger<Key extends Object, Options> implements Logger<Key, Options> {
  /// Constructs a [EmptyLogger].
  const EmptyLogger();

  @override
  void log(LoggerEvent<Key, Options> event) {}
}
