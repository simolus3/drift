import 'package:drift/native.dart';
import 'package:modular/database.dart';
import 'package:modular/src/users.drift.dart';

void main() async {
  final database = Database(NativeDatabase.memory(logStatements: true));

  database.userQueriesDrift.findUsers().watch().listen(print);

  await database.myAccessor
      .addUser(user: UsersCompanion.insert(name: 'first_user'));
  await database.close();
}
