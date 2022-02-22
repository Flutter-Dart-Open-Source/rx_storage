import 'event.dart';
import 'logger.dart';

/// Log nothing :)
class RxStorageEmptyLogger<Key extends Object, Options>
    implements RxStorageLogger<Key, Options> {
  /// Constructs a [RxStorageEmptyLogger].
  const RxStorageEmptyLogger();

  @override
  void log(RxStorageLoggerEvent<Key, Options> event) {}
}
