import '../interface/storage.dart';
import '../model/key_and_value.dart';

/// Log messages about operations (such as read, write, value change) and stream events.
abstract class Logger {
  /// Called when values have changed.
  void keysChanged(Iterable<KeyAndValue<dynamic>> pairs);

  /// Called when the stream emits an item.
  void doOnDataStream(KeyAndValue pair);

  /// Called when the stream emits an error.
  void doOnErrorStream(dynamic error, StackTrace stackTrace);

  /// Called when reading value from [Storage].
  void readValue(Type type, String key, dynamic value);

  /// Called when writing value to [Storage].
  void writeValue(Type type, String key, dynamic value, bool writeResult);
}
