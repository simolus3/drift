import 'package:drift/drift.dart';
import 'package:tests/database/database.dart';

const int dashId = 1, dukeId = 2, gopherId = 3;

UsersCompanion dash = UsersCompanion(
  name: const Value('Dash'),
  birthDate: Value(DateTime(2011, 10, 11)),
);

UsersCompanion duke = UsersCompanion(
  name: const Value('Duke'),
  birthDate: Value(DateTime(1996, 1, 23)),
);

UsersCompanion gopher = UsersCompanion(
  name: const Value('Go Gopher'),
  birthDate: Value(DateTime(2012, 3, 28)),
);

UsersCompanion florian = UsersCompanion(
  name: const Value(
      'Florian, the fluffy Ferret from Florida familiar with Flutter'),
  birthDate: Value(DateTime(2015, 4, 29)),
);

UsersCompanion marcell = UsersCompanion(
  id: const Value(1),
  name: const Value('Marcell'),
  birthDate: Value(DateTime(1989, 12, 31)),
);
