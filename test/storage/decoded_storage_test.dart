import 'dart:async';

import 'package:rx_storage/rx_storage.dart';
import 'package:test/test.dart';

import '../utils/user.dart';

void main() {
  group('Decoded bulk storage', () {
    test('readAll receives each key and its stored representation', () async {
      final Storage<int, void> storage = InMemoryStorage<int>();
      await storage.write<int>(7, 42, (value) => 'encoded:$value');

      expect(
        await storage.readAll((key, raw) => '$key=$raw'),
        <int, String?>{7: '7=encoded:42'},
      );
    });

    test('readAll handles different codecs for different keys', () async {
      final storage = InMemoryStorage<String>();
      const user = User(1, 'Ada');
      await storage.write<User>('user', user, userToJsonString);
      await storage.write<int>('counter', 42, (value) => '$value');

      final values = await storage.readAll((key, raw) {
        switch (key) {
          case 'user':
            return jsonStringToUser(raw);
          case 'counter':
            return int.parse(raw as String);
          default:
            throw StateError('Unknown key: $key');
        }
      });

      expect(values, <String, Object?>{'user': user, 'counter': 42});
    });

    test('readAll skips missing keys and preserves null-valued entries',
        () async {
      final storage = InMemoryStorage<String>();
      await storage.write<int>('default', null, (value) => value);
      await storage.write<int>('nullable', null, (value) => value);

      final values = await storage.readAll((key, raw) {
        expect(raw, isNull);
        return key == 'default' ? 42 : null;
      });

      expect(values, <String, int?>{'default': 42, 'nullable': null});
      expect(values.containsKey('missing'), isFalse);
    });

    test('readAll on empty storage does not invoke the decoder', () async {
      final storage = InMemoryStorage<String>();

      expect(
        await storage
            .readAll((_, __) => throw StateError('No entries to decode')),
        isEmpty,
      );
    });

    test('readAll captures entries before asynchronous decoding', () async {
      final storage = InMemoryStorage<String>();
      await storage.write<int>('first', 1, (value) => value);
      final decoded = Completer<int?>();
      final reading = storage.readAll((key, raw) {
        expect(key, 'first');
        expect(raw, 1);
        return decoded.future;
      });

      await storage.remove('first');
      await storage.write<int>('second', 2, (value) => value);
      decoded.complete(10);

      expect(await reading, <String, int?>{'first': 10});
      expect(
        await storage.readAll((_, raw) => raw),
        <String, Object?>{'second': 2},
      );
    });

    for (final asynchronous in <bool>[false, true]) {
      final kind = asynchronous ? 'asynchronous' : 'synchronous';

      test('readAll propagates $kind failures without changing entries',
          () async {
        final storage = InMemoryStorage<String>();
        await storage.write<int>('first', 1, (value) => value);
        await storage.write<int>('second', 2, (value) => value);
        final failure = FormatException('Cannot decode');

        final reading = storage.readAll((key, raw) {
          if (key == 'first') {
            return raw as int?;
          }
          if (asynchronous) {
            return Future<int?>.error(failure);
          }
          throw failure;
        });

        await expectLater(reading, throwsA(same(failure)));
        expect(
          await storage.readAll((_, raw) => raw),
          <String, Object?>{'first': 1, 'second': 2},
        );
      });
    }
  });
}
