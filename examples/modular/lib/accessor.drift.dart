// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:modular/database.dart' as i1;
import 'package:modular/src/users.drift.dart' as i2;

mixin $MyAccessorMixin on i0.DatabaseAccessor<i1.Database> {
  i2.Users get users => attachedDatabase.users;
  i2.Follows get follows => attachedDatabase.follows;
  Future<int> addUser({required i0.Insertable<i2.User> user}) {
    var $arrayStartIndex = 1;
    final generateduser =
        $writeInsertable(this.users, user, startIndex: $arrayStartIndex);
    $arrayStartIndex += generateduser.amountOfVariables;
    return customInsert(
      'INSERT INTO users ${generateduser.sql}',
      variables: [...generateduser.introducedVariables],
      updates: {users},
    );
  }
}
