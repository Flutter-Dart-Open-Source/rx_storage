import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:meta/meta.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

import '../util.dart';

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
  static const _timeout = Duration(seconds: 30);

  final _blockS = StreamController<_AsyncQueueEntry<T>>();
  final _countS = StreamController<int>(sync: true);
  late final DisposeBag _bag;

  /// Construct [AsyncQueue].
  AsyncQueue(Object key, void Function() onTimeout) {
    _bag = DisposeBag(
        const <Object>[], '( AsyncQueue ~ $key ~ ${shortHash(this)} )');

    _blockS.disposedBy(_bag);
    _countS.disposedBy(_bag);

    final count$ = _countS.stream
        .scan<int?>((acc, value, _) => acc! + value, 0)
        .shareValueNotReplay(null);
    count$
        .where((count) => count == 0)
        .switchMap((_) => Rx.timer<void>(null, _timeout)
            .where((_) => count$.value == 0)
            .takeUntil(count$.where((count) => count != null && count > 0)))
        .listen((_) => onTimeout())
        .disposedBy(_bag);

    Future<T> executeBlock(_AsyncQueueEntry<T> entry) {
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
      }).whenComplete(() => _countS.add(-1));
    }

    _blockS.stream
        .asyncMap(executeBlock)
        .listen(null, onError: (Object _) {})
        .disposedBy(_bag);
  }

  /// Close queue.
  Future<void> dispose() => _bag.dispose();

  /// Add block to queue.
  Future<T> enqueue(AsyncQueueBlock<T> block) {
    assert(() {
      if (_bag.isClearing || _bag.isDisposed) {
        throw StateError('AsyncQueue has been disposed!');
      }
      return true;
    }());

    final completer = Completer<T>.sync();
    _blockS.add(_AsyncQueueEntry(completer, block));
    _countS.add(1);
    return completer.future;
  }
}
