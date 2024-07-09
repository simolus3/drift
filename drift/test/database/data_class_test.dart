import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';

void main() {
  test('data classes can be serialized', () {
    final entry = TodoEntry(
      id: RowId(13),
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
      expect(serializer.fromJson<Uint8List?>(const [0, 1]), const [0, 1]);
    });

    test('can be overridden globally', () {
      final old = driftRuntimeOptions.defaultSerializer;
      driftRuntimeOptions.defaultSerializer = _MySerializer();

      final entry = TodoEntry(
        id: RowId(13),
        title: 'Title',
        content: 'Content',
        category: 3,
        targetDate: DateTime.now(),
      );
      expect(
        entry.toJson(),
        const {
          'id': 'foo',
          'title': 'foo',
          'content': 'foo',
          'category': 'foo',
          'target_date': 'foo',
          'status': 'foo',
        },
      );

      driftRuntimeOptions.defaultSerializer = old;
    });

    test('can serialize and deserialize blob columns', () {
      final user = User(
        id: RowId(3),
        name: 'Username',
        isAwesome: true,
        profilePicture: Uint8List.fromList(const [1, 2, 3, 4]),
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
    const entry = Category(
      id: RowId(3),
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
        id: const Value(RowId(3)),
        priority: const Value(CategoryPriority.low),
      )),
    );
  });

  test('data classes can be converted to companions with null to absent', () {
    const entry = PureDefault(txt: null);

    expect(entry.toCompanion(false),
        const PureDefaultsCompanion(txt: Value(null)));
    expect(entry.toCompanion(true), const PureDefaultsCompanion());
  });

  test('data classes can be copied with changes given by companion', () {
    const nameless = DepartmentData(id: 1);
    expect(nameless.copyWithCompanion(DepartmentCompanion()),
        const DepartmentData(id: 1));
    expect(nameless.copyWithCompanion(DepartmentCompanion(id: Value(2))),
        const DepartmentData(id: 2));
    expect(nameless.copyWithCompanion(DepartmentCompanion(name: Value("a"))),
        const DepartmentData(id: 1, name: "a"));

    const named = DepartmentData(id: 2, name: "b");
    expect(named.copyWithCompanion(DepartmentCompanion()),
        const DepartmentData(id: 2, name: "b"));
    expect(named.copyWithCompanion(DepartmentCompanion(name: Value("c"))),
        const DepartmentData(id: 2, name: "c"));
    expect(named.copyWithCompanion(DepartmentCompanion(name: Value(null))),
        const DepartmentData(id: 2));
  });

  test('utilities to wrap nullable values', () {
    expect(
        // ignore: prefer_const_constructors, deprecated_member_use_from_same_package
        () => Value<int?>.ofNullable(null),
        throwsA(isA<AssertionError>()));

    expect(const Value<int?>.absentIfNull(null).present, isFalse);
    expect(const Value<int>.absentIfNull(null).present, isFalse);
    expect(const Value<int?>.absentIfNull(12).present, isTrue);
    expect(const Value<int>.absentIfNull(23).present, isTrue);
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
      const first = Value<Object?>.absent();
      const different = Value(null);

      expect(first.hashCode, isNot(equals(different.hashCode)));
      expect(first, isNot(equals(different)));
    });
  });
  test(
    'Insertable should have a const constructor so a subclass can be a const',
    () {
      const insertable = _MyInsertable();
      insertable.toColumns(false);
    },
  );
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

class _MyInsertable extends Insertable<void> {
  const _MyInsertable();

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) => const {};
}
