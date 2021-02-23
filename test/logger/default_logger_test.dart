import 'package:rx_storage/rx_storage.dart';
import 'package:stack_trace/stack_trace.dart';
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
        prints(
            'TAG → Stream emits error: $exception\n${Trace.from(stackTrace).terse}\n'),
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

    test('ReadValueFailureEvent', () {
      const type = String;
      const key = 'key';

      final stackTrace = StackTrace.current;
      final exception = Exception();
      final error = RxStorageError(exception, stackTrace);

      expect(
        () => logger.log(ReadValueFailureEvent(key, type, error, null)),
        prints(
            'TAG → Read: key=key, type=String → $exception\n${Trace.from(stackTrace).terse}\n'),
      );
    });

    test('ReadAllSuccessEvent', () {
      const keyAndValues = [
        KeyAndValue('key1', 'value1', String),
        KeyAndValue('key2', 2, int),
      ];

      expect(
        () => logger.log(ReadAllSuccessEvent(keyAndValues, null)),
        prints([
          'TAG ↓ Read all',
          '    → { key: key1, type: String, value: value1 }',
          '    → { key: key2, type: int, value: 2 }\n',
        ].join('\n')),
      );
    });

    test('ReadAllFailureEvent', () {
      final stackTrace = StackTrace.current;
      final exception = Exception();
      final error = RxStorageError(exception, stackTrace);

      expect(
        () => logger.log(ReadAllFailureEvent(error, null)),
        prints(
            'TAG → Read all → $exception\n${Trace.from(stackTrace).terse}\n'),
      );
    });

    test('ClearSuccessEvent', () {
      expect(
        () => logger.log(ClearSuccessEvent(null)),
        prints('TAG ← Clear → success\n'),
      );
    });

    test('ClearFailureEvent', () {
      final stackTrace = StackTrace.current;
      final exception = Exception();
      final error = RxStorageError(exception, stackTrace);

      expect(
        () => logger.log(ClearFailureEvent(error, null)),
        prints('TAG ← Clear → $exception\n${Trace.from(stackTrace).terse}\n'),
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

    test('WriteFailureEvent', () {
      const type = String;
      const key = 'key';
      const value = 'value';

      final stackTrace = StackTrace.current;
      final exception = Exception();
      final error = RxStorageError(exception, stackTrace);

      expect(
        () => logger
            .log(WriteFailureEvent(KeyAndValue(key, value, type), null, error)),
        prints(
            'TAG ← Write: key=key, type=String, value=value → $exception\n${Trace.from(stackTrace).terse}\n'),
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
        prints(
            'TAG → Stream emits error: $exception\n${Trace.from(stackTrace).terse}\n'),
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

    test('ReadValueFailureEvent', () {
      const type = String;
      const key = 'key';

      final stackTrace = StackTrace.current;
      final exception = Exception();
      final error = RxStorageError(exception, stackTrace);

      expect(
        () => logger.log(ReadValueFailureEvent(key, type, error, 2)),
        prints(
            'TAG → Read: key=key, type=String, options=2 → $exception\n${Trace.from(stackTrace).terse}\n'),
      );
    });

    test('ReadAllSuccessEvent', () {
      const keyAndValues = [
        KeyAndValue('key1', 'value1', String),
        KeyAndValue('key2', 2, int),
      ];

      expect(
        () => logger.log(ReadAllSuccessEvent(keyAndValues, 2)),
        prints([
          'TAG ↓ Read all: options=2',
          '    → { key: key1, type: String, value: value1 }',
          '    → { key: key2, type: int, value: 2 }\n',
        ].join('\n')),
      );
    });

    test('ReadAllFailureEvent', () {
      final stackTrace = StackTrace.current;
      final exception = Exception();
      final error = RxStorageError(exception, stackTrace);

      expect(
        () => logger.log(ReadAllFailureEvent(error, 3)),
        prints(
            'TAG → Read all: options=3 → $exception\n${Trace.from(stackTrace).terse}\n'),
      );
    });

    test('ClearSuccessEvent', () {
      expect(
        () => logger.log(ClearSuccessEvent(2)),
        prints('TAG ← Clear: options=2 → success\n'),
      );
    });

    test('ClearFailureEvent', () {
      final stackTrace = StackTrace.current;
      final exception = Exception();
      final error = RxStorageError(exception, stackTrace);

      expect(
        () => logger.log(ClearFailureEvent(error, 2)),
        prints(
            'TAG ← Clear: options=2 → $exception\n${Trace.from(stackTrace).terse}\n'),
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

    test('WriteFailureEvent', () {
      const type = String;
      const key = 'key';
      const value = 'value';

      final stackTrace = StackTrace.current;
      final exception = Exception();
      final error = RxStorageError(exception, stackTrace);

      expect(
        () => logger
            .log(WriteFailureEvent(KeyAndValue(key, value, type), 2, error)),
        prints(
            'TAG ← Write: key=key, type=String, options=2, value=value → $exception\n${Trace.from(stackTrace).terse}\n'),
      );
    });
  });
}
