import 'dart:async';

/// TODO
class AsyncQueueEntry<T> {
  /// TODO
  final Completer<T> completer;

  /// TODO
  final AsyncQueueBlock<T> block;

  /// TODO
  AsyncQueueEntry(this.completer, this.block);
}

/// TODO
typedef AsyncQueueBlock<T> = Future<T> Function();

/// TODO
class AsyncQueue<T> {
  final _blockS = StreamController<AsyncQueueEntry<T>>();
  StreamSubscription<T>? _subscription;

  /// TODO
  AsyncQueue() {
    _subscription = _blockS.stream.asyncMap((entry) {
      final completer = entry.completer;

      Future<T> future;
      try {
        future = entry.block();
      } catch (e, s) {
        completer.completeError(e, s);
        rethrow;
      }

      return future.then((v) {
        completer.complete(v);
        return v;
      }).onError<Object>((Object e, StackTrace s) {
        completer.completeError(e, s);
        throw e;
      });
    }).listen(
      null,
      onError: (Object _) {},
    );
  }

  /// TODO
  Future<void> dispose() {
    if (_subscription == null || _blockS.isClosed) {
      throw StateError('AsyncQueue has been disposed!');
    }
    final future =
        Future.wait<void>([_subscription!.cancel(), _blockS.close()]);
    _subscription = null;
    return future;
  }

  /// TODO
  Future<T> enqueue(AsyncQueueBlock<T> block) {
    if (_subscription == null || _blockS.isClosed) {
      throw StateError('AsyncQueue has been disposed!');
    }

    final completer = Completer<T>.sync();
    _blockS.add(AsyncQueueEntry(completer, block));
    return completer.future;
  }
}
