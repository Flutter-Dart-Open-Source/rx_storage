import 'dart:async';

class AsyncQueueEntry<T> {
  final Completer<T> completer;
  final AsyncQueueBlock<T> block;

  AsyncQueueEntry(this.completer, this.block);
}

typedef AsyncQueueBlock<T> = Future<T> Function();

class AsyncQueue<T> {
  final _blockS = StreamController<AsyncQueueEntry<T>>();
  StreamSubscription<T>? _subscription;

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
      }).catchError(completer.completeError);
    }).listen(
      null,
      onError: (Object _) {},
    );
  }

  Future<void> dispose() {
    if (_subscription == null || _blockS.isClosed) {
      throw StateError('AsyncQueue has been disposed!');
    }
    final future =
        Future.wait<void>([_subscription!.cancel(), _blockS.close()]);
    _subscription = null;
    return future;
  }

  Future<T> enqueue(AsyncQueueBlock<T> block) {
    if (_subscription == null || _blockS.isClosed) {
      throw StateError('AsyncQueue has been disposed!');
    }

    final completer = Completer<T>.sync();
    _blockS.add(AsyncQueueEntry(completer, block));
    return completer.future;
  }
}
