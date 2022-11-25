import 'package:drift/drift.dart';

import 'accessor.drift.dart';
import 'database.dart';

@DriftAccessor(
  include: {'src/users.drift'},
  queries: {'addUser': r'INSERT INTO users $user;'},
)
class MyAccessor extends DatabaseAccessor<Database> with $MyAccessorMixin {
  MyAccessor(super.attachedDatabase);
}
