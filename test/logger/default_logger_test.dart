import 'package:rx_storage/rx_storage.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultLogger<String, void>', () {
    final logger = DefaultLogger<String, void>(tag: 'TAG');

    test('KeysChangedEvent', () {
      const keyAndValues = [
        KeyAndValue('key1', 'value1', String),
        KeyAndValue('key2', 2, int),
      ];

      expect(
        () => logger.log(KeysChangedEvent(keyAndValues)),
        prints([
          'TAG ↓ Key changes',
          '    → { key: key1, type: String, value: value1 }',
          '    → { key: key2, type: int, value: 2 }\n',
        ].join('\n')),
      );
      ;
    });

    test('OnDataStreamEvent', () {
      const pair = KeyAndValue('key1', 'value1', String);
      expect(
        () => logger.log(OnDataStreamEvent(pair)),
        prints(
            'TAG → Stream emits data: { key: key1, type: String, value: value1 }\n'),
      );
    });

    test('OnErrorStreamEvent', () {
      final stackTrace = StackTrace.current;
      final exception = Exception();
      expect(
        () => logger
            .log(OnErrorStreamEvent(RxStorageError(exception, stackTrace))),
        prints('TAG → Stream emits error: $exception, $stackTrace\n'),
      );
    });

    test('ReadValueSuccessEvent', () {
      const type = String;
      const key = 'key';
      const value = 'value';
      expect(
        () => logger
            .log(ReadValueSuccessEvent(KeyAndValue(key, value, type), null)),
        prints('TAG → Read: key=key, type=String → value\n'),
      );
    });

    test('WriteSuccessEvent', () {
      const type = String;
      const key = 'key';
      const value = 'value';
      expect(
        () =>
            logger.log(WriteSuccessEvent(KeyAndValue(key, value, type), null)),
        prints('TAG ← Write: key=key, type=String, value=value → success\n'),
      );
    });
  });

  group('DefaultLogger<String, int>', () {
    final logger = DefaultLogger<String, int>(tag: 'TAG');

    test('KeysChangedEvent', () {
      const keyAndValues = [
        KeyAndValue('key1', 'value1', String),
        KeyAndValue('key2', 2, int),
      ];

      expect(
        () => logger.log(KeysChangedEvent(keyAndValues)),
        prints([
          'TAG ↓ Key changes',
          '    → { key: key1, type: String, value: value1 }',
          '    → { key: key2, type: int, value: 2 }\n',
        ].join('\n')),
      );
    });

    test('OnDataStreamEvent', () {
      const pair = KeyAndValue('key1', 'value1', String);
      expect(
        () => logger.log(OnDataStreamEvent(pair)),
        prints(
            'TAG → Stream emits data: { key: key1, type: String, value: value1 }\n'),
      );
    });

    test('OnErrorStreamEvent', () {
      final stackTrace = StackTrace.current;
      final exception = Exception();
      expect(
        () => logger
            .log(OnErrorStreamEvent(RxStorageError(exception, stackTrace))),
        prints('TAG → Stream emits error: $exception, $stackTrace\n'),
      );
    });

    test('ReadValueSuccessEvent', () {
      const type = String;
      const key = 'key';
      const value = 'value';
      expect(
        () =>
            logger.log(ReadValueSuccessEvent(KeyAndValue(key, value, type), 0)),
        prints('TAG → Read: key=key, type=String, options=0 → value\n'),
      );
    });

    test('WriteSuccessEvent', () {
      const type = String;
      const key = 'key';
      const value = 'value';
      expect(
        () => logger.log(WriteSuccessEvent(KeyAndValue(key, value, type), 0)),
        prints(
            'TAG ← Write: key=key, type=String, options=0, value=value → success\n'),
      );
    });
  });
}
