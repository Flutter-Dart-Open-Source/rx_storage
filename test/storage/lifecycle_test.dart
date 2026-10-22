import 'dart:async';

import 'package:rx_storage/rx_storage.dart';
import 'package:test/test.dart';

import '../fake_storage.dart';

void main() {
  group('RxStorage lifecycle', () {
    test('concurrent and repeated disposal runs external cleanup once',
        () async {
      var cleanups = 0;
      final storage = RxStorage<String, void>(
        InMemoryStorage<String>(),
        null,
        () => ++cleanups,
      );

      final first = storage.dispose();
      final second = storage.dispose();
      await Future.wait([first, second]);

      expect(cleanups, 1);
      expect(second, same(first));
      expect(storage.dispose(), same(first));
      await storage.dispose();
      expect(cleanups, 1);
    });

    test('disposal retains a cleanup failure without repeating the callback',
        () async {
      var cleanups = 0;
      final failure = StateError('Cannot clean up');
      final storage = RxStorage<String, void>(
        InMemoryStorage<String>(),
        null,
        () {
          ++cleanups;
          throw failure;
        },
      );

      final first = storage.dispose();
      final second = storage.dispose();
      await Future.wait([
        expectLater(first, throwsA(same(failure))),
        expectLater(second, throwsA(same(failure))),
      ]);

      expect(cleanups, 1);
      await expectLater(storage.dispose(), throwsA(same(failure)));
      expect(cleanups, 1);
    });

    test('initialization failures wait for operations without uncaught errors',
        () async {
      final failure = StateError('Cannot initialize');
      final trace = StackTrace.current;
      final uncaught = <Object>[];
      final errors = <Object>[];
      final traces = <StackTrace>[];

      await runZonedGuarded<Future<void>>(() async {
        final initialization = Completer<Storage<String, void>>();
        final storage = RxStorage<String, void>(initialization.future);
        initialization.completeError(failure, trace);
        // Let initialization fail before the first operation starts.
        await Future<void>(() {});

        try {
          await storage.read<int>('key', (raw) => raw as int?);
        } catch (error, stackTrace) {
          errors.add(error);
          traces.add(stackTrace);
        }
        try {
          await storage.observe<int>('key', (raw) => raw as int?).first;
        } catch (error, stackTrace) {
          errors.add(error);
          traces.add(stackTrace);
        }
        await storage.dispose();
      }, (error, _) => uncaught.add(error))!;

      expect(uncaught, isEmpty);
      expect(errors, [same(failure), same(failure)]);
      expect(traces, [same(trace), same(trace)]);
    });

    test('an active update can finish after disposal', () async {
      final adapter = InMemoryStorage<String>();
      await adapter.write<int>('key', 1, (value) => value);
      final logger = _RecordingLogger();
      final storage = RxStorage<String, void>(adapter, logger);
      final started = Completer<void>();
      final release = Completer<int?>();
      final result = expectLater(
        storage.update<int>(
          key: 'key',
          decoder: (raw) => raw as int?,
          transformer: (_) {
            started.complete();
            return release.future;
          },
          encoder: (value) => value,
        ),
        completes,
      );
      await started.future;
      await storage.dispose();
      final logCount = logger.events.length;
      release.complete(2);
      await result;

      expect(await adapter.read<int>('key', (raw) => raw as int?), 2);
      expect(logger.events, hasLength(logCount));
    });

    test('an active clear can finish after adapter initialization and disposal',
        () async {
      final adapter = InMemoryStorage<String>();
      await adapter.write<int>('key', 1, (value) => value);
      final initialization = Completer<Storage<String, void>>();
      final logger = _RecordingLogger();
      final storage = RxStorage<String, void>(initialization.future, logger);
      final result = expectLater(storage.clear(), completes);
      // Let the queued clear start waiting for adapter initialization.
      await Future<void>(() {});
      await storage.dispose();
      final logCount = logger.events.length;
      initialization.complete(adapter);
      await result;

      expect(await adapter.readAll((_, raw) => raw), isEmpty);
      expect(logger.events, hasLength(logCount));
    });

    for (final succeeds in <bool>[true, false]) {
      final outcome = succeeds ? 'success' : 'failure';

      test('subclass logging after disposal preserves active reload $outcome',
          () async {
        final adapter = _ControlledReloadStorage();
        final logger = _RecordingReloadLogger();
        final storage = FakeRxStorage(adapter, logger);
        final values = <String, Object?>{'key': 2};
        final failure = StateError('Cannot reload');
        final result = expectLater(
          storage.reload(),
          succeeds ? completion(same(values)) : throwsA(same(failure)),
        );
        await adapter.started.future;

        try {
          await storage.dispose();
          final logCount = logger.events.length;
          if (succeeds) {
            adapter.result.complete(values);
          } else {
            adapter.result.completeError(failure);
          }
          await result;
          expect(logger.events, hasLength(logCount));
        } finally {
          if (!adapter.result.isCompleted) {
            if (succeeds) {
              adapter.result.complete(values);
            } else {
              adapter.result.completeError(failure);
            }
          }
          await result;
        }
      });
    }

    for (final succeeds in <bool>[true, false]) {
      final outcome = succeeds ? 'success' : 'failure';

      test('disposal rejects queued writes and preserves active write $outcome',
          () async {
        final adapter = InMemoryStorage<String>();
        final logger = _RecordingLogger();
        final storage = RxStorage<String, void>(adapter, logger);
        final initial = Completer<void>();
        final events = <int?>[];
        final subscription = storage
            .observe<int>(
          'key',
          (raw) => raw as int?,
        )
            .listen((value) {
          events.add(value);
          if (!initial.isCompleted) {
            initial.complete();
          }
        });
        await initial.future;

        final started = Completer<void>();
        final release = Completer<Object?>();
        final failure = StateError('Cannot encode');
        final active = storage.write<int>('key', 1, (_) {
          started.complete();
          return release.future;
        });
        final activeResult = expectLater(
          active,
          succeeds ? completes : throwsA(same(failure)),
        );
        await started.future;
        final rejected = expectLater(
          storage
              .write<int>('key', 2, (value) => value)
              .timeout(const Duration(seconds: 1)),
          throwsStateError,
        );

        try {
          await storage.dispose();
          final logCount = logger.events.length;
          await rejected;
          if (succeeds) {
            release.complete(1);
          } else {
            release.completeError(failure);
          }
          await activeResult;

          expect(await adapter.read<int>('key', (raw) => raw as int?),
              succeeds ? 1 : null);
          expect(events, <int?>[null]);
          expect(logger.events, hasLength(logCount));
        } finally {
          if (!release.isCompleted) {
            if (succeeds) {
              release.complete(1);
            } else {
              release.completeError(failure);
            }
          }
          await activeResult;
          await subscription.cancel();
        }
      });
    }
  });
}

final class _ControlledReloadStorage extends FakeStorage {
  final started = Completer<void>();
  final result = Completer<Map<String, Object?>>();

  _ControlledReloadStorage() : super(<String, Object?>{'key': 1});

  @override
  Future<Map<String, Object?>> reload() {
    started.complete();
    return result.future;
  }
}

final class _RecordingReloadLogger implements FakeLogger {
  final events = <RxStorageLoggerEvent<String, void>>[];

  @override
  void log(RxStorageLoggerEvent<String, void> event) => events.add(event);
}

final class _RecordingLogger implements RxStorageLogger<String, void> {
  final events = <RxStorageLoggerEvent<String, void>>[];

  @override
  void log(RxStorageLoggerEvent<String, void> event) => events.add(event);
}
