import 'dart:async';

import 'package:rx_storage/src/logger/default_logger.dart';
import 'package:rx_storage/src/model/key_and_value.dart';
import 'package:test/test.dart';

void main() {
  final logs = <String>[];

  dynamic Function() overridePrint(dynamic Function() testFn) {
    return () {
      final spec = ZoneSpecification(print: (_, __, ___, String line) {
        // Add to log instead of printing to stdout
        logs.add(line);
      });
      return Zone.current.fork(specification: spec).run<dynamic>(testFn);
    };
  }

  group('DefaultLogger', () {
    final logger = DefaultLogger();

    setUp(() => logs.clear());

    test(
      'keysChanged',
      overridePrint(() {
        const pairs = [
          KeyAndValue('key1', 'value1'),
          KeyAndValue('key2', 2),
        ];
        logger.keysChanged(pairs);
        expect(
          logs,
          <String>[
            ' ↓ Key changes',
            "    → { 'key1': value1 }" '\n' "    → { 'key2': 2 }",
          ],
        );
      }),
    );

    test(
      'doOnDataStream',
      overridePrint(() {
        const keyAndValue = KeyAndValue('key1', 'value1');
        logger.doOnDataStream(keyAndValue);

        expect(
          logs,
          [" → Stream emits data: { 'key1': value1 }"],
        );
      }),
    );

    test(
      'doOnErrorStream',
      overridePrint(() {
        final stackTrace = StackTrace.current;
        final exception = Exception();
        logger.doOnErrorStream(exception, stackTrace);

        expect(
          logs,
          [' → Stream emits error: $exception, $stackTrace'],
        );
      }),
    );

    test(
      'readValue',
      overridePrint(() {
        const type = String;
        const key = 'key';
        const value = 'value';
        logger.readValue(type, key, value);

        expect(
          logs,
          [" → Read value: type String, key 'key' → value"],
        );
      }),
    );

    test(
      'writeValue',
      overridePrint(() {
        const type = String;
        const key = 'key';
        const value = 'value';
        const writeResult = true;
        logger.writeValue(type, key, value, writeResult);

        expect(
          logs,
          [
            " → Write value: type String, key 'key', value value  → result true"
          ],
        );
      }),
    );
  });
}
