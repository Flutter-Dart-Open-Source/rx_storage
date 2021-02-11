import 'event.dart';
import 'logger.dart';

/// Default Logger's implementation, simply print to the console.
class DefaultLogger<Key extends Object, Options>
    implements Logger<Key, Options> {
  /// Construct a [DefaultLogger].
  const DefaultLogger();

  @override
  void log(LoggerEvent<Key, Options> event) {
    // TODO: implement log
  }
}
