import '../schemas/schema_v1.dart' as v1;
import '../schemas/schema_v2.dart' as v2;

/// Run `dart run drift_dev make-migrations --help` for more information

final usersV1 = <v1.UsersData>[
  v1.UsersData(id: 0),
];
final usersV2 = <v2.UsersData>[
  v2.UsersData(id: 0, name: 'no name'),
];
