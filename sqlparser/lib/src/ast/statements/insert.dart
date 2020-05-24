part of '../ast.dart';

enum InsertMode {
  insert,
  replace,
  insertOrReplace,
  insertOrRollback,
  insertOrAbort,
  insertOrFail,
  insertOrIgnore
}

class InsertStatement extends CrudStatement {
  final InsertMode mode;
  TableReference table;
  final List<Reference> targetColumns;
  InsertSource source;
  UpsertClause upsert;

  List<Column> get resolvedTargetColumns {
    if (targetColumns.isNotEmpty) {
      return targetColumns.map((c) => c.resolvedColumn).toList();
    } else {
      // no columns declared - assume all columns from the table
      return table.resultSet?.resolvedColumns;
    }
  }

  InsertStatement(
      {WithClause withClause,
      this.mode = InsertMode.insert,
      @required this.table,
      @required this.targetColumns,
      @required this.source,
      this.upsert})
      : super._(withClause);

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
  Iterable<AstNode> get childNodes sync* {
    if (withClause != null) yield withClause;
    yield table;
    yield* targetColumns;
    yield* source.childNodes;
    if (upsert != null) yield upsert;
  }

  @override
  bool contentEquals(InsertStatement other) {
    return other.mode == mode && other.source.runtimeType == source.runtimeType;
  }
}

// todo: Should be an AstNode
abstract class InsertSource {
  Iterable<AstNode> get childNodes;

  const InsertSource();

  T when<T>(
      {T Function(ValuesSource) isValues,
      T Function(SelectInsertSource) isSelect,
      T Function(DefaultValues) isDefaults}) {
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
}

/// Inserts the rows returned by [stmt].
class SelectInsertSource extends InsertSource {
  final BaseSelectStatement stmt;

  SelectInsertSource(this.stmt);

  @override
  Iterable<AstNode> get childNodes => [stmt];
}

/// Use `DEFAULT VALUES` for an insert statement.
class DefaultValues extends InsertSource {
  const DefaultValues();

  @override
  Iterable<AstNode> get childNodes => const [];
}
