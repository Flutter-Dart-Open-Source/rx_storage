import 'package:rx_storage/rx_storage.dart';
import 'package:test/test.dart';

void main() {
  group('EmptyLogger', () {
    test('Works', () {
      final logger = EmptyLogger<String, void>();
      const keyAndValue = KeyAndValue('key', 'value');

      logger.log(OnDataStreamEvent(keyAndValue));
    });
  });
}
