import 'package:test/test.dart';

import 'data/tables/todos.dart';

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
}
