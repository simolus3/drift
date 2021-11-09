import 'package:sqlparser/sqlparser.dart';

import '../../analysis/analysis.dart';
import '../ast.dart'; // todo: Remove this import
import '../clauses/upsert.dart';
import '../node.dart';
import '../visitor.dart';
import 'statement.dart';

enum InsertMode {
  insert,
  replace,
  insertOrReplace,
  insertOrRollback,
  insertOrAbort,
  insertOrFail,
  insertOrIgnore
}

class InsertStatement extends CrudStatement
    implements HasPrimarySource, StatementReturningColumns {
  final InsertMode mode;
  @override
  TableReference table;
  List<Reference> targetColumns;
  InsertSource source;
  UpsertClause? upsert;

  @override
  Returning? returning;
  @override
  ResultSet? returnedResultSet;

  List<Column?>? get resolvedTargetColumns {
    if (targetColumns.isNotEmpty) {
      return targetColumns.map((c) => c.resolvedColumn).toList();
    } else {
      // no columns declared - assume all columns from the table that are not
      // generated.
      return table.resultSet?.resolvedColumns
          ?.where((c) => c is! TableColumn || !c.isGenerated)
          .toList();
    }
  }

  InsertStatement({
    WithClause? withClause,
    this.mode = InsertMode.insert,
    required this.table,
    required this.targetColumns,
    required this.source,
    this.upsert,
    this.returning,
  }) : super(withClause);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitInsertStatement(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    withClause = transformer.transformNullableChild(withClause, this, arg);
    table = transformer.transformChild(table, this, arg);
    targetColumns = transformer.transformChildren(targetColumns, this, arg);
    returning = transformer.transformNullableChild(returning, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [
        if (withClause != null) withClause!,
        table,
        ...targetColumns,
        source,
        if (upsert != null) upsert!,
        if (returning != null) returning!,
      ];
}

/// Marker interface for AST nodes that can be used as data sources in insert
/// statements.
abstract class InsertSource extends AstNode {}

/// Uses a list of values for an insert statement (`VALUES (a, b, c)`).
class ValuesSource extends InsertSource {
  List<Tuple> values;

  ValuesSource(this.values);

  @override
  Iterable<AstNode> get childNodes => values;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitValuesSource(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    values = transformer.transformChildren(values, this, arg);
  }
}

/// Inserts the rows returned by [stmt].
class SelectInsertSource extends InsertSource {
  BaseSelectStatement stmt;

  SelectInsertSource(this.stmt);

  @override
  Iterable<AstNode> get childNodes => [stmt];

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitSelectInsertSource(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    stmt = transformer.transformChild(stmt, this, arg);
  }
}

/// Use `DEFAULT VALUES` for an insert statement.
class DefaultValues extends InsertSource {
  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDefaultValues(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}
