import 'package:moor/moor.dart';
import 'package:moor/src/runtime/data_class.dart';
import 'package:test/test.dart';
import 'data/tables/todos.dart';

final someDate = DateTime(2019, 06, 08);

final someTodoEntry = TodoEntry(
  id: 3,
  title: 'a title',
  content: null,
  targetDate: someDate,
  category: 3,
);

final regularSerialized = {
  'id': 3,
  'title': 'a title',
  'content': null,
  'target_date': someDate.millisecondsSinceEpoch,
  'category': 3,
};

final customSerialized = {
  'id': 3,
  'title': 'a title',
  'content': 'set to null',
  'target_date': someDate.toIso8601String(),
  'category': 3,
};

class CustomSerializer extends ValueSerializer {
  @override
  T fromJson<T>(json) {
    if (T == DateTime) {
      return DateTime.parse(json.toString()) as T;
    } else if (json == 'set to null') {
      return null;
    } else {
      return json as T;
    }
  }

  @override
  toJson<T>(T value) {
    if (T == DateTime) {
      return (value as DateTime).toIso8601String();
    } else if (value == null) {
      return 'set to null';
    } else {
      return value;
    }
  }
}

void main() {
  test('default serializer', () {
    final serializer = const ValueSerializer.defaults();
    expect(serializer.toJson<DateTime>(null), null);
    expect(serializer.fromJson<DateTime>(null), null);
  });

  group('serialization', () {
    test('with defaults', () {
      expect(someTodoEntry.toJson(), equals(regularSerialized));
    });

    test('with custom serializer', () {
      expect(someTodoEntry.toJson(serializer: CustomSerializer()),
          equals(customSerialized));
    });
  });

  group('deserialization', () {
    test('with defaults', () {
      expect(TodoEntry.fromJson(regularSerialized), equals(someTodoEntry));
    });

    test('with custom serializer', () {
      expect(
          TodoEntry.fromJson(customSerialized, serializer: CustomSerializer()),
          equals(someTodoEntry));
    });
  });
}
