import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:test/test.dart';

import '../fake_storage.dart';
import '../utils/compat.dart';
import '../utils/user.dart';

void main() {
  group('Storage', () {
    const user1 = User(1, 'Name#1');
    const user2 = User(2, 'Name#2');

    final kTestValues = <String, dynamic>{
      'String': 'hello world',
      'bool': true,
      'int': 42,
      'double': 3.14159,
      'List': <String>['foo', 'bar'],
      'User': jsonEncode(user1),
    };

    final kTestValues2 = <String, dynamic>{
      'String': 'goodbye world',
      'bool': false,
      'int': 1337,
      'double': 2.71828,
      'List': <String>['baz', 'quox'],
      'User': jsonEncode(user2),
    };

    late FakeStorage storage;
    late FakeRxStorage rxStorage;

    setUp(() {
      storage = FakeStorage(kTestValues);
      rxStorage = FakeRxStorage(storage, const FakeDefaultLogger());
    });

    tearDown(() async {
      // disable before clearing :)
      storage.throws = false;
      storage.readAllThrows = false;
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
      expect(await rxStorage.readUser(), user1);
      expect(await rxStorage.readAll(), kTestValues);

      // forward error.
      storage.throws = true;

      expect(rxStorage.get('String'), throwsException);
      expect(rxStorage.get('bool'), throwsException);
      expect(rxStorage.get('int'), throwsException);
      expect(rxStorage.get('double'), throwsException);
      expect(rxStorage.get('List'), throwsException);
      expect(rxStorage.getString('String'), throwsException);
      expect(rxStorage.getBool('bool'), throwsException);
      expect(rxStorage.getInt('int'), throwsException);
      expect(rxStorage.getDouble('double'), throwsException);
      expect(rxStorage.getStringList('List'), throwsException);
      expect(rxStorage.readUser(), throwsException);

      // forward error.
      storage.readAllThrows = true;
      expect(rxStorage.readAll(), throwsException);
    });

    test('writing', () async {
      await Future.wait([
        rxStorage.setString('String', kTestValues2['String'] as String),
        rxStorage.setBool('bool', kTestValues2['bool'] as bool),
        rxStorage.setInt('int', kTestValues2['int'] as int),
        rxStorage.setDouble('double', kTestValues2['double'] as double),
        rxStorage.setStringList('List', kTestValues2['List'] as List<String>),
        rxStorage.writeUser(user2),
      ]);

      expect(await rxStorage.getString('String'), kTestValues2['String']);
      expect(await rxStorage.getBool('bool'), kTestValues2['bool']);
      expect(await rxStorage.getInt('int'), kTestValues2['int']);
      expect(await rxStorage.getDouble('double'), kTestValues2['double']);
      expect(await rxStorage.getStringList('List'), kTestValues2['List']);
      expect(await rxStorage.readUser(), user2);

      // forward error.
      storage.throws = true;

      expect(
        rxStorage.setString('String', kTestValues2['String'] as String),
        throwsException,
      );
      expect(
        rxStorage.setBool('bool', kTestValues2['bool'] as bool),
        throwsException,
      );
      expect(
        rxStorage.setInt('int', kTestValues2['int'] as int),
        throwsException,
      );
      expect(
        rxStorage.setDouble('double', kTestValues2['double'] as double),
        throwsException,
      );
      expect(
        rxStorage.setStringList('List', kTestValues2['List'] as List<String>),
        throwsException,
      );
      expect(
        rxStorage.writeUser(user2),
        throwsException,
      );
    });

    test('removing', () async {
      const key = 'testKey';

      await rxStorage.setString(key, null);
      await rxStorage.setBool(key, null);
      await rxStorage.setInt(key, null);
      await rxStorage.setDouble(key, null);
      await rxStorage.setStringList(key, null);
      await rxStorage.remove(key);

      // forward error.
      storage.throws = true;

      expect(rxStorage.setString(key, null), throwsException);
      expect(rxStorage.setBool(key, null), throwsException);
      expect(rxStorage.setInt(key, null), throwsException);
      expect(rxStorage.setDouble(key, null), throwsException);
      expect(rxStorage.setStringList(key, null), throwsException);
      expect(rxStorage.remove(key), throwsException);
    });

    test('containsKey', () async {
      const key = 'testKey';

      expect(await rxStorage.containsKey(key), false);

      await rxStorage.setString(key, 'test');
      expect(await rxStorage.containsKey(key), true);

      // forward error.
      storage.throws = true;
      expect(rxStorage.containsKey(key), throwsException);
    });

    test('clearing', () async {
      await rxStorage.clear();
      expect(await rxStorage.getString('String'), null);
      expect(await rxStorage.getBool('bool'), null);
      expect(await rxStorage.getInt('int'), null);
      expect(await rxStorage.getDouble('double'), null);
      expect(await rxStorage.getStringList('List'), null);
      expect(await rxStorage.readUser(), null);

      // forward error.
      // failed when clearing.
      storage.readAllThrows = false;
      storage.throws = true;
      await expectLater(rxStorage.clear(), throwsException);

      // forward error.
      // failed when reading all.
      storage.readAllThrows = true;
      storage.throws = false;
      expect(rxStorage.clear(), throwsException);
    });

    test('reloading', () async {
      await rxStorage.setString('String', kTestValues['String'] as String);
      expect(await rxStorage.getString('String'), kTestValues['String']);

      storage.map = kTestValues2;
      expect(await rxStorage.getString('String'), kTestValues['String']);

      await rxStorage.reload();
      expect(await rxStorage.getString('String'), kTestValues2['String']);

      // forward error.
      storage.map = kTestValues;
      storage.throws = true;
      expect(rxStorage.reload(), throwsException);
    });

    test('writing copy of strings list', () async {
      final myList = <String>[];
      await rxStorage.setStringList('myList', myList);
      myList.add('foobar');

      final cachedList = await rxStorage.getStringList('myList');
      expect(cachedList, <String>[]);

      cachedList!.add('foobar2');

      expect(await rxStorage.getStringList('myList'), <String>[]);
    });

    test('getKeys', () async {
      final keys = await rxStorage.getKeys();
      final expected = kTestValues.keys.toSet();

      expect(
        SetEquality<String>().equals(keys, expected),
        isTrue,
      );

      // forward error.
      storage.readAllThrows = true;
      expect(rxStorage.getKeys(), throwsException);
    });
  });
}
