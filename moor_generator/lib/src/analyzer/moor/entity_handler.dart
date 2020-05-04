import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/analyzer/sql_queries/lints/linter.dart';
import 'package:moor_generator/src/analyzer/sql_queries/query_analyzer.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/find_referenced_tables.dart';

/// Handles `REFERENCES` clauses in tables by resolving their columns and
/// reporting errors if they don't exist. Further, sets the
/// [MoorTable.references] field for tables declared in moor.
class EntityHandler extends BaseAnalyzer {
  final ParsedMoorFile file;

  AnalyzeMoorStep get moorStep => step as AnalyzeMoorStep;

  EntityHandler(
      AnalyzeMoorStep step, this.file, List<MoorTable> availableTables)
      : super(availableTables, step) {
    _referenceResolver = _ReferenceResolvingVisitor(this);
  }

  final Map<CreateTriggerStatement, MoorTrigger> _triggers = {};
  final Map<TableInducingStatement, MoorTable> _tables = {};
  final Map<CreateIndexStatement, MoorIndex> _indexes = {};

  _ReferenceResolvingVisitor _referenceResolver;

  void handle() {
    for (final entity in file.declaredEntities) {
      if (entity is MoorTable) {
        entity.references.clear();
        _handleMoorDeclaration<MoorTableDeclaration>(entity, _tables);
      } else if (entity is MoorTrigger) {
        entity.clearResolvedReferences();

        final node =
            _handleMoorDeclaration(entity, _triggers) as CreateTriggerStatement;

        // triggers can have complex statements, so run the linter on them
        _lint(node, entity.displayName);

        // find additional tables that might be referenced in the body

        entity.bodyReferences.addAll(_findTables(node.action));
        entity.bodyUpdates.addAll(_findUpdatedTables(node.action));
      } else if (entity is MoorIndex) {
        entity.table = null;

        _handleMoorDeclaration<MoorIndexDeclaration>(entity, _indexes);
      } else if (entity is SpecialQuery) {
        final node = (entity.declaration as MoorSpecialQueryDeclaration).node;

        _lint(node, 'special @create table');
        entity.references.addAll(_findTables(node.statement));
      }
    }
  }

  void _lint(AstNode node, String displayName) {
    final context = engine.analyzeNode(node, file.parseResult.sql);
    context.errors.forEach(report);

    final linter = Linter(context, mapper);
    linter.reportLints();
    reportLints(linter.lints, name: displayName);
  }

  Iterable<MoorTable> _findTables(AstNode node) {
    final tablesFinder = ReferencedTablesVisitor();
    node.acceptWithoutArg(tablesFinder);
    return tablesFinder.foundTables.map(mapper.tableToMoor);
  }

  Iterable<WrittenMoorTable> _findUpdatedTables(AstNode node) {
    final finder = UpdatedTablesVisitor();
    node.acceptWithoutArg(finder);
    return finder.writtenTables.map(mapper.writtenToMoor);
  }

  AstNode _handleMoorDeclaration<T extends MoorDeclaration>(
    HasDeclaration e,
    Map<AstNode, HasDeclaration> map,
  ) {
    final declaration = e.declaration as T;
    map[declaration.node] = e;

    declaration.node.acceptWithoutArg(_referenceResolver);
    return declaration.node;
  }

  MoorTable _inducedTable(TableInducingStatement stmt) {
    return _tables[stmt];
  }

  MoorTrigger _inducedTrigger(CreateTriggerStatement stmt) {
    return _triggers[stmt];
  }

  MoorIndex _inducedIndex(CreateIndexStatement stmt) {
    return _indexes[stmt];
  }
}

class _ReferenceResolvingVisitor extends RecursiveVisitor<void, void> {
  final EntityHandler handler;

  _ReferenceResolvingVisitor(this.handler);

  MoorTable _resolveTable(TableReference reference) {
    return handler.tables.singleWhere((t) => t.sqlName == reference.tableName,
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
  void visitCreateIndexStatement(CreateIndexStatement e, void arg) {
    final table = _resolveTable(e.on);
    if (table == null) {
      handler.step.reportError(ErrorInMoorFile(
        severity: Severity.error,
        span: e.on.span,
        message: 'Target table ${e.on.tableName} could not be found.',
      ));
    } else {
      final moorIndex = handler._inducedIndex(e);
      moorIndex?.table = table;
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
