import 'package:drift/native.dart';

import '../../generated/todos.dart';

void main() {
  TodoDb(NativeDatabase.memory());
  print('database created');

  // Keep the process alive
  Stream<void>.periodic(const Duration(seconds: 10)).listen(null);
}
