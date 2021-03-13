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

class InsertStatement extends CrudStatement implements HasPrimarySource {
  final InsertMode mode;
  @override
  TableReference table;
  final List<Reference> targetColumns;
  InsertSource source;
  UpsertClause? upsert;

  List<Column?>? get resolvedTargetColumns {
    if (targetColumns.isNotEmpty) {
      return targetColumns.map((c) => c.resolvedColumn).toList();
    } else {
      // no columns declared - assume all columns from the table
      return table.resultSet?.resolvedColumns;
    }
  }

  InsertStatement(
      {WithClause? withClause,
      this.mode = InsertMode.insert,
      required this.table,
      required this.targetColumns,
      required this.source,
      this.upsert})
      : super(withClause);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitInsertStatement(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    withClause = transformer.transformNullableChild(withClause, this, arg);
    table = transformer.transformChild(table, this, arg);
    transformer.transformChildren(targetColumns, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [
        if (withClause != null) withClause!,
        table,
        ...targetColumns,
        source,
        if (upsert != null) upsert!,
      ];
}

abstract class InsertSource extends AstNode {
  T? when<T>(
      {T Function(ValuesSource)? isValues,
      T Function(SelectInsertSource)? isSelect,
      T Function(DefaultValues)? isDefaults}) {
    if (this is ValuesSource) {
      return isValues?.call(this as ValuesSource);
    } else if (this is SelectInsertSource) {
      return isSelect?.call(this as SelectInsertSource);
    } else if (this is DefaultValues) {
      return isDefaults?.call(this as DefaultValues);
    } else {
      throw StateError('Did not expect $runtimeType as InsertSource');
    }
  }
}

/// Uses a list of values for an insert statement (`VALUES (a, b, c)`).
class ValuesSource extends InsertSource {
  final List<Tuple> values;

  ValuesSource(this.values);

  @override
  Iterable<AstNode> get childNodes => values;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitValuesSource(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    transformer.transformChildren(values, this, arg);
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
