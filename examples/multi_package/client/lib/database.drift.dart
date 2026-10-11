// dart format width=80
// ignore_for_file: type=lint
import 'package:drift3_preview/drift.dart' as i0;
import 'package:shared/src/users.drift.dart' as i1;
import 'package:shared/src/posts.drift.dart' as i2;
import 'package:drift_sqlite/drift_sqlite.dart' as i3;
import 'package:shared/shared.drift.dart' as i4;

abstract base class $ClientDatabase extends i0.GeneratedDatabase {
  $ClientDatabase(super.implementation);
  i1.$UsersTable get users => i1.$UsersTable();
  i2.Posts get posts => i2.Posts();
  i0.TableOrViewStatements<i1.User, i1.$UsersTable> get usersQueries =>
      this.users.statements(this);
  i0.TableOrViewStatements<i2.Post, i2.Posts> get postsQueries =>
      this.posts.statements(this);
  @override
  Map<i0.KnownSqlDialect, Object> get dialectOptions => {
        i0.KnownSqlDialect.sqlite: const i3.SqliteOptions(
          strictTablesByDefault: true,
          storeDateTimesAsText: true,
          useBinaryJsonRepresentation: true,
        ),
      };
  i4.SharedDrift get sharedDrift => i4.SharedDrift(this);
  @override
  i0.DatabaseSchema get schema => _$schema;
  static final i0.DatabaseSchema _$schema = i0.DatabaseSchema([
    i1.$UsersTable(),
    i2.Posts(),
  ]);
}
