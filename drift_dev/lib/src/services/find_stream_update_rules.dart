import 'package:drift/drift.dart' hide DriftDatabase;
import 'package:sqlparser/sqlparser.dart';

import '../analysis/results/results.dart';

class FindStreamUpdateRules {
  final DriftDatabase db;

  FindStreamUpdateRules(this.db);

  StreamQueryUpdateRules identifyRules() {
    final rules = <UpdateRule>[];

    for (final entity in db.references) {
      if (entity is DriftTrigger) {
        _writeRulesForTrigger(entity, rules);
      } else if (entity is DriftTable) {
        _writeRulesForTable(entity, rules);
      }
    }

    return StreamQueryUpdateRules(rules);
  }

  void _writeRulesForTable(DriftTable table, List<UpdateRule> rules) {
    void writeRule(
        DriftElement referenced, UpdateKind listen, ReferenceAction? action) {
      TableUpdate? effect;
      switch (action) {
        case ReferenceAction.setNull:
        case ReferenceAction.setDefault:
          effect = TableUpdate(table.id.name, kind: UpdateKind.update);
          break;
        case ReferenceAction.cascade:
          effect = TableUpdate(table.id.name, kind: listen);
          break;
        default:
          break;
      }

      if (effect != null) {
        rules.add(
          WritePropagation(
            on: TableUpdateQuery.onTableName(
              referenced.id.name,
              limitUpdateKind: listen,
            ),
            result: [effect],
          ),
        );
      }
    }

    // Write update rules from fk constraints applied to columns
    for (final column in table.columns) {
      for (final constraint in column.constraints) {
        if (constraint is ForeignKeyReference) {
          writeRule(constraint.otherColumn.owner, UpdateKind.delete,
              constraint.onDelete);
          writeRule(constraint.otherColumn.owner, UpdateKind.update,
              constraint.onUpdate);
        }
      }
    }

    // And to those declared on the whole table
    for (final constraint in table.tableConstraints) {
      if (constraint is ForeignKeyTable) {
        writeRule(
            constraint.otherTable, UpdateKind.delete, constraint.onDelete);
        writeRule(
            constraint.otherTable, UpdateKind.update, constraint.onUpdate);
      }
    }
  }

  void _writeRulesForTrigger(DriftTrigger trigger, List<UpdateRule> rules) {
    final on = trigger.on;
    if (on != null) {
      rules.add(
        WritePropagation(
          on: TableUpdateQuery.onTableName(
            on.id.name,
            limitUpdateKind: trigger.onWrite,
          ),
          result: [
            for (final update in trigger.writes)
              TableUpdate(update.table.id.name, kind: update.kind)
          ],
        ),
      );
    }
  }
}
