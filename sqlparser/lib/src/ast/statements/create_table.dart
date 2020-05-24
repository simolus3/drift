part of '../ast.dart';

abstract class TableInducingStatement extends Statement
    implements CreatingStatement {
  final bool ifNotExists;
  final String tableName;

  /// Specific to moor. Overrides the name of the data class used to hold a
  /// result for of this table. Will be null when the moor extensions are not
  /// enabled or if no name has been set.
  final String overriddenDataClassName;

  Token tableNameToken;

  TableInducingStatement._(this.ifNotExists, this.tableName,
      [this.overriddenDataClassName]);

  @override
  String get createdName => tableName;
}

/// A "CREATE TABLE" statement, see https://www.sqlite.org/lang_createtable.html
/// for the individual components.
class CreateTableStatement extends TableInducingStatement {
  final List<ColumnDefinition> columns;
  final List<TableConstraint> tableConstraints;
  final bool withoutRowId;

  Token openingBracket;
  Token closingBracket;

  CreateTableStatement(
      {bool ifNotExists = false,
      @required String tableName,
      this.columns = const [],
      this.tableConstraints = const [],
      this.withoutRowId = false,
      String overriddenDataClassName})
      : super._(ifNotExists, tableName, overriddenDataClassName);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCreateTableStatement(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    transformer.transformChildren(columns, this, arg);
    transformer.transformChildren(tableConstraints, this, arg);
  }

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

class CreateVirtualTableStatement extends TableInducingStatement {
  /// The module that will be invoked when creating the virtual table.
  final String moduleName;
  Token moduleNameToken;

  /// Arguments passed to the module. Since the specific module is responsible
  /// for parsing them, the general parser only exposes them as strings with a
  /// source location.
  final List<SourceSpanWithContext> arguments;
  List<String> _argumentText;

  List<String> get argumentContent {
    return _argumentText ??= arguments.map((a) => a.text).toList();
  }

  CreateVirtualTableStatement({
    bool ifNotExists = false,
    @required String tableName,
    @required this.moduleName,
    this.arguments = const [],
    String overriddenDataClassName,
  }) : super._(ifNotExists, tableName, overriddenDataClassName);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCreateVirtualTableStatement(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  bool contentEquals(CreateVirtualTableStatement other) {
    return other.ifNotExists == ifNotExists &&
        other.tableName == tableName &&
        other.moduleName == moduleName &&
        const ListEquality().equals(other.argumentContent, argumentContent);
  }
}
