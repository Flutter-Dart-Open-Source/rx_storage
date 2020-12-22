import 'dart:async';

/// A transformer that converts a Stream into a single-subscription stream.
class SingleSubscriptionTransformer<T> extends StreamTransformerBase<T, T> {
  /// Construct a [SingleSubscriptionTransformer] that converts a Stream
  /// into a single-subscription stream.
  const SingleSubscriptionTransformer();

  @override
  Stream<T> bind(Stream<T> stream) {
    StreamSubscription<T> subscription;
    StreamController<T> controller;

    controller = StreamController<T>(
      sync: true,
      onListen: () {
        subscription = stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () => subscription.cancel(),
    );

    return controller.stream;
  }
}

/// Converts a Stream into a single-subscription stream.
extension ToSingleSubscriptionStreamExtension<T> on Stream<T> {
  /// Converts a Stream into a single-subscription stream.
  Stream<T> toSingleSubscriptionStream() =>
      transform(SingleSubscriptionTransformer<T>());
}
