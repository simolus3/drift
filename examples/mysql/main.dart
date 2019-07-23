import 'lib/database.dart';

void main() async {
  final database = Database();
  await database.insertUser('MySql test');
}
