import 'package:rx_storage/rx_storage.dart';
import 'package:test/test.dart';

void main() {
  group('EmptyLogger', () {
    test('Works', () {
      final logger = RxStorageEmptyLogger<String, void>();
      const keyAndValue = KeyAndValue('key', 'value', String);

      logger.log(OnDataStreamEvent(keyAndValue));
    });
  });
}
