import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:sqlparser/sqlparser.dart';

class FindStreamUpdateRules {
  final Database db;

  FindStreamUpdateRules(this.db);

  StreamQueryUpdateRules identifyRules() {
    final rules = <UpdateRule>[];

    for (final entity in db.entities) {
      if (entity is MoorTrigger) {
        _writeRulesForTrigger(entity, rules);
      } else if (entity is DriftTable) {
        _writeRulesForTable(entity, rules);
      }
    }

    return StreamQueryUpdateRules(rules);
  }

  void _writeRulesForTable(DriftTable table, List<UpdateRule> rules) {
    final declaration = table.declaration;

    // We only know about foreign key clauses from tables in moor files
    if (declaration is! DriftTableDeclaration) return;

    if (declaration.node is! CreateTableStatement) return;

    final stmt = declaration.node as CreateTableStatement;
    final tableName = table.sqlName;

    for (final fkClause in stmt.allDescendants.whereType<ForeignKeyClause>()) {
      final referencedMoorTable = table.references.firstWhereOrNull(
        (tbl) => tbl.sqlName == fkClause.foreignTable.tableName,
      );

      void writeRule(UpdateKind listen, ReferenceAction? action) {
        TableUpdate? effect;
        switch (action) {
          case ReferenceAction.setNull:
          case ReferenceAction.setDefault:
            effect = TableUpdate(tableName, kind: UpdateKind.update);
            break;
          case ReferenceAction.cascade:
            effect = TableUpdate(tableName, kind: listen);
            break;
          default:
            break;
        }

        if (effect != null) {
          rules.add(
            WritePropagation(
              on: TableUpdateQuery.onTableName(
                referencedMoorTable!.sqlName,
                limitUpdateKind: listen,
              ),
              result: [effect],
            ),
          );
        }
      }

      if (referencedMoorTable == null) continue;
      writeRule(UpdateKind.delete, fkClause.onDelete);
      writeRule(UpdateKind.update, fkClause.onUpdate);
    }
  }

  void _writeRulesForTrigger(MoorTrigger trigger, List<UpdateRule> rules) {
    final declaration = trigger.declaration;

    if (declaration is! DriftTriggerDeclaration) return;

    final target = declaration.node.target;
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
          trigger.on!.sqlName,
          limitUpdateKind: targetKind,
        ),
        result: [
          for (final update in trigger.bodyUpdates)
            TableUpdate(update.table.sqlName, kind: update.kind)
        ],
      ),
    );
  }
}
