import 'dart:async';

/// Transforms each element of this stream into a new stream event, and reject null.
/// ### Example
///
///     Stream.fromIterable([1, 'two', 3, 'four'])
///       .mapNotNull((i) => i is int ? i * 2 : null)
///       .listen(print); // prints 2, 6
///
/// #### as opposed to:
///
///     Stream.fromIterable([1, 'two', 3, 'four'])
///       .map((i) => i is int ? i * 2 : null)
///       .where((i) => i != null)
///       .listen(print); // prints 2, 6
extension MapNotNullStreamExtension<T> on Stream<T> {
  /// Transforms each element of this stream into a new stream event, and reject null.
  Stream<R> mapNotNull<R extends Object>(R? Function(T) mapper) {
    late StreamController<R> controller;
    late StreamSubscription<T> subscription;

    void onListen() {
      subscription = listen(
        (data) {
          R? mappedValue;

          try {
            mappedValue = mapper(data);
          } catch (e, s) {
            controller.addError(e, s);
            return;
          }

          if (mappedValue != null) {
            controller.add(mappedValue);
          }
        },
        onError: controller.addError,
        onDone: controller.close,
      );
    }

    Future<void> onCancel() => subscription.cancel();

    if (isBroadcast) {
      controller = StreamController<R>.broadcast(
        sync: true,
        onListen: onListen,
        onCancel: onCancel,
      );
    } else {
      controller = StreamController<R>(
        sync: true,
        onListen: onListen,
        onPause: () => subscription.pause(),
        onResume: () => subscription.resume(),
        onCancel: onCancel,
      );
    }

    return controller.stream;
  }
}
