import 'async/async_queue_test.dart' as async_queue_test;
import 'logger/default_logger_test.dart' as default_logger_test;
import 'logger/logger_adapter_test.dart' as logger_adapter_test;
import 'model/key_and_value_test.dart' as key_and_value_test;
import 'perf.dart' as perf;
import 'storage/storage_test.dart' as storage_test;
import 'storage/streams_test.dart' as streams_test;

void main() async {
  await perf.main();

  // async
  async_queue_test.main();

  // logger tests
  default_logger_test.main();
  logger_adapter_test.main();

  // model test
  key_and_value_test.main();

  // storage tests
  storage_test.main();
  streams_test.main();
}
