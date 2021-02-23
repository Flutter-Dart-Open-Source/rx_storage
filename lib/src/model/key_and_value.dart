/// Pair of [key] and [value].
class KeyAndValue<K extends Object, V> {
  /// The key of the [KeyAndValue].
  final K key;

  /// The value associated to [key].
  final V value;

  /// The type of [value].
  final Type type;

  /// Construct a [KeyAndValue] with [key] and [key].
  // ignore: unnecessary_null_comparison
  const KeyAndValue(this.key, this.value, this.type) : assert(key != null);

  @override
  String toString() => 'KeyAndValue { key: $key, type: $type, value: $value }';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyAndValue &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          value == other.value &&
          type == other.type;

  @override
  int get hashCode => key.hashCode ^ value.hashCode ^ type.hashCode;
}

/// Convert a map to list of [KeyAndValue]s.
extension MapToListOfKeyAndValuesExtension<Key extends Object>
    on Map<Key, Object?> {
  /// Convert this map to list of [KeyAndValue]s.
  List<KeyAndValue<Key, Object?>> toListOfKeyAndValues() {
    final pairs = entries.map((e) {
      // value is null or value is not a [KeyAndValue].
      assert(e.value == null || e.value is! KeyAndValue<Key, Object?>);
      return KeyAndValue<Key, Object?>(e.key, e.value, dynamic);
    });
    return List.unmodifiable(pairs);
  }
}
