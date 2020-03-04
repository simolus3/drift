import 'package:moor/moor.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:sqlparser/sqlparser.dart';

class FindStreamUpdateRules {
  final Database db;

  FindStreamUpdateRules(this.db);

  StreamQueryUpdateRules identifyRules() {
    final rules = <UpdateRule>[];

    for (final trigger in db.entities.whereType<MoorTrigger>()) {
      final target = trigger.declaration.node.target;
      UpdateKind targetKind;
      if (target is DeleteTarget) {
        targetKind = UpdateKind.delete;
      } else if (target is InsertTarget) {
        targetKind = UpdateKind.insert;
      } else {
        targetKind = UpdateKind.update;
      }

      rules.add(
        WritePropagation(
          on: TableUpdateQuery.onTableName(
            trigger.on.sqlName,
            limitUpdateKind: targetKind,
          ),
          result: [
            for (final update in trigger.bodyUpdates)
              TableUpdate(update.table.sqlName, kind: update.kind)
          ],
        ),
      );
    }

    return StreamQueryUpdateRules(rules);
  }
}
