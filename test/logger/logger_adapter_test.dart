import 'package:rx_storage/src/logger/logger_adapter.dart';
import 'package:rx_storage/src/model/key_and_value.dart';
import 'package:test/test.dart';

void main() {
  group('LoggerAdapter', () {
    test('Works', () {
      final logger = LoggerAdapter();
      const keyAndValue = KeyAndValue('key', 'value');
      logger.keysChanged([keyAndValue]);
      logger.doOnDataStream(keyAndValue);
      logger.doOnErrorStream(Exception(), StackTrace.current);
      logger.writeValue(
        keyAndValue.value.runtimeType,
        keyAndValue.key,
        keyAndValue.value,
        true,
      );
      logger.readValue(
        keyAndValue.value.runtimeType,
        keyAndValue.key,
        keyAndValue.value,
      );
    });
  });
}
