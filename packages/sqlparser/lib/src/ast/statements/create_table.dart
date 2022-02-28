import 'package:source_span/source_span.dart';

import '../../reader/tokenizer/token.dart';
import '../ast.dart'; // todo: Remove this import

abstract class TableInducingStatement extends Statement
    implements CreatingStatement {
  final bool ifNotExists;
  final String tableName;

  /// Drift-specific information about the desired name of a Dart class for this
  /// table.
  ///
  /// This will always be `null` when drift extensions are not enabled.
  DriftTableName? driftTableName;
  Token? tableNameToken;

  TableInducingStatement._(this.ifNotExists, this.tableName,
      [this.driftTableName]);

  @override
  String get createdName => tableName;
}

/// A "CREATE TABLE" statement, see https://www.sqlite.org/lang_createtable.html
/// for the individual components.
class CreateTableStatement extends TableInducingStatement {
  List<ColumnDefinition> columns;
  List<TableConstraint> tableConstraints;

  /// Whether this table has been defined with an `WITHOUT ROWID` clause.
  final bool withoutRowId;

  /// Whether this table has been defined as `STRICT`.
  ///
  /// Strict tables are limited to a few column type names. Columns in strict
  /// tables may not store other types.
  final bool isStrict;

  Token? openingBracket;
  Token? closingBracket;
  Token? strict;

  CreateTableStatement({
    bool ifNotExists = false,
    required String tableName,
    this.columns = const [],
    this.tableConstraints = const [],
    this.withoutRowId = false,
    this.isStrict = false,
    DriftTableName? driftTableName,
  }) : super._(ifNotExists, tableName, driftTableName);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCreateTableStatement(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    columns = transformer.transformChildren(columns, this, arg);
    tableConstraints =
        transformer.transformChildren(tableConstraints, this, arg);
    driftTableName =
        transformer.transformNullableChild(driftTableName, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [
        ...columns,
        ...tableConstraints,
        if (driftTableName != null) driftTableName!,
      ];
}

class CreateVirtualTableStatement extends TableInducingStatement {
  /// The module that will be invoked when creating the virtual table.
  final String moduleName;
  Token? moduleNameToken;

  /// Arguments passed to the module. Since the specific module is responsible
  /// for parsing them, the general parser only exposes them as strings with a
  /// source location.
  final List<SourceSpanWithContext> arguments;
  List<String>? _argumentText;

  List<String> get argumentContent {
    return _argumentText ??= arguments.map((a) => a.text).toList();
  }

  CreateVirtualTableStatement({
    bool ifNotExists = false,
    required String tableName,
    required this.moduleName,
    this.arguments = const [],
    DriftTableName? driftTableName,
  }) : super._(ifNotExists, tableName, driftTableName);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCreateVirtualTableStatement(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    driftTableName =
        transformer.transformNullableChild(driftTableName, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes =>
      [if (driftTableName != null) driftTableName!];
}
