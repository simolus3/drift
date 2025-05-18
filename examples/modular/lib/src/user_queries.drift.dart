// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:drift/internal/modular.dart' as i1;
import 'package:modular/src/users.drift.dart' as i2;

i0.OnCreateQuery get $drift0 =>
    i0.OnCreateQuery(i0.CustomComponent('UPDATE users SET id = id + 1'));

class UserQueriesDrift extends i1.ModularAccessor {
  UserQueriesDrift(i0.GeneratedDatabase db) : super(db);
  i0.Selectable<i2.User> findUsers({FindUsers$predicate? predicate}) {
    var $arrayStartIndex = 1;
    final generatedpredicate = $write(
        predicate?.call(this.users) ??
            const i0.Expression.customComponent(i0.CustomComponent('(TRUE)')),
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedpredicate.amountOfVariables;
    return customSelectMapped<i2.User>(
        query:
            'SELECT id AS _c0, name AS _c1, biography AS _c2, preferences AS _c3, profile_picture AS _c4 FROM users WHERE ${generatedpredicate.sql}',
        variables: [...generatedpredicate.variables],
        readsFrom: {
          users,
          ...generatedpredicate.watchedTables,
        },
        createMapper: (i0.DriftResultSet resultSet) {
          final map_0 = users.createMapperFromPositions(const [
            (index: 0, name: '_c0'),
            (index: 1, name: '_c1'),
            (index: 2, name: '_c2'),
            (index: 3, name: '_c3'),
            (index: 4, name: '_c4'),
          ]);

          return (i0.DriftRow row) => map_0(row)!;
        });
  }

  i0.Selectable<i2.PopularUser> findPopularUsers() {
    return customSelectMapped<i2.PopularUser>(
        query:
            'SELECT id AS _c0, name AS _c1, biography AS _c2, preferences AS _c3, profile_picture AS _c4 FROM popular_users',
        variables: [],
        readsFrom: {
          users,
          follows,
        },
        createMapper: (i0.DriftResultSet resultSet) {
          final map_0 = popularUsers.createMapperFromPositions(const [
            (index: 0, name: '_c0'),
            (index: 1, name: '_c1'),
            (index: 2, name: '_c2'),
            (index: 3, name: '_c3'),
            (index: 4, name: '_c4'),
          ]);

          return (i0.DriftRow row) => map_0(row)!;
        });
  }

  Future<int> follow(int var1, int var2) {
    return customInsert(
      'INSERT INTO follows VALUES (?1, ?2)',
      variables: [(dialect.intType, var1), (dialect.intType, var2)],
      updates: {follows},
    );
  }

  i2.Users get users =>
      i1.ReadDatabaseContainer(attachedDatabase).resultSet<i2.Users>('users');
  i2.PopularUsers get popularUsers => i1.ReadDatabaseContainer(attachedDatabase)
      .resultSet<i2.PopularUsers>('popular_users');
  i2.Follows get follows => i1.ReadDatabaseContainer(attachedDatabase)
      .resultSet<i2.Follows>('follows');
}

typedef FindUsers$predicate = i0.Expression<bool> Function(i2.Users users);
