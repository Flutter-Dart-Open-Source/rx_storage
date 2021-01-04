import 'dart:async';

import 'package:rx_storage/src/stream_extensions/single_subscription.dart';
import 'package:test/test.dart';

void main() {
  group('Stream.toSingleSubscriptionStream', () {
    test('Stream.toSingleSubscriptionStream', () {
      final streamController = StreamController<int>.broadcast();
      final singleSubscriptionStream =
          streamController.stream.toSingleSubscriptionStream();

      expect(singleSubscriptionStream.isBroadcast, isFalse);
      singleSubscriptionStream.listen(null);
      expect(() => singleSubscriptionStream.listen(null), throwsStateError);
    });

    test('Emitting values since listening', () {
      final streamController = StreamController<int>.broadcast();
      final singleSubscriptionStream =
          streamController.stream.toSingleSubscriptionStream();

      expect(
        singleSubscriptionStream,
        emitsInOrder(<dynamic>[1, 2, 3, emitsDone]),
      );

      streamController.add(1);
      streamController.add(2);
      streamController.add(3);
      streamController.close();
    });

    test('Assert isBroadcast', () {
      Stream<void>.empty().toSingleSubscriptionStream();

      expect(
        () => Stream.value(1).toSingleSubscriptionStream(),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
