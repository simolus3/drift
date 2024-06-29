// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:drift/internal/modular.dart' as i1;
import 'package:modular/src/users.drift.dart' as i2;

i0.OnCreateQuery get $drift0 =>
    i0.OnCreateQuery('UPDATE users SET id = id + 1');

class UserQueriesDrift extends i1.ModularAccessor {
  UserQueriesDrift(i0.GeneratedDatabase db) : super(db);
  i0.Selectable<i2.User> findUsers({FindUsers$predicate? predicate}) {
    var $arrayStartIndex = 1;
    final generatedpredicate = $write(
        predicate?.call(this.users) ?? const i0.CustomExpression('(TRUE)'),
        startIndex: $arrayStartIndex);
    $arrayStartIndex += generatedpredicate.amountOfVariables;
    return customSelect('SELECT * FROM users WHERE ${generatedpredicate.sql}',
        variables: [
          ...generatedpredicate.introducedVariables
        ],
        readsFrom: {
          users,
          ...generatedpredicate.watchedTables,
        }).asyncMap(users.mapFromRow);
  }

  i0.Selectable<i2.PopularUser> findPopularUsers() {
    return customSelect('SELECT * FROM popular_users',
        variables: [],
        readsFrom: {
          users,
          follows,
        }).asyncMap(popularUsers.mapFromRow);
  }

  Future<int> follow(int var1, int var2) {
    return customInsert(
      'INSERT INTO follows VALUES (?1, ?2)',
      variables: [i0.Variable<int>(var1), i0.Variable<int>(var2)],
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
