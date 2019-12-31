import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:sqlparser/sqlparser.dart';

/// Handles `REFERENCES` clauses in tables by resolving their columns and
/// reporting errors if they don't exist. Further, sets the
/// [MoorTable.references] field for tables declared in moor.
class EntityHandler {
  final AnalyzeMoorStep step;
  final ParsedMoorFile file;
  final List<MoorTable> availableTables;

  EntityHandler(this.step, this.file, this.availableTables);

  final Map<CreateTriggerStatement, MoorTrigger> _triggers = {};
  final Map<TableInducingStatement, MoorTable> _tables = {};

  void handle() {
    final referenceResolver = _ReferenceResolvingVisitor(this);
    for (final table in file.declaredTables) {
      table.references.clear();

      final declaration = table.declaration as MoorTableDeclaration;
      _tables[declaration.node] = table;
      declaration.node.acceptWithoutArg(referenceResolver);
    }

    for (final trigger in file.declaredEntities.whereType<MoorTrigger>()) {
      trigger.on = null;

      final declaration = trigger.declaration as MoorTriggerDeclaration;
      _triggers[declaration.node] = trigger;
      declaration.node.acceptWithoutArg(referenceResolver);
    }
  }

  MoorTable _inducedTable(TableInducingStatement stmt) {
    return _tables[stmt];
  }

  MoorTrigger _inducedTrigger(CreateTriggerStatement stmt) {
    return _triggers[stmt];
  }
}

class _ReferenceResolvingVisitor extends RecursiveVisitor<void, void> {
  final EntityHandler handler;

  _ReferenceResolvingVisitor(this.handler);

  MoorTable _resolveTable(TableReference reference) {
    return handler.availableTables.singleWhere(
        (t) => t.sqlName == reference.tableName,
        orElse: () => null);
  }

  @override
  void visitCreateTriggerStatement(CreateTriggerStatement e, void arg) {
    final table = _resolveTable(e.onTable);
    if (table == null) {
      handler.step.reportError(ErrorInMoorFile(
        severity: Severity.error,
        span: e.onTable.span,
        message: 'Target table ${e.onTable.tableName} could not be found.',
      ));
    } else {
      final moorTrigger = handler._inducedTrigger(e);
      moorTrigger?.on = table;
    }
  }

  @override
  void visitForeignKeyClause(ForeignKeyClause clause, void arg) {
    final stmt = clause.parents.whereType<CreateTableStatement>().first;
    final referencedTable = _resolveTable(clause.foreignTable);

    if (referencedTable == null) {
      handler.step.reportError(ErrorInMoorFile(
        severity: Severity.error,
        span: clause.span,
        message:
            'Referenced table ${clause.foreignTable.tableName} could not be'
            'found.',
      ));
    } else {
      final createdTable = handler._inducedTable(stmt);
      createdTable?.references?.add(referencedTable);
    }

    super.visitForeignKeyClause(clause, arg);
  }
}
