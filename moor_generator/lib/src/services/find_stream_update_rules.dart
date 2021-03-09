//@dart=2.9
import 'package:moor/moor.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:sqlparser/sqlparser.dart';

class FindStreamUpdateRules {
  final Database db;

  FindStreamUpdateRules(this.db);

  StreamQueryUpdateRules identifyRules() {
    final rules = <UpdateRule>[];

    for (final entity in db.entities) {
      if (entity is MoorTrigger) {
        _writeRulesForTrigger(entity, rules);
      } else if (entity is MoorTable) {
        _writeRulesForTable(entity, rules);
      }
    }

    return StreamQueryUpdateRules(rules);
  }

  void _writeRulesForTable(MoorTable table, List<UpdateRule> rules) {
    final declaration = table.declaration;

    // We only know about foreign key clauses from tables in moor files
    if (declaration is! MoorTableDeclaration) return;

    final moorDeclaration = declaration as MoorTableDeclaration;
    if (moorDeclaration.node is! CreateTableStatement) return;

    final stmt = moorDeclaration.node as CreateTableStatement;
    final tableName = table.sqlName;

    for (final fkClause in stmt.allDescendants.whereType<ForeignKeyClause>()) {
      final referencedMoorTable = table.references.firstWhere(
        (tbl) => tbl.sqlName == fkClause.foreignTable.tableName,
        orElse: () => null,
      );

      void writeRule(UpdateKind listen, ReferenceAction action) {
        TableUpdate effect;
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
                referencedMoorTable.sqlName,
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

    if (declaration is! MoorTriggerDeclaration) return;

    final target = (declaration as MoorTriggerDeclaration).node.target;
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
}
