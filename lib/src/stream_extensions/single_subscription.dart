import 'dart:async';

/// Converts a broadcast Stream into a single-subscription stream.
extension ToSingleSubscriptionStreamExtension<T> on Stream<T> {
  /// Converts a broadcast Stream into a single-subscription stream.
  Stream<T> toSingleSubscriptionStream() {
    assert(isBroadcast == true);
    final controller = StreamController<T>(sync: true);

    late StreamSubscription<T> subscription;
    controller.onListen = () {
      subscription = listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
    };
    controller.onCancel = () => subscription.cancel();

    return controller.stream;
  }
}
