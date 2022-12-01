import 'package:drift/drift.dart';
import 'package:test/test.dart';

import 'generated/todos.dart';

final DateTime _someDate = DateTime(2019, 06, 08);

final TodoEntry _someTodoEntry = TodoEntry(
  id: 3,
  title: null,
  content: 'content',
  targetDate: _someDate,
  category: 3,
  status: TodoStatus.open,
);

final Map<String, dynamic> _regularSerialized = {
  'id': 3,
  'title': null,
  'content': 'content',
  'target_date': _someDate.millisecondsSinceEpoch,
  'category': 3,
  'status': TodoStatus.open.name,
};

final Map<String, dynamic> _asTextSerialized = {
  'id': 3,
  'title': null,
  'content': 'content',
  'target_date': _someDate.toIso8601String(),
  'category': 3,
  'status': TodoStatus.open.name,
};

final Map<String, dynamic> _customSerialized = {
  'id': 3,
  'title': 'set to null',
  'content': 'content',
  'target_date': _someDate.toIso8601String(),
  'category': 3,
  'status': TodoStatus.open.name,
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
      expect(_someTodoEntry.toJson(), equals(_regularSerialized));
    });

    test('with default serializer, date as text', () {
      expect(
        _someTodoEntry.toJson(
            serializer: const ValueSerializer.defaults(
                serializeDateTimeValuesAsString: true)),
        equals(_asTextSerialized),
      );
    });

    test('applies json type converter', () {
      const serialized = {
        'txt': {'data': 'foo'}
      };

      expect(PureDefault(txt: MyCustomObject('foo')).toJson(), serialized);
      expect(PureDefault.fromJson(serialized),
          PureDefault(txt: MyCustomObject('foo')));
    });

    test('with custom serializer', () {
      expect(_someTodoEntry.toJson(serializer: CustomSerializer()),
          equals(_customSerialized));
    });
  });

  group('deserialization', () {
    test('with defaults', () {
      expect(TodoEntry.fromJson(_regularSerialized), equals(_someTodoEntry));
      expect(TodoEntry.fromJson(_asTextSerialized), equals(_someTodoEntry));
    });

    test('with date-as-text serializer', () {
      const serializer =
          ValueSerializer.defaults(serializeDateTimeValuesAsString: true);

      expect(TodoEntry.fromJson(_regularSerialized, serializer: serializer),
          equals(_someTodoEntry));
      expect(TodoEntry.fromJson(_asTextSerialized, serializer: serializer),
          equals(_someTodoEntry));
    });

    test('with custom serializer', () {
      expect(
          TodoEntry.fromJson(_customSerialized, serializer: CustomSerializer()),
          equals(_someTodoEntry));
    });
  });
}
