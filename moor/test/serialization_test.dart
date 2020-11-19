import 'package:moor/moor.dart';
import 'package:moor/src/runtime/data_class.dart';
import 'package:test/test.dart';
import 'data/tables/todos.dart';

final DateTime someDate = DateTime(2019, 06, 08);

final TodoEntry someTodoEntry = TodoEntry(
  id: 3,
  title: null,
  content: 'content',
  targetDate: someDate,
  category: 3,
);

final Map<String, dynamic> regularSerialized = {
  'id': 3,
  'title': null,
  'content': 'content',
  'target_date': someDate.millisecondsSinceEpoch,
  'category': 3,
};

final Map<String, dynamic> customSerialized = {
  'id': 3,
  'title': 'set to null',
  'content': 'content',
  'target_date': someDate.toIso8601String(),
  'category': 3,
};

class CustomSerializer extends ValueSerializer {
  @override
  T fromJson<T>(dynamic json) {
    if (<T>[] is List<DateTime?>) {
      return DateTime.parse(json.toString()) as T;
    } else if (json == 'set to null') {
      return null as T;
    } else {
      return json as T;
    }
  }

  @override
  dynamic toJson<T>(T value) {
    if (<T>[] is List<DateTime?>) {
      return (value as DateTime?)?.toIso8601String();
    } else if (value == null) {
      return 'set to null';
    } else {
      return value;
    }
  }
}

void main() {
  test('default serializer', () {
    const serializer = ValueSerializer.defaults();
    expect(serializer.toJson<DateTime?>(null), null);
    expect(serializer.fromJson<DateTime?>(null), null);
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
