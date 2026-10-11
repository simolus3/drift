import 'package:drift3_preview/drift.dart';
import 'package:shared/tables.dart';

import 'database.drift.dart';

// Additional table we only need on the server
class ActiveSessions extends Table {
  IntColumn get user => integer().references(Users, #id);
  TextColumn get bearerToken => text();
}

@DriftDatabase(
  tables: [ActiveSessions],
  include: {'package:shared/shared.drift'},
)
final class ServerDatabase extends $ServerDatabase {
  ServerDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        if (details.wasCreated) {
          await usersQueries
              .insertOne(UsersCompanion.insert(name: 'Demo user'));
          await postsQueries.insertOne(
              PostsCompanion.insert(author: 1, content: Value('Test post')));
        }
      },
    );
  }

  Future<User?> authenticateUser(String token) async {
    final query = select(users).join([
      Join.inner(activeSessions, on: activeSessions.user.equalsExp(users.id))
    ]);
    query.where(activeSessions.bearerToken.equals(token));

    final row = await query.getSingleOrNull();
    final user = row?.readTable(users);

    return user;
  }
}
