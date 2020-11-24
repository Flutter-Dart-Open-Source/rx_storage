import 'package:rx_storage/src/interface/storage.dart';

import 'utils/synchronous_future.dart';

Future<T> _wrap<T>(T value) => SynchronousFuture(value);

class FakeStorage implements Storage {
  Map<String, dynamic> _map;
  Map<String, dynamic>? _pendingMap;

  FakeStorage(Map<String, dynamic> map) : _map = Map.of(map);

  set map(Map<String, dynamic> map) => _pendingMap = Map.of(map);

  Future<bool> _setValue(String key, dynamic value) {
    if (value is List<String>?) {
      _map[key] = value?.toList();
    } else {
      _map[key] = value;
    }
    return _wrap(true);
  }

  Future<T?> _getValue<T>(String key) {
    final value = _map[key] as T?;
    return value is List<String>
        ? _wrap(value.toList() as dynamic)
        : _wrap(value);
  }

  //
  //
  //

  @override
  Future<bool> clear() {
    _map.clear();
    return _wrap(true);
  }

  @override
  Future<bool> containsKey(String key) => _wrap(_map.containsKey(key));

  @override
  Future<Object?> get(String key) => _getValue(key);

  @override
  Future<bool?> getBool(String key) => _getValue(key);

  @override
  Future<double?> getDouble(String key) => _getValue(key);

  @override
  Future<int?> getInt(String key) => _getValue(key);

  @override
  Future<Set<String>> getKeys() => _wrap(_map.keys.toSet());

  @override
  Future<String?> getString(String key) => _getValue(key);

  @override
  Future<List<String>?> getStringList(String key) => _getValue(key);

  @override
  Future<void> reload() {
    if (_pendingMap != null) {
      _map = _pendingMap!;
      _pendingMap = null;
    }
    return _wrap(null);
  }

  @override
  Future<bool> remove(String key) => _setValue(key, null);

  @override
  Future<bool> setBool(String key, bool? value) => _setValue(key, value);

  @override
  Future<bool> setDouble(String key, double? value) => _setValue(key, value);

  @override
  Future<bool> setInt(String key, int? value) => _setValue(key, value);

  @override
  Future<bool> setString(String key, String? value) => _setValue(key, value);

  @override
  Future<bool> setStringList(String key, List<String>? value) =>
      _setValue(key, value);
}
