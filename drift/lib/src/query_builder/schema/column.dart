import '../compiler.dart';
import '../dialect.dart';
import '../expressions/expression.dart';
import '../types.dart';
import 'result_set.dart';

/// A column that appears as part of some schema object.
base class SchemaColumn<T extends Object> extends Expression<T> {
  /// The raw name of the column in SQL (without any escaping quotes).
  final String name;

  /// The SQL type of this column.
  final SqlType<T> type;

  /// Whether the column is nullable in SQL, meaning that it doesn't have a
  /// `NOT NULL` constraint applied to it.
  final bool isNullable;

  late ResultSet owningResultSet;

  SchemaColumn({
    required this.name,
    required this.type,
    this.isNullable = true,
  });

  @override
  SqlType<T> resolveType(DriftDialect dialect) {
    return type;
  }

  @override
  String toString() {
    return '${owningResultSet.alias}.$name';
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addColumnReference(this);
  }
}
