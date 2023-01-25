import 'dart:async';
import 'dart:math';

import 'package:rx_storage/src/async/async_queue.dart';
import 'package:rxdart_ext/rxdart_ext.dart';
import 'package:test/test.dart';

void main() {
  group('AsyncQueue', () {
    const timeout = Duration(milliseconds: 500);
    final extraTimeout = (timeout * 1.1).inMilliseconds;
    final halfTimeout = (timeout * 0.5).inMilliseconds;

    test('execute in serial order', () async {
      late AsyncQueue<int> queue;

      final running = <int>[];
      final ran = <int>[];
      var simultaneous = 0;
      var timeoutOccurred = false;

      queue = AsyncQueue<int>(
        key: 'key',
        onTimeout: () {
          queue.dispose();
          timeoutOccurred = true;
        },
        timeout: timeout,
      );

      final tasks = <Future<void>>[];
      for (var i = 0; i < 1000; i++) {
        tasks.add(
          queue.enqueue(() async {
            running.add(i);
            simultaneous = max(simultaneous, running.length);

            await delay(1);

            ran.add(i);
            running.remove(i);
            return i;
          }),
        );
      }

      await Future.wait(tasks);
      expect(simultaneous, lessThanOrEqualTo(1));
      expect(ran, [...ran]..sort());

      await delay(extraTimeout);
      expect(timeoutOccurred, isTrue);
    });

    test('cannot enqueue task after disposed', () async {
      final queue = AsyncQueue<int>(
        key: 'key',
        onTimeout: () {},
        timeout: timeout,
      );

      await pumpEventQueue();
      _unawaited(queue.dispose());

      expect(
        () => queue.enqueue(() => Future.value(0)),
        throwsA(isStateError),
      );
    });

    test('onTimeout is called when timeout occurred', () async {
      var count = 0;

      final queue = AsyncQueue<void>(
        key: 'key',
        onTimeout: () => ++count,
        timeout: timeout,
      );

      await pumpEventQueue();

      for (var i = 0; i < 10; i++) {
        _unawaited(queue.enqueue(() => Future.value()));
        await delay(halfTimeout);
        expect(count, 0);
      }

      await delay(extraTimeout);
      expect(count, 1);
    });
  });
}

void _unawaited(Future<void>? future) {}
