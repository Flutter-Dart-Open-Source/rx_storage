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

    test('observe decodes stored values after writes and deletion', () async {
      await storage.write<int>('key', 1, (value) => 'encoded:$value');
      await _expectChanges(
        storage.observe<int>(
          'key',
          (raw) =>
              raw == null ? null : int.parse((raw as String).split(':').last),
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
      expect(await storage.readAll((_, raw) => raw), isEmpty);
    });

    test('observe decodes retained null and removed keys with the same default',
        () async {
      await _expectChanges(
        storage.observe<int>('key', (raw) => raw as int? ?? 42),
        <Object?>[42, 42, 42],
        () async {
          expect(await storage.containsKey('key'), isFalse);
          await storage.write<int>('key', 1, (_) => null);
          expect(await storage.containsKey('key'), isTrue);
          await storage.remove('key');
        },
      );
      expect(await storage.containsKey('key'), isFalse);
    });

    test('observeAll emits an empty map initially and encoded values on write',
        () async {
      await _expectChanges(
        storage.observeAll((_, raw) => raw),
        <Object?>[
          <String, Object?>{},
          <String, Object?>{'key': 'encoded:1'},
        ],
        () => storage.write<int>('key', 1, (value) => 'encoded:$value'),
      );
    });

    test('observeAll includes null-valued entries', () async {
      await _expectChanges(
        storage.observeAll((_, raw) => raw),
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
        storage.observeAll((_, raw) => raw),
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
        storage.observeAll((_, raw) => raw),
        <Object?>[
          <String, Object?>{'key': 1},
          <String, Object?>{},
        ],
        storage.clear,
      );
    });

    test('observeAll emits encoded values after update', () async {
      await _expectChanges(
        storage.observeAll((_, raw) => raw),
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

    test('observeAll decodes the initial and subsequent maps', () async {
      await storage.write<int>('key', 1, (value) => 'encoded:$value');

      await _expectChanges(
        storage.observeAll((key, raw) => Future<String?>.value('$key=$raw')),
        <Object?>[
          <String, String?>{'key': 'key=encoded:1'},
          <String, String?>{'key': 'key=encoded:2'},
        ],
        () => storage.write<int>('key', 2, (value) => 'encoded:$value'),
      );
    });

    test('observeAll omits cleared keys instead of decoding them as null',
        () async {
      await storage.write<int>('key', null, (value) => value);

      await _expectChanges(
        storage.observeAll((_, raw) => raw as int? ?? 42),
        <Object?>[
          <String, int?>{'key': 42},
          <String, int?>{},
        ],
        storage.clear,
      );
    });

    test('observeAll preserves map order while an initial decoder is pending',
        () async {
      await storage.write<int>('key', 0, (value) => value);
      final started = Completer<void>();
      final initialValue = Completer<Object?>();
      final expectation = expectLater(
        storage.observeAll((_, raw) {
          if (raw == 0) {
            started.complete();
            return initialValue.future;
          }
          return raw;
        }),
        emitsInOrder(<Object?>[
          <String, Object?>{'key': 0},
          <String, Object?>{'key': 1},
        ]),
      );

      await started.future;
      await storage.write<int>('key', 1, (value) => value);
      // Let the later change queue while the initial decoder is still pending.
      await Future<void>(() {});
      initialValue.complete(0);
      await expectation;
    });

    test('observeAll emits decoding errors and recovers on later changes',
        () async {
      final failure = FormatException('Cannot decode');
      final failedDecode = Completer<void>();

      await _expectChanges(
        storage.observeAll((_, raw) {
          if (raw == 'bad') {
            failedDecode.complete();
            return Future<int?>.error(failure);
          }
          return int.parse(raw as String);
        }),
        <Object?>[
          <String, int?>{},
          emitsError(same(failure)),
          <String, int?>{'key': 42},
        ],
        () async {
          await storage.write<String>('key', 'bad', (value) => value);
          await failedDecode.future;
          await storage.write<int>('key', 42, (value) => '$value');
        },
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

    test('an observer decode error does not fail the write or another observer',
        () async {
      final failure = FormatException('Cannot decode three');
      final normal = StreamIterator(storage.observe<int>('key', (raw) {
        if (raw == '3') throw failure;
        return raw == null ? null : int.parse(raw as String);
      }));
      final formatted = StreamIterator(storage.observe<String>(
        'key',
        (raw) async => raw == null ? 'missing' : 'stored:$raw',
      ));
      addTearDown(normal.cancel);
      addTearDown(formatted.cancel);
      expect(await normal.moveNext(), isTrue);
      expect(await formatted.moveNext(), isTrue);

      var encoderCalls = 0;
      await storage.write<int>('key', null, (_) async {
        encoderCalls++;
        return '3';
      });
      expect(encoderCalls, 1);
      expect(await storage.containsKey('key'), isTrue);
      await expectLater(normal.moveNext(), throwsA(same(failure)));
      expect(await formatted.moveNext(), isTrue);
      expect(formatted.current, 'stored:3');
      expect(
          await storage.observe<String>('key', (raw) => raw as String?).first,
          '3');
    });

    test('only clear invalidates observers of unrelated missing keys',
        () async {
      var reads = 0;
      await _expectChanges(
        storage.observe<int>('missing', (raw) {
          reads++;
          return raw as int? ?? 42;
        }),
        <Object?>[42, 42, emitsDone],
        () async {
          await storage.write<int>('other', 1, (value) => value);
          await storage.remove('other');
          await storage.clear();
          await storage.dispose();
        },
      );
      expect(reads, 2);
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
          expect(await storage.readAll((_, raw) => raw),
              <String, Object?>{'key': 1});
          await storage.write<int>('key', 3, (value) => value);
        },
      );
    });

    test('observe rereads for every update after a slow decoder', () async {
      final started = Completer<void>();
      final initial = Completer<int?>();
      var reads = 0;
      final output = expectLater(
        storage.observe<int>('counter', (raw) {
          if (++reads == 1) {
            started.complete();
            return initial.future;
          }
          return raw as int?;
        }),
        emitsInOrder(
            <Object?>[null, for (var i = 0; i < 25; i++) 25, emitsDone]),
      );
      addTearDown(() {
        if (!initial.isCompleted) initial.complete(null);
      });
      await started.future;
      await Future.wait(List.generate(
        25,
        (_) => storage.update<int>(
          key: 'counter',
          decoder: (raw) async => raw as int?,
          transformer: (value) async => (value ?? 0) + 1,
          encoder: (value) async => value,
        ),
      ));
      expect(reads, 1);
      expect(await storage.read<int>('counter', (raw) => raw as int?), 25);
      await storage.dispose();
      initial.complete(null);
      await output;
      expect(reads, 26);
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
