part of '../ast.dart';

/// A nested star result column, denoted by `**` in user queries.
///
/// Nested star result columns behave similar to a regular [StarResultColumn]
/// when the query is actually run. However, they will affect generated code
/// when using moor.
class NestedStarResultColumn extends ResultColumn {
  final String tableName;
  ResultSet resultSet;

  NestedStarResultColumn(this.tableName);

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  bool contentEquals(NestedStarResultColumn other) {
    return other.tableName == tableName;
  }
}
