import '../interface/storage.dart';
import '../model/key_and_value.dart';

/// Log messages about operations (such as read, write, value change) and stream events.
abstract class Logger {
  /// Called when values have changed.
  void keysChanged(Iterable<KeyAndValue<Object, Object?>> pairs);

  /// Called when the stream emits an item.
  void doOnDataStream(KeyAndValue<Object, Object?> pair);

  /// Called when the stream emits an error.
  void doOnErrorStream(Object error, StackTrace stackTrace);

  /// Called when reading value from [Storage].
  void readValue(Type type, Object key, Object? value);

  /// Called when writing value to [Storage].
  void writeValue(Type type, Object key, Object? value, bool writeResult);
}
