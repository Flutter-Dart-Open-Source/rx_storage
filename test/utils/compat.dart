import 'package:rx_storage/rx_storage.dart';

T _identity<T>(T t) => t;

extension RxCompatExtensions on RxStorage<String, void> {
  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with key was changed.
  Stream<Object?> getStream(String key) => observe<Object>(key, _identity);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a bool.
  Stream<bool?> getBoolStream(String key) =>
      observe(key, (Object? s) => s as bool?);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a double.
  Stream<double?> getDoubleStream(String key) =>
      observe(key, (Object? s) => s as double?);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a int.
  Stream<int?> getIntStream(String key) =>
      observe(key, (Object? s) => s as int?);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a String.
  Stream<String?> getStringStream(String key) =>
      observe(key, (Object? s) => s as String?);

  /// Return [Stream] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This stream will emit an error if it's not a string set.
  Stream<List<String>?> getStringListStream(String key) =>
      observe(key, (Object? s) => s as List<String>?);

  /// Return [Stream] that will emit all keys read from persistent storage.
  /// It will automatic emit all keys when any value was changed.
  Stream<Set<String>> getKeysStream() =>
      observeAll().map((event) => event.keys.toSet());
}

extension CompatExtensions on Storage<String, void> {
  /// Reads a value of any type from persistent storage.
  Future<Object?> get(String key) => read<Object>(key, _identity);

  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a bool.
  Future<bool?> getBool(String key) => read(key, (Object? s) => s as bool?);

  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a double.
  Future<double?> getDouble(String key) =>
      read(key, (Object? s) => s as double?);

  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a int.
  Future<int?> getInt(String key) => read(key, (Object? s) => s as int?);

  /// Returns all keys in the persistent storage.
  Future<Set<String>> getKeys() =>
      readAll().then((value) => value.keys.toSet());

  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a String.
  Future<String?> getString(String key) =>
      read(key, (Object? s) => s as String?);

  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a string set.
  Future<List<String>?> getStringList(String key) =>
      read(key, (Object? s) => s as List<String>?);

  /// Saves a boolean [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  Future<void> setBool(String key, bool? value) => write(key, value, _identity);

  /// Saves a double [value] to persistent storage in the background.
  ///
  /// Android doesn't support storing doubles, so it will be stored as a float.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  Future<void> setDouble(String key, double? value) =>
      write(key, value, _identity);

  /// Saves an integer [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  Future<void> setInt(String key, int? value) => write(key, value, _identity);

  /// Saves a string [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  Future<void> setString(String key, String? value) =>
      write(key, value, _identity);

  /// Saves a list of strings [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  Future<void> setStringList(String key, List<String>? value) =>
      write(key, value, _identity);
}
