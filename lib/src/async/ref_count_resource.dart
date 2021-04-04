import 'package:meta/meta.dart';

// ignore_for_file: public_member_api_docs

@internal
class RefCountResource<Key, T> {
  final _items = <Key, _Item<T>>{};
  final T Function(Key) create;
  final void Function(Key, T)? onRelease;

  RefCountResource({
    required this.create,
    this.onRelease,
  });

  T acquire(Key key) {
    final item = _items.putIfAbsent(key, () => _Item(create(key)));
    item.refCount++;
    return item.value;
  }

  void release(Key key, T value) {
    final existing = _items[key];
    if (existing == null || !identical(existing.value, value)) {
      throw StateError(
          'inconsistent release for key $key, seems like value $value was leaked or never acquired');
    }
    existing.refCount--;
    if (existing.refCount < 1) {
      _items.remove(key);
      onRelease?.call(key, value);
    }
  }

  void releaseAll() {
    _items.forEach((key, value) => onRelease?.call(key, value.value));
    _items.clear();
  }

  int get size => _items.length;
}

class _Item<T> {
  final T value;
  var refCount = 0;

  _Item(this.value);
}

void main() {
  final ref = RefCountResource<String, int>(create: (i) {
    print('call $i');
    return 2;
  });

  print(ref.acquire('1'));
  print(ref.acquire('1'));
  print(ref.acquire('1'));

  ref.release('1', 2);
  ref.release('1', 2);
  ref.release('1', 3);

  print(ref.acquire('1'));
  print(ref.acquire('1'));
  print(ref.acquire('1'));
}
