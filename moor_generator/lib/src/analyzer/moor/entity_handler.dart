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

  void handle() {
    for (final table in file.declaredTables) {
      table.references.clear();
    }

    file.parseResult.rootNode
        ?.acceptWithoutArg(_ReferenceResolvingVisitor(this));
  }
}

class _ReferenceResolvingVisitor extends RecursiveVisitor<void, void> {
  final EntityHandler handler;

  _ReferenceResolvingVisitor(this.handler);

  @override
  void visitForeignKeyClause(ForeignKeyClause clause, void arg) {
    final stmt = clause.parents.whereType<CreateTableStatement>().first;
    final referencedTable = handler.availableTables.singleWhere(
        (t) => t.sqlName == clause.foreignTable.tableName,
        orElse: () => null);

    if (referencedTable == null) {
      handler.step.reportError(ErrorInMoorFile(
          severity: Severity.error,
          span: clause.span,
          message:
              'Referenced table ${clause.foreignTable.tableName} could not be'
              'found.'));
    } else {
      final createdTable = handler.file.tableDeclarations[stmt];
      createdTable?.references?.add(referencedTable);
    }

    super.visitForeignKeyClause(clause, arg);
  }
}
