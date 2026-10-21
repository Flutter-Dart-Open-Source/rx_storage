/// Reactive streams over asynchronous key-value storage.
///
/// Wrap a [Storage] adapter with [RxStorage] to observe values as they change.
library rx_storage;

export 'src/impl/real_storage.dart';
export 'src/interface/rx_storage.dart';
export 'src/interface/storage.dart';
export 'src/interface/transactional_storage.dart';
export 'src/logger/default_logger.dart';
export 'src/logger/empty_logger.dart';
export 'src/logger/event.dart';
export 'src/logger/logger.dart';
export 'src/model/error.dart';
export 'src/model/key_and_value.dart';
export 'src/storage/in_memory_storage.dart';
