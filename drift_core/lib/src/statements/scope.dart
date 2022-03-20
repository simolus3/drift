import '../builder/context.dart';

import '../schema.dart';
import 'clauses.dart';

abstract class StatementScope extends ContextScope {
  final bool readsFromMultipleTables;

  StatementScope(this.readsFromMultipleTables);

  AddedTable? findTable(EntityWithResult entity, String? name);
}
