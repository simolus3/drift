import 'package:drift/drift.dart';

import 'accessor.dart';
import 'database.drift.dart';

@DriftDatabase(include: {
  'src/user_queries.drift',
  'src/posts.drift',
  'src/search.drift',
}, daos: [
  MyAccessor
])
class Database extends $Database {
  Database(super.e);

  @override
  int get schemaVersion => 1;
}
