import '../model/key_and_value.dart';
import 'logger.dart';

/// Default Logger's implementation, simply print to the console.
class DefaultLogger implements Logger {
  /// Construct a [DefaultLogger].
  const DefaultLogger();

  @override
  void keysChanged(Iterable<KeyAndValue<Object, Object?>> pairs) {
    print(' ↓ Key changes');
    print(pairs.map((p) => '    → $p').join('\n'));
  }

  @override
  void doOnDataStream(KeyAndValue<Object, Object?> pair) =>
      print(' → Stream emits data: $pair');

  @override
  void doOnErrorStream(Object error, StackTrace stackTrace) =>
      print(' → Stream emits error: $error, $stackTrace');

  @override
  void readValue(Type type, Object key, Object? value) =>
      print(" → Read value: type $type, key '$key' → $value");

  @override
  void writeValue(Type type, Object key, Object? value, bool writeResult) => print(
      " → Write value: type $type, key '$key', value $value  → result $writeResult");
}
