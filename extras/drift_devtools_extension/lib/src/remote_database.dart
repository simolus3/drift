import 'dart:convert';

import 'package:devtools_app_shared/service.dart';
// ignore: invalid_use_of_internal_member, implementation_imports
import 'package:drift/src/runtime/devtools/shared.dart';
import 'package:vm_service/vm_service.dart';

/// Utilities to access a drift database via service extensions.
class RemoteDatabase {
  final DatabaseDescription description;

  RemoteDatabase({required this.description});

  static Future<RemoteDatabase> resolve(
    Instance database,
    EvalOnDartLibrary eval,
    Disposable isAlive,
  ) async {
    final stringVal = await eval.evalInstance(
      'describe(db)',
      isAlive: isAlive,
      scope: {'db': database.id!},
    );
    final value = await eval.retrieveFullValueAsString(stringVal);

    final description = DatabaseDescription.fromJson(json.decode(value!));

    return RemoteDatabase(description: description);
  }
}
