import 'package:drift/native.dart';
import 'package:modular/database.dart';

void main() async {
  final database = Database(NativeDatabase.memory(logStatements: true));

  database.usersDrift.findUsers().watch().listen(print);
}
