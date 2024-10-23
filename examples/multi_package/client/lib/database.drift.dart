// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:shared/src/users.drift.dart' as i1;
import 'package:shared/src/posts.drift.dart' as i2;
import 'package:shared/shared.drift.dart' as i3;
import 'package:drift/internal/modular.dart' as i4;

abstract class $ClientDatabase extends i0.GeneratedDatabase {
  $ClientDatabase(i0.QueryExecutor e) : super(e);
  $ClientDatabaseManager get managers => $ClientDatabaseManager(this);
  late final i1.$UsersTable users = i1.$UsersTable(this);
  late final i2.Posts posts = i2.Posts(this);
  i3.SharedDrift get sharedDrift => i4.ReadDatabaseContainer(this)
      .accessor<i3.SharedDrift>(i3.SharedDrift.new);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [users, posts];
  @override
  i0.DriftDatabaseOptions get options =>
      const i0.DriftDatabaseOptions(storeDateTimeAsText: true);
}

class $ClientDatabaseManager {
  final $ClientDatabase _db;
  $ClientDatabaseManager(this._db);
  i1.$$UsersTableTableManager get users =>
      i1.$$UsersTableTableManager(_db, _db.users);
  i2.$PostsTableManager get posts => i2.$PostsTableManager(_db, _db.posts);
}
