import 'dart:async';

import 'package:rx_storage/rx_storage.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryStorage', () {
    test('stores encoded values and decodes them when read', () async {
      final Storage<int, void> storage = InMemoryStorage<int>();

      await storage.write<int>(7, 42, (value) => 'encoded:$value');

      expect(await storage.containsKey(7), isTrue);
      expect(await storage.readAll((_, raw) => raw),
          <int, Object?>{7: 'encoded:42'});
      expect(
        await storage.read<int>(
            7, (raw) => int.parse((raw as String).split(':').last)),
        42,
      );
    });

    test('retains encoded null values until the key is removed', () async {
      final storage = InMemoryStorage<String>();

      await storage.write<int>('key', 42, (_) => null);

      expect(await storage.containsKey('key'), isTrue);
      expect(await storage.read<Object>('key', (raw) => raw), isNull);
      expect(await storage.readAll((_, raw) => raw),
          <String, Object?>{'key': null});

      await storage.remove('key');

      expect(await storage.containsKey('key'), isFalse);
      expect(await storage.readAll((_, raw) => raw), isEmpty);
      await storage.remove('missing');
      expect(await storage.containsKey('missing'), isFalse);
    });

    test('clears every entry, including null-valued entries', () async {
      final storage = InMemoryStorage<String>();
      await storage.write<int>('first', 1, (value) => value);
      await storage.write<int>('second', null, (value) => value);

      await storage.clear();

      expect(await storage.readAll((_, raw) => raw), isEmpty);
      expect(await storage.containsKey('first'), isFalse);
      expect(await storage.containsKey('second'), isFalse);
      await storage.clear();
      expect(await storage.readAll((_, raw) => raw), isEmpty);
    });

    test('passes missing values to the decoder without creating an entry',
        () async {
      final storage = InMemoryStorage<String>();

      expect(
        await storage.read<int>('missing', (raw) => raw as int? ?? 42),
        42,
      );
      expect(await storage.containsKey('missing'), isFalse);
      expect(await storage.readAll((_, raw) => raw), isEmpty);
    });

    test('passes null input through the encoder', () async {
      final storage = InMemoryStorage<String>();

      await storage.write<int>(
          'key', null, (value) => 'encoded:${value ?? 42}');

      expect(await storage.readAll((_, raw) => raw),
          <String, Object?>{'key': 'encoded:42'});
    });

    test('waits for asynchronous encoding and decoding', () async {
      final storage = InMemoryStorage<String>();
      final encoded = Completer<Object?>();
      final writing = storage.write<int>('key', 42, (_) => encoded.future);

      expect(await storage.containsKey('key'), isFalse);
      encoded.complete('encoded:42');
      await writing;

      final decoded = Completer<int?>();
      final reading = storage.read<int>('key', (raw) {
        expect(raw, 'encoded:42');
        return decoded.future;
      });
      decoded.complete(42);

      expect(await reading, 42);
    });

    test('readAll returns independent map snapshots', () async {
      final storage = InMemoryStorage<String>();
      await storage.write<int>('first', 1, (value) => value);
      final snapshot = await storage.readAll((_, raw) => raw);

      await storage.write<int>('second', 2, (value) => value);
      expect(snapshot, <String, Object?>{'first': 1});

      snapshot
        ..clear()
        ..['injected'] = 3;
      expect(
        await storage.readAll((_, raw) => raw),
        <String, Object?>{'first': 1, 'second': 2},
      );
    });

    test('keeps mutable values by reference on write and read', () async {
      final storage = InMemoryStorage<String>();
      final items = <int>[1];
      await storage.write<List<int>>('items', items, (value) => value);

      items.add(2);
      final read =
          await storage.read<List<int>>('items', (raw) => raw as List<int>?);
      expect(read, same(items));

      final snapshot = await storage.readAll((_, raw) => raw);
      expect(snapshot['items'], same(items));
      (snapshot['items'] as List<int>).add(3);
      expect(
        await storage.read<List<int>>('items', (raw) => raw as List<int>?),
        <int>[1, 2, 3],
      );
    });

    test('keeps separate instances independent', () async {
      final first = InMemoryStorage<String>();
      final second = InMemoryStorage<String>();
      await first.write<int>('key', 1, (value) => value);

      expect(await second.containsKey('key'), isFalse);
      await second.write<int>('key', 2, (value) => value);
      await first.clear();

      expect(await second.read<int>('key', (raw) => raw as int?), 2);
    });

    for (final asynchronous in <bool>[false, true]) {
      final kind = asynchronous ? 'asynchronous' : 'synchronous';

      test('preserves entries when $kind encoding fails', () async {
        final storage = InMemoryStorage<String>();
        await storage.write<int>('key', 1, (value) => value);
        final failure = StateError('Cannot encode');
        FutureOr<Object?> encoder(int? _) {
          if (asynchronous) {
            return Future<Object?>.error(failure);
          }
          throw failure;
        }

        await expectLater(
            storage.write<int>('key', 2, encoder), throwsA(same(failure)));
        await expectLater(
            storage.write<int>('missing', 2, encoder), throwsA(same(failure)));

        expect(await storage.readAll((_, raw) => raw),
            <String, Object?>{'key': 1});
      });

      test('reports $kind decoder failures through the future', () async {
        final storage = InMemoryStorage<String>();
        await storage.write<int>('key', 1, (value) => value);
        final failure = FormatException('Cannot decode');
        final reading = storage.read<int>('key', (_) {
          if (asynchronous) {
            return Future<int?>.error(failure);
          }
          throw failure;
        });

        await expectLater(reading, throwsA(same(failure)));
        expect(await storage.readAll((_, raw) => raw),
            <String, Object?>{'key': 1});
      });
    }
  });
}
