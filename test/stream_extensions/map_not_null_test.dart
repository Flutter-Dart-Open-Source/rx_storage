import 'dart:async';

import 'package:rx_storage/src/stream_extensions/map_not_null.dart';
import 'package:test/test.dart';

void main() {
  group('Rx.mapNotNull', () {
    test('Rx.mapNotNull', () async {
      // 0-----1-----2-----3-----...-----8-----9-----|
      // 1-----null--3-----null--...-----9-----null--|
      // 1--3--5--7--9--|
      final stream =
          Stream.periodic(const Duration(milliseconds: 100), (i) => i)
              .take(10)
              .mapNotNull((i) => i.isOdd ? null : i + 1);
      await expectLater(
        stream,
        emitsInOrder(<dynamic>[1, 3, 5, 7, 9, emitsDone]),
      );
    });

    test('Rx.mapNotNull.shouldThrowA', () {
      expect(
        () => Stream.value(42).mapNotNull<int>(null),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Rx.mapNotNull.shouldThrowB', () async {
      final stream = Stream<int>.error(Exception()).mapNotNull((_) => true);
      await expectLater(
        stream,
        emitsError(isA<Exception>()),
      );
    });

    test('Rx.mapNotNull.shouldThrowC', () async {
      final stream = Stream.fromIterable([1, 2, 3, 4]).mapNotNull((i) {
        if (i == 3) {
          throw Exception();
        } else {
          return i;
        }
      });
      expect(
        stream,
        emitsInOrder(<dynamic>[
          1,
          2,
          emitsError(isA<Exception>()),
          4,
          emitsDone,
        ]),
      );
    });

    test('Rx.mapNotNull.asBroadcastStream', () {
      final stream = Stream.fromIterable([2, 3, 4, 5, 6])
          .mapNotNull((i) => null)
          .asBroadcastStream();

      // listen twice on same stream
      stream.listen(null);
      stream.listen(null);

      // code should reach here
      expect(true, true);
    });

    test('Rx.mapNotNull.pause.resume', () async {
      StreamSubscription<num> subscription;

      subscription =
          Stream.fromIterable([2, 3, 4, 5, 6]).mapNotNull((i) => i).listen(
        expectAsync1(
          (data) {
            expect(data, 2);
            subscription.cancel();
          },
        ),
      );

      subscription.pause();
      subscription.resume();
    });

    test('Rx.mapNotNull.broadcast', () {
      final streamController = StreamController<int>.broadcast();
      final stream = streamController.stream.mapNotNull((i) => i);

      expect(stream.isBroadcast, isTrue);
      stream.listen(null);
      stream.listen(null);

      expect(true, true);
    });

    test('Rx.mapNotNull.not.broadcast', () {
      final streamController = StreamController<int>();
      final stream = streamController.stream.mapNotNull((i) => i);

      expect(stream.isBroadcast, isFalse);
      stream.listen(null);
      expect(() => stream.listen(null), throwsStateError);

      streamController.add(1);
    });
  });
}
