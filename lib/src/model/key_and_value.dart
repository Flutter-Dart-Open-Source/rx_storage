/// Pair of [key] and [value].
class KeyAndValue<K, V> {
  /// The key of the [KeyAndValue].
  final K key;

  /// The value associated to [key].
  final V value;

  /// Construct a [KeyAndValue] with [key] and [key].
  const KeyAndValue(this.key, this.value);

  @override
  String toString() => "{ '$key': $value }";
}
