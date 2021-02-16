/// Pair of [key] and [value].
class KeyAndValue<K extends Object, V> {
  /// The key of the [KeyAndValue].
  final K key;

  /// The value associated to [key].
  final V value;

  /// Construct a [KeyAndValue] with [key] and [key].
  const KeyAndValue(this.key, this.value);

  @override
  String toString() => "{ '$key': $value }";
}

/// Convert a map to list of [KeyAndValue]s.
extension MapToListOfKeyAndValuesExtension<Key extends Object>
    on Map<Key, Object?> {
  /// Convert this map to list of [KeyAndValue]s.
  List<KeyAndValue<Key, Object?>> toListOfKeyAndValues() {
    final pairs = entries.map((e) => KeyAndValue<Key, Object?>(e.key, e.value));
    return List.unmodifiable(pairs);
  }
}
