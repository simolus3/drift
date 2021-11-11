import 'package:test/test.dart';

import '../data/tables/todos.dart';

void main() {
  test('\$expandVar test', () {
    final db = TodoDb();

    expect(db.$expandVar(4, 0), '');
    expect(db.$expandVar(2, 3), '?2, ?3, ?4');
  });
}
