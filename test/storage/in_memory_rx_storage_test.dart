import 'dart:async';

import 'package:rx_storage/rx_storage.dart';
import 'package:test/test.dart';

void main() {
  group('RxStorage with InMemoryStorage', () {
    late InMemoryStorage<String> adapter;
    late RxStorage<String, void> storage;

    setUp(() {
      adapter = InMemoryStorage<String>();
      storage = RxStorage<String, void>(adapter);
      addTearDown(storage.dispose);
    });

    for (final present in <bool>[false, true]) {
      final state = present ? 'null-valued' : 'missing';

      test('observe emits an initial null for a $state key', () async {
        if (present) {
          await storage.write<int>('key', null, (value) => value);
        }
        await expectLater(
          storage.observe<int>('key', (raw) => raw as int?),
          emitsInOrder(<Object?>[null]),
        );
        expect(await storage.containsKey('key'), present);
      });
    }

    test('observe emits original values after encoding and null after deletion',
        () async {
      await storage.write<int>('key', 1, (value) => 'encoded:$value');
      await _expectChanges(
        storage.observe<int>(
          'key',
          (raw) => int.parse((raw as String).split(':').last),
        ),
        <Object?>[1, 2, null, 3, null],
        () async {
          await storage.write<int>('key', 2, (value) => 'encoded:$value');
          await storage.remove('key');
          expect(await storage.containsKey('key'), isFalse);
          await storage.write<int>('key', 3, (value) => 'encoded:$value');
          await storage.clear();
        },
      );
      expect(await storage.readAll(), isEmpty);
    });

    test('observe applies decoder defaults only to the initial read', () async {
      await _expectChanges(
        storage.observe<int>('key', (raw) => raw as int? ?? 42),
        <Object?>[42, null, null],
        () async {
          expect(await storage.containsKey('key'), isFalse);
          await storage.write<int>('key', null, (value) => value);
          expect(await storage.containsKey('key'), isTrue);
          await storage.remove('key');
        },
      );
      expect(await storage.containsKey('key'), isFalse);
    });

    test('observeAll emits an empty map initially and encoded values on write',
        () async {
      await _expectChanges(
        storage.observeAll(),
        <Object?>[
          <String, Object?>{},
          <String, Object?>{'key': 'encoded:1'},
        ],
        () => storage.write<int>('key', 1, (value) => 'encoded:$value'),
      );
    });

    test('observeAll includes null-valued entries', () async {
      await _expectChanges(
        storage.observeAll(),
        <Object?>[
          <String, Object?>{},
          <String, Object?>{'key': null},
        ],
        () => storage.write<int>('key', null, (value) => value),
      );
    });

    test('observeAll omits removed keys', () async {
      await storage.write<int>('keep', 1, (value) => value);
      await storage.write<int>('remove', null, (value) => value);

      await _expectChanges(
        storage.observeAll(),
        <Object?>[
          <String, Object?>{'keep': 1, 'remove': null},
          <String, Object?>{'keep': 1},
        ],
        () => storage.remove('remove'),
      );
    });

    test('observeAll emits an empty map after clear', () async {
      await storage.write<int>('key', 1, (value) => value);

      await _expectChanges(
        storage.observeAll(),
        <Object?>[
          <String, Object?>{'key': 1},
          <String, Object?>{},
        ],
        storage.clear,
      );
    });

    test('observeAll emits encoded values after update', () async {
      await _expectChanges(
        storage.observeAll(),
        <Object?>[
          <String, Object?>{},
          <String, Object?>{'key': 'encoded:1'},
        ],
        () => storage.update<int>(
          key: 'key',
          decoder: (raw) => raw as int?,
          transformer: (value) => (value ?? 0) + 1,
          encoder: (value) => 'encoded:$value',
        ),
      );
    });

    test('observe reports initial asynchronous decoding failures', () async {
      final failure = FormatException('Cannot decode');

      await expectLater(
        storage.observe<int>('key', (_) async => throw failure),
        emitsError(same(failure)),
      );
    });

    test('observe reports incompatible types written after listening',
        () async {
      await _expectChanges(
        storage.observe<int>('key', (raw) => raw as int?),
        <Object?>[null, emitsError(isA<TypeError>())],
        () => storage.write<String>('key', 'text', (value) => value),
      );
    });

    test('failed writes and updates leave entries and stream values unchanged',
        () async {
      await storage.write<int>('key', 1, (value) => value);
      final failure = StateError('Cannot update');

      await _expectChanges(
        storage.observe<int>('key', (raw) => raw as int?),
        <Object?>[1, 3],
        () async {
          await expectLater(
            storage.write<int>('key', 2, (_) async => throw failure),
            throwsA(same(failure)),
          );
          await expectLater(
            storage.update<int>(
              key: 'key',
              decoder: (raw) => raw as int?,
              transformer: (_) async => throw failure,
              encoder: (value) => value,
            ),
            throwsA(same(failure)),
          );
          expect(await storage.readAll(), <String, Object?>{'key': 1});
          await storage.write<int>('key', 3, (value) => value);
        },
      );
    });

    test('concurrent asynchronous updates preserve every increment', () async {
      await _expectChanges(
        storage.observe<int>('counter', (raw) => raw as int?),
        <Object?>[null, for (var value = 1; value <= 25; value++) value],
        () => Future.wait(List.generate(
          25,
          (_) => storage.update<int>(
            key: 'counter',
            decoder: (raw) async => raw as int?,
            transformer: (value) async {
              await Future<void>.delayed(Duration.zero);
              return (value ?? 0) + 1;
            },
            encoder: (value) async => value,
          ),
        )),
      );

      expect(await storage.read<int>('counter', (raw) => raw as int?), 25);
    });
  });

  test('disposing the wrapper closes streams and preserves adapter entries',
      () async {
    final adapter = InMemoryStorage<String>();
    await adapter.write<int>('key', 42, (value) => value);
    final storage = RxStorage<String, void>(adapter);
    await _expectChanges(
      storage.observe<int>('key', (raw) => raw as int?),
      <Object?>[42, emitsDone],
      storage.dispose,
    );
    expect(await adapter.read<int>('key', (raw) => raw as int?), 42);
  });
}

Future<void> _expectChanges<T>(Stream<T> stream, Iterable<Object?> expected,
    Future<void> Function() change) async {
  final initialEvent = Completer<void>();
  final expectation = expectLater(
    stream.map((value) {
      if (!initialEvent.isCompleted) {
        initialEvent.complete();
      }
      return value;
    }),
    emitsInOrder(expected),
  );

  await initialEvent.future;
  await change();
  await expectation;
}
