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

class InsertStatement extends Statement with CrudStatement {
  final InsertMode mode;
  final TableReference table;
  final List<Reference> targetColumns;
  final InsertSource source;

  List<Column> get resolvedTargetColumns {
    if (targetColumns.isNotEmpty) {
      return targetColumns.map((c) => c.resolvedColumn).toList();
    } else {
      // no columns declared - assume all columns from the table
      return table.resultSet?.resolvedColumns;
    }
  }

  // todo parse upsert clauses

  InsertStatement(
      {this.mode = InsertMode.insert,
      @required this.table,
      @required this.targetColumns,
      @required this.source});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitInsertStatement(this);

  @override
  Iterable<AstNode> get childNodes sync* {
    yield table;
    yield* targetColumns;
    yield* source.childNodes;
  }

  @override
  bool contentEquals(InsertStatement other) {
    return other.mode == mode && other.source.runtimeType == source.runtimeType;
  }
}

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
  final SelectStatement stmt;

  SelectInsertSource(this.stmt);

  @override
  Iterable<AstNode> get childNodes => [stmt];
}

/// Use `DEFAULT VALUES` for an insert statement.
class DefaultValues extends InsertSource {
  const DefaultValues();

  @override
  final Iterable<AstNode> childNodes = const [];
}
