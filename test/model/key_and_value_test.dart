import 'package:rx_storage/src/model/key_and_value.dart';
import 'package:test/test.dart';

Type typeOf<T>() => T;

void main() {
  group('$KeyAndValue tests', () {
    test('Construct a KeyAndValue', () {
      KeyAndValue('key1', 'value', String);
      KeyAndValue('key2', 2, int);
      KeyAndValue('key3', 2.5, double);
      KeyAndValue('key4', true, bool);
      KeyAndValue('key5', null, Null);
      KeyAndValue('key6', <String>['v1', 'v2', 'v3'], typeOf<List<String>>());
      expect(true, isTrue);
    });

    test('KeyAndValue.==', () {
      expect(
        KeyAndValue('key1', 'value', String),
        KeyAndValue('key1', 'value', String),
      );
      expect(
        KeyAndValue('key2', 2, int),
        KeyAndValue('key2', 2, int),
      );
      expect(
        KeyAndValue('key3', 2.5, double),
        KeyAndValue('key3', 2.5, double),
      );
      expect(
        KeyAndValue('key4', true, bool),
        KeyAndValue('key4', true, bool),
      );
      expect(
        KeyAndValue('key5', null, Null),
        KeyAndValue('key5', null, Null),
      );
    });

    test('KeyAndValue.toString', () {
      expect(
        KeyAndValue('key1', 'value', String).toString(),
        'KeyAndValue { key: key1, type: String, value: value }',
      );
      expect(
        KeyAndValue('key2', 2, int).toString(),
        'KeyAndValue { key: key2, type: int, value: 2 }',
      );
      expect(
        KeyAndValue('key3', 2.5, double).toString(),
        'KeyAndValue { key: key3, type: double, value: 2.5 }',
      );
      expect(
        KeyAndValue('key4', true, bool).toString(),
        'KeyAndValue { key: key4, type: bool, value: true }',
      );
      expect(
        KeyAndValue('key5', null, Null).toString(),
        'KeyAndValue { key: key5, type: Null, value: null }',
      );
      expect(
        KeyAndValue('key6', <String>['v1', 'v2', 'v3'], typeOf<List<String>>())
            .toString(),
        'KeyAndValue { key: key6, type: List<String>, value: [v1, v2, v3] }',
      );
    });
  });
}
