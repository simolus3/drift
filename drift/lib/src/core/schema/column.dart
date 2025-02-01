import '../compiler.dart';
import '../dialect.dart';
import '../expressions/expression.dart';
import '../types.dart';
import 'result_set.dart';

/// A column that appears as part of some schema object.
abstract base class SchemaColumn<T extends Object> extends Expression<T> {
  /// The raw name of the column in SQL (without any escaping quotes).
  final String name;

  final SqlType<T> Function(DriftDialect) _resolveType;

  late ResultSet owningResultSet;

  SchemaColumn({
    required this.name,
    required SqlType<T> Function(DriftDialect dialect) type,
  }) : _resolveType = type;

  @override
  SqlType<T> resolveType(DriftDialect dialect) {
    return _resolveType(dialect);
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
