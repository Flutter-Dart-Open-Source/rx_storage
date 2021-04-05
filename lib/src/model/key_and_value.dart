/// Pair of [key] and [value].
class KeyAndValue<K extends Object, V> {
  /// The key of the [KeyAndValue].
  final K key;

  /// The value associated to [key].
  final V value;

  /// The type of [value].
  final Type type;

  /// Construct a [KeyAndValue] with [key] and [key].
  const KeyAndValue(this.key, this.value, this.type);

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
      final value = e.value;
      return value is KeyAndValue<Key, Object?>
          ? value
          : KeyAndValue<Key, Object?>(e.key, value, dynamic);
    });
    return List.unmodifiable(pairs);
  }
}
