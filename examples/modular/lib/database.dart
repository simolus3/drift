import 'package:drift/drift.dart';

import 'database.drift.dart';

@DriftDatabase(include: {
  'src/users.drift',
  'src/posts.drift',
  'src/search.drift',
})
class Database extends $Database {
  Database(super.e);

  @override
  int get schemaVersion => 1;
}
