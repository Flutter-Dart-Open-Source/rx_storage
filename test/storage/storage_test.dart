import 'package:collection/collection.dart';
import 'package:rx_storage/rx_storage.dart';
import 'package:test/test.dart';

import '../fake_storage.dart';

void main() {
  group('Storage', () {
    const kTestValues = <String, dynamic>{
      'String': 'hello world',
      'bool': true,
      'int': 42,
      'double': 3.14159,
      'List': <String>['foo', 'bar'],
    };

    const kTestValues2 = <String, dynamic>{
      'String': 'goodbye world',
      'bool': false,
      'int': 1337,
      'double': 2.71828,
      'List': <String>['baz', 'quox'],
    };

    FakeStorage storage;
    RxStorage rxStorage;

    setUp(() {
      storage = FakeStorage(kTestValues);
      rxStorage = RxStorage(storage, const DefaultLogger());
    });

    tearDown(() async {
      await rxStorage.clear();
    });

    test('reading', () async {
      expect(await rxStorage.get('String'), kTestValues['String']);
      expect(await rxStorage.get('bool'), kTestValues['bool']);
      expect(await rxStorage.get('int'), kTestValues['int']);
      expect(await rxStorage.get('double'), kTestValues['double']);
      expect(await rxStorage.get('List'), kTestValues['List']);
      expect(await rxStorage.getString('String'), kTestValues['String']);
      expect(await rxStorage.getBool('bool'), kTestValues['bool']);
      expect(await rxStorage.getInt('int'), kTestValues['int']);
      expect(await rxStorage.getDouble('double'), kTestValues['double']);
      expect(await rxStorage.getStringList('List'), kTestValues['List']);
    });

    test('writing', () async {
      await Future.wait(<Future<bool>>[
        rxStorage.setString('String', kTestValues2['String']),
        rxStorage.setBool('bool', kTestValues2['bool']),
        rxStorage.setInt('int', kTestValues2['int']),
        rxStorage.setDouble('double', kTestValues2['double']),
        rxStorage.setStringList('List', kTestValues2['List'])
      ]);

      expect(await rxStorage.getString('String'), kTestValues2['String']);
      expect(await rxStorage.getBool('bool'), kTestValues2['bool']);
      expect(await rxStorage.getInt('int'), kTestValues2['int']);
      expect(await rxStorage.getDouble('double'), kTestValues2['double']);
      expect(await rxStorage.getStringList('List'), kTestValues2['List']);
    });

    test('removing', () async {
      const key = 'testKey';
      await rxStorage.setString(key, null);
      await rxStorage.setBool(key, null);
      await rxStorage.setInt(key, null);
      await rxStorage.setDouble(key, null);
      await rxStorage.setStringList(key, null);
      await rxStorage.remove(key);
    });

    test('containsKey', () async {
      const key = 'testKey';

      expect(await rxStorage.containsKey(key), false);

      await rxStorage.setString(key, 'test');
      expect(await rxStorage.containsKey(key), true);
    });

    test('clearing', () async {
      await rxStorage.clear();
      expect(await rxStorage.getString('String'), null);
      expect(await rxStorage.getBool('bool'), null);
      expect(await rxStorage.getInt('int'), null);
      expect(await rxStorage.getDouble('double'), null);
      expect(await rxStorage.getStringList('List'), null);
    });

    test('reloading', () async {
      await rxStorage.setString('String', kTestValues['String']);
      expect(await rxStorage.getString('String'), kTestValues['String']);

      storage.map = kTestValues2;
      expect(await rxStorage.getString('String'), kTestValues['String']);

      await rxStorage.reload();
      expect(await rxStorage.getString('String'), kTestValues2['String']);
    });

    test('writing copy of strings list', () async {
      final myList = <String>[];
      await rxStorage.setStringList('myList', myList);
      myList.add('foobar');

      final cachedList = await rxStorage.getStringList('myList');
      expect(cachedList, <String>[]);

      cachedList.add('foobar2');

      expect(await rxStorage.getStringList('myList'), <String>[]);
    });

    test('getKeys', () async {
      final keys = await rxStorage.getKeys();
      final expected = kTestValues.keys.toSet();

      expect(
        SetEquality<String>().equals(keys, expected),
        isTrue,
      );
    });
  });
}
