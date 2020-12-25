import 'package:rx_storage/rx_storage.dart';
import 'package:test/test.dart';

import '../fake_storage.dart';
import '../utils/compat.dart';

void main() {
  group('Test Stream', () {
    const kTestValues = <String, dynamic>{
      'String': 'hello world',
      'bool': true,
      'int': 42,
      'double': 3.14159,
      'List': <String>['foo', 'bar'],
    };

    FakeStorage fakeStorage;
    FakeRxStorage rxStorage;

    setUp(() {
      fakeStorage = FakeStorage(kTestValues);

      rxStorage = FakeRxStorage(
        fakeStorage,
        const DefaultLogger(),
      );
    });

    tearDown(() async => await rxStorage.dispose());

    test(
      'Stream will emit error when read value is not valid type, or emit null when value is not set',
      () async {
        final intStream =
            rxStorage.getIntStream('bool'); // Actual: Stream<bool>
        await expectLater(
          intStream,
          emitsAnyOf([
            isNull,
            emitsError(isA<TypeError>()),
          ]),
        );

        final listStringStream =
            rxStorage.getStringListStream('String'); // Actual: Stream<String>
        await expectLater(
          listStringStream,
          emitsAnyOf([
            isNull,
            emitsError(isA<TypeError>()),
          ]),
        );

        final noSuchStream =
            rxStorage.getIntStream('###String'); // Actual: Stream<String>

        await expectLater(
          noSuchStream,
          emits(isNull),
        );
      },
    );

    test(
      'Stream will emit value as soon as possible after listen',
      () async {
        await Future.wait([
          expectLater(
            rxStorage.getIntStream('int'),
            emits(anything),
          ),
          expectLater(
            rxStorage.getBoolStream('bool'),
            emits(anything),
          ),
          expectLater(
            rxStorage.getDoubleStream('double'),
            emits(anything),
          ),
          expectLater(
            rxStorage.getStringStream('String'),
            emits(anything),
          ),
          expectLater(
            rxStorage.getStringListStream('List'),
            emits(anything),
          ),
          expectLater(
            rxStorage.getStream('No such key'),
            emits(isNull),
          ),
        ]);
      },
    );

    test(
      'Stream will emit value as soon as possible after listen,'
      ' and will emit value when value associated with key change',
      () async {
        ///
        /// Bool
        ///
        final streamBool = rxStorage.getBoolStream('bool');
        final expectStreamBoolFuture = expectLater(
          streamBool,
          emitsInOrder([anything, false, true, false, true, false]),
        );
        await rxStorage.setBool('bool', false);
        await rxStorage.setBool('bool', true);
        await rxStorage.setBool('bool', false);
        await rxStorage.setBool('bool', true);
        await rxStorage.setBool('bool', false);

        ///
        /// Double
        ///
        final streamDouble = rxStorage.getDoubleStream('double');
        final expectStreamDoubleFuture = expectLater(
          streamDouble,
          emitsInOrder([anything, 0.3333, 1, 2, isNull, 3, isNull, 4]),
        );
        await rxStorage.setDouble('double', 0.3333);
        await rxStorage.setDouble('double', 1);
        await rxStorage.setDouble('double', 2);
        await rxStorage.setDouble('double', null);
        await rxStorage.setDouble('double', 3);
        await rxStorage.remove('double');
        await rxStorage.setDouble('double', 4);

        ///
        /// Int
        ///
        final streamInt = rxStorage.getIntStream('int');
        final expectStreamIntFuture = expectLater(
          streamInt,
          emitsInOrder([anything, 1, isNull, 2, 3, isNull, 3, 2, 1]),
        );
        await rxStorage.setInt('int', 1);
        await rxStorage.setInt('int', null);
        await rxStorage.setInt('int', 2);
        await rxStorage.setInt('int', 3);
        await rxStorage.remove('int');
        await rxStorage.setInt('int', 3);
        await rxStorage.setInt('int', 2);
        await rxStorage.setInt('int', 1);

        ///
        /// String
        ///
        final streamString = rxStorage.getStringStream('String');
        final expectStreamStringFuture = expectLater(
          streamString,
          emitsInOrder([anything, 'h', 'e', 'l', 'l', 'o', isNull]),
        );
        await rxStorage.setString('String', 'h');
        await rxStorage.setString('String', 'e');
        await rxStorage.setString('String', 'l');
        await rxStorage.setString('String', 'l');
        await rxStorage.setString('String', 'o');
        await rxStorage.setString('String', null);

        ///
        /// List<String>
        ///
        final streamListString = rxStorage.getStringListStream('List');
        final expectStreamListStringFuture = expectLater(
          streamListString,
          emitsInOrder([
            anything,
            <String>['1', '2', '3'],
            <String>['1', '2', '3', '4'],
            <String>['1', '2', '3', '4', '5'],
            <String>['1', '2', '3', '4'],
            <String>['1', '2', '3'],
            <String>['1', '2'],
            <String>['1'],
            <String>[],
            isNull,
            <String>['done'],
          ]),
        );
        await rxStorage.setStringList('List', ['1', '2', '3']);
        await rxStorage.setStringList('List', ['1', '2', '3', '4']);
        await rxStorage.setStringList('List', ['1', '2', '3', '4', '5']);
        await rxStorage.setStringList('List', ['1', '2', '3', '4']);
        await rxStorage.setStringList('List', ['1', '2', '3']);
        await rxStorage.setStringList('List', ['1', '2']);
        await rxStorage.setStringList('List', ['1']);
        await rxStorage.setStringList('List', []);
        await rxStorage.remove('List');
        await rxStorage.setStringList('List', ['done']);

        await Future.wait([
          expectStreamBoolFuture,
          expectStreamDoubleFuture,
          expectStreamIntFuture,
          expectStreamStringFuture,
          expectStreamListStringFuture,
        ]);
      },
    );

    test('Does not emit anything after disposed', () async {
      final stream = rxStorage.getStringListStream('List');

      const expected = [
        anything,
        ['before', 'dispose', '1'],
        ['before', 'dispose', '2'],
      ];
      var index = 0;
      final result = <bool>[];
      stream.listen(
        (data) => result.add(index == 0 ? true : data == expected[index++]),
      );

      for (final v in expected.skip(1)) {
        await rxStorage.setStringList(
          'List',
          v,
        );
        await Future.delayed(Duration.zero);
      }

      // delay
      await Future.delayed(const Duration(microseconds: 500));
      await rxStorage.dispose();
      await Future.delayed(Duration.zero);

      try {
        // cannot use anymore
        await rxStorage.setStringList(
          'List',
          <String>['after', 'dispose'],
        );
        // working fine
        expect(
          await rxStorage.getStringList('List'),
          <String>['after', 'dispose'],
        );
      } catch (e) {
        expect(e, isStateError);
      }

      // timeout is 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      expect(result.length, expected.length);
      expect(result.every((element) => element), isTrue);
    });

    test('Emit null when clearing', () async {
      final stream = rxStorage.getStringListStream('List');

      final later = expectLater(
        stream,
        emitsInOrder(
          [
            anything,
            isNull,
          ],
        ),
      );

      await rxStorage.clear();

      await later;
    });

    test('Emit value when reloading', () async {
      final stream = rxStorage.getStringListStream('List');

      final later = expectLater(
        stream,
        emitsInOrder(
          [
            anything,
            ['AFTER RELOAD'],
            ['WORKING 1'],
            ['WORKING 2'],
          ],
        ),
      );

      fakeStorage.map = {
        'List': ['AFTER RELOAD']
      };
      await rxStorage.reload(); // emits ['AFTER RELOAD']

      await rxStorage.setStringList('List', ['WORKING 1']); // emits ['WORKING']

      fakeStorage.map = {
        'List': ['WORKING 2'],
      };
      await rxStorage.reload(); // emits ['WORKING']

      await later;
    });

    test('Emit keys', () async {
      final keysStream = rxStorage.getKeysStream();

      final future = expectLater(
        keysStream,
        emitsInOrder([
          anything,
          anything,
          anything,
          anything,
        ]),
      );

      await rxStorage.setInt('int', 0);
      await rxStorage.setDouble('double', 0);
      await rxStorage.setString('String', '');

      await future;
    });

    test('Stream is single-subscription stream', () {
      final stream = rxStorage.getStringListStream('List');
      expect(stream.isBroadcast, isFalse);
      stream.listen(null);
      expect(() => stream.listen(null), throwsStateError);
    });
  });
}
