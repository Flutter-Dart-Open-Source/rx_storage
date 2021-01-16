import 'logger/default_logger_test.dart' as default_logger_test;
import 'logger/logger_adapter_test.dart' as logger_adapter_test;
import 'model/key_and_value_test.dart' as key_and_value_test;
import 'storage/storage_test.dart' as storage_test;
import 'storage/streams_test.dart' as streams_test;

void main() {
  // logger tests
  default_logger_test.main();
  logger_adapter_test.main();

  // model test
  key_and_value_test.main();

  // storage tests
  storage_test.main();
  streams_test.main();
}
