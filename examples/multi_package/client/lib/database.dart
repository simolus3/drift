import 'package:drift/drift.dart';

import 'database.drift.dart';

@DriftDatabase(include: {'package:shared/shared.drift'})
class ClientDatabase extends $ClientDatabase {
  ClientDatabase(super.e);

  @override
  int get schemaVersion => 1;

  Future<int> get locallySavedPosts async {
    final count = countAll();
    final query = selectOnly(posts)..addColumns([count]);
    return query.map((row) => row.read(count)!).getSingle();
  }
}
