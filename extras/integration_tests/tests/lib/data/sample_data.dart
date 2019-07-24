import 'package:moor/moor.dart';
import 'package:tests/database/database.dart';

class People {
  static const int dashId = 1, dukeId = 2, gopherId = 3;

  static UsersCompanion dash = UsersCompanion(
    name: const Value('Dash'),
    birthDate: Value(DateTime(2011, 10, 11)),
  );

  static UsersCompanion duke = UsersCompanion(
    name: const Value('Duke'),
    birthDate: Value(DateTime(1996, 1, 23)),
  );

  static UsersCompanion gopher = UsersCompanion(
    name: const Value('Go Gopher'),
    birthDate: Value(DateTime(2012, 3, 28)),
  );

  static UsersCompanion florian = UsersCompanion(
    name: const Value(
        'Florian, the fluffy Ferret from Florida familiar with Flutter'),
    birthDate: Value(DateTime(2015, 4, 29)),
  );
}
