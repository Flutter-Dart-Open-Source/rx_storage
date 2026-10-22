import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:meta/meta.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

import '../util.dart';

final class _AsyncQueueEntry<T> {
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
final class AsyncQueue<T> {
  final _blockS = StreamController<_AsyncQueueEntry<T>>();
  final _pendingEntries = <_AsyncQueueEntry<T>>{};
  late final DisposeBag _bag;
  Future<void>? _disposeFuture;
  var _isDisposed = false;

  final _countS = StateSubject<int>(0, sync: true);

  /// Construct an [AsyncQueue].
  AsyncQueue({
    required Object key,
    required Duration timeout,
    required void Function() onTimeout,
  }) {
    _bag = DisposeBag(
        const <Object>[], '( AsyncQueue ~ $key ~ ${shortHash(this)} )');

    _blockS.disposedBy(_bag);
    _countS.disposedBy(_bag);

    // when the queue is empty, we wait for a timeout to occur
    // and then we call the onTimeout callback.
    _countS
        .where((count) => count == 0)
        .switchMap((_) => Rx.timer<void>(null, timeout)
            .where((_) => _countS.value == 0)
            .takeUntil(_countS.where((count) => count > 0)))
        .listen((_) {
      assert(() {
        if (_countS.value != 0) {
          throw StateError('AsyncQueue is not empty!');
        }
        return true;
      }());

      onTimeout();
    }).disposedBy(_bag);

    Future<T> executeBlock(_AsyncQueueEntry<T> entry) async {
      _pendingEntries.remove(entry);
      try {
        final value = await entry.block();
        entry.completer.complete(value);
        return value;
      } catch (e, s) {
        entry.completer.completeError(e, s);
        rethrow;
      } finally {
        if (!_isDisposed) {
          _countS.value = _countS.value - 1;
        }
      }
    }

    _blockS.stream
        .asyncMap(executeBlock)
        .listen(null, onError: (Object _) {})
        .disposedBy(_bag);
  }

  /// Closes the queue and rejects pending entries with a [StateError].
  ///
  /// The active task can finish without keeping disposal waiting.
  Future<void> dispose() {
    final disposing = _disposeFuture;
    if (disposing != null) {
      return disposing;
    }

    _isDisposed = true;
    final future = _disposeFuture = _bag.dispose();
    final pending = _pendingEntries.toList(growable: false);
    _pendingEntries.clear();
    for (final entry in pending) {
      entry.completer.completeError(
        StateError('AsyncQueue was disposed before the task started.'),
        StackTrace.current,
      );
    }
    return future;
  }

  /// Add block to queue.
  Future<T> enqueue(AsyncQueueBlock<T> block) {
    if (_isDisposed) {
      throw StateError('AsyncQueue has been disposed!');
    }

    final completer = Completer<T>.sync();
    final entry = _AsyncQueueEntry(completer, block);
    _pendingEntries.add(entry);
    _blockS.add(entry);
    _countS.value = _countS.value + 1;
    return completer.future;
  }
}
