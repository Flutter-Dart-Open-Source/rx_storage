import 'package:meta/meta.dart';

import 'event.dart';
import 'logger.dart';

/// Log nothing :)
class RxStorageEmptyLogger<Key extends Object, Options>
    implements RxStorageLogger<Key, Options> {
  /// Constructs a [RxStorageEmptyLogger].
  const RxStorageEmptyLogger();

  @nonVirtual
  @override
  void log(RxStorageLoggerEvent<Key, Options> event) {}
}
