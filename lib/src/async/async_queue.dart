import 'dart:async';

import 'package:meta/meta.dart';

class _AsyncQueueEntry<T> {
  final Completer<T> completer;

  final AsyncQueueBlock<T> block;

  _AsyncQueueEntry(this.completer, this.block);
}

/// Function that returns a [Future].
@internal
typedef AsyncQueueBlock<T> = Future<T> Function();

/// A serial queue that executes single block at a time and it does this in FIFO order, first in, first out.
/// Serial queue are often used to synchronize access to a specific value or resource to prevent data races to occur.
@internal
class AsyncQueue<T> {
  final _blockS = StreamController<_AsyncQueueEntry<T>>();
  StreamSubscription<T>? _subscription;

  /// Construct [AsyncQueue].
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
      }).onError<Object>((e, s) {
        completer.completeError(e, s);
        throw e;
      });
    }).listen(null, onError: (Object _) {});
  }

  /// Close queue.
  Future<void> dispose() {
    if (_subscription == null || _blockS.isClosed) {
      throw StateError('AsyncQueue has been disposed!');
    }
    final future = _subscription!.cancel().then<void>((_) => _blockS.close());
    _subscription = null;
    return future;
  }

  /// Add block to queue.
  Future<T> enqueue(AsyncQueueBlock<T> block) {
    if (_subscription == null || _blockS.isClosed) {
      throw StateError('AsyncQueue has been disposed!');
    }

    final completer = Completer<T>.sync();
    _blockS.add(_AsyncQueueEntry(completer, block));
    return completer.future;
  }
}
