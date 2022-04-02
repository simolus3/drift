import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';

void main() {
  test('data classes can be serialized', () {
    final entry = TodoEntry(
      id: 13,
      title: 'Title',
      content: 'Content',
      targetDate: DateTime.now(),
    );

    final serialized = entry.toJsonString();
    final deserialized = TodoEntry.fromJsonString(serialized);

    expect(deserialized, equals(deserialized));
  });

  group('default serializer', () {
    const serializer = ValueSerializer.defaults();
    test('can deserialize ints as doubles', () {
      expect(serializer.fromJson<double>(3), 3.0);
    });

    test('can deserialize non-null values with nullable types', () {
      expect(serializer.fromJson<double?>(3), 3.0);
      expect(serializer.fromJson<DateTime?>(0),
          DateTime.fromMillisecondsSinceEpoch(0));
      expect(serializer.fromJson<Uint8List?>([0, 1]), [0, 1]);
    });

    test('can be overridden globally', () {
      final old = driftRuntimeOptions.defaultSerializer;
      driftRuntimeOptions.defaultSerializer = _MySerializer();

      final entry = TodoEntry(
        id: 13,
        title: 'Title',
        content: 'Content',
        category: 3,
        targetDate: DateTime.now(),
      );
      expect(
        entry.toJson(),
        {
          'id': 'foo',
          'title': 'foo',
          'content': 'foo',
          'category': 'foo',
          'target_date': 'foo',
        },
      );

      driftRuntimeOptions.defaultSerializer = old;
    });

    test('can serialize and deserialize blob columns', () {
      final user = User(
        id: 3,
        name: 'Username',
        isAwesome: true,
        profilePicture: Uint8List.fromList([1, 2, 3, 4]),
        creationTime: DateTime.now(),
      );

      final recovered = User.fromJsonString(user.toJsonString());

      // Note: Some precision is lost when serializing DateTimes, so we're using
      // custom expects instead of expect(recovered, user)
      expect(recovered.id, user.id);
      expect(recovered.name, user.name);
      expect(recovered.isAwesome, user.isAwesome);
      expect(recovered.profilePicture, user.profilePicture);
    });
  });

  test('generated data classes can be converted to companions', () {
    final entry = Category(
      id: 3,
      description: 'description',
      priority: CategoryPriority.low,
      descriptionInUpperCase: 'ignored',
    );
    final companion = entry.toCompanion(false);

    expect(companion.runtimeType, CategoriesCompanion);
    expect(
      companion,
      equals(CategoriesCompanion.insert(
        description: 'description',
        id: const Value(3),
        priority: const Value(CategoryPriority.low),
      )),
    );
  });

  test('data classes can be converted to companions with null to absent', () {
    final entry = PureDefault(txt: null);

    expect(entry.toCompanion(false),
        const PureDefaultsCompanion(txt: Value(null)));
    expect(entry.toCompanion(true), const PureDefaultsCompanion());
  });

  test('nullable values cannot be used with nullOrAbsent', () {
    expect(
        // ignore: prefer_const_constructors
        () => Value<int?>.ofNullable(null),
        throwsA(isA<AssertionError>()));

    expect(const Value<int>.ofNullable(null).present, isFalse);
    expect(const Value<int?>.ofNullable(12).present, isTrue);
    expect(const Value<int>.ofNullable(23).present, isTrue);
  });

  test('companions support hash and equals', () {
    const first = CategoriesCompanion(description: Value('foo'));
    final equalToFirst = CategoriesCompanion.insert(description: 'foo');
    const different = CategoriesCompanion(description: Value('bar'));

    expect(first.hashCode, equalToFirst.hashCode);
    expect(first, equals(equalToFirst));

    expect(first.hashCode, isNot(equals(different.hashCode)));
    expect(first, isNot(equals(different)));
  });

  group('value: hash and ==:', () {
    test('equal when values are same', () {
      const first = Value(0);
      const equalToFirst = Value(0);
      const different = Value(1);

      expect(first.hashCode, equalToFirst.hashCode);
      expect(first, equals(equalToFirst));

      expect(first.hashCode, isNot(equals(different.hashCode)));
      expect(first, isNot(equals(different)));
    });

    test('equal when value is absent and generic is different', () {
      const first = Value<int>.absent();
      const equalToFirst = Value<String>.absent();

      expect(first.hashCode, equalToFirst.hashCode);
      expect(first, equals(equalToFirst));
    });

    test('equal when value is null and generic is different', () {
      const first = Value<int?>(null);
      const equalToFirst = Value<String?>(null);

      expect(first.hashCode, equals(equalToFirst.hashCode));
      expect(first, equals(equalToFirst));
    });

    test("don't equal when one value is absent and the other one is null", () {
      const first = Value.absent();
      const different = Value(null);

      expect(first.hashCode, isNot(equals(different.hashCode)));
      expect(first, isNot(equals(different)));
    });
  });
}

class _MySerializer extends ValueSerializer {
  @override
  T fromJson<T>(dynamic json) {
    throw StateError('Should not be called');
  }

  @override
  dynamic toJson<T>(T value) {
    return 'foo';
  }
}
