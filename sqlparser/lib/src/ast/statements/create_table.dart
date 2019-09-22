part of '../ast.dart';

/// A "CREATE TABLE" statement, see https://www.sqlite.org/lang_createtable.html
/// for the individual components.
class CreateTableStatement extends Statement
    with SchemaStatement
    implements PartOfMoorFile {
  final bool ifNotExists;
  final String tableName;
  final List<ColumnDefinition> columns;
  final List<TableConstraint> tableConstraints;
  final bool withoutRowId;

  /// Specific to moor. Overrides the name of the data class used to hold a
  /// result for of this table. Will be null when the moor extensions are not
  /// enabled or if no name has been set.
  final String overriddenDataClassName;

  Token openingBracket;
  Token closingBracket;

  CreateTableStatement(
      {this.ifNotExists = false,
      @required this.tableName,
      this.columns = const [],
      this.tableConstraints = const [],
      this.withoutRowId = false,
      this.overriddenDataClassName});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitCreateTableStatement(this);

  @override
  Iterable<AstNode> get childNodes => [...columns, ...tableConstraints];

  @override
  bool contentEquals(CreateTableStatement other) {
    return other.ifNotExists == ifNotExists &&
        other.tableName == tableName &&
        other.withoutRowId == withoutRowId &&
        other.overriddenDataClassName == overriddenDataClassName;
  }
}
