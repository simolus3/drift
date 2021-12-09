import '../../reader/tokenizer/token.dart';
import '../ast.dart'; // todo: Remove this import

/// A "CREATE VIEW" statement, see https://sqlite.org/lang_createview.html
class CreateViewStatement extends Statement implements CreatingStatement {
  final bool ifNotExists;

  final String viewName;
  IdentifierToken? viewNameToken;

  BaseSelectStatement query;

  final List<String>? columns;

  /// Moor-specific information about the desired name of a Dart class for this
  /// table.
  ///
  /// This will always be `null` when moor extensions are not enabled.
  MoorTableName? moorTableName;

  CreateViewStatement({
    this.ifNotExists = false,
    required this.viewName,
    this.columns,
    required this.query,
    this.moorTableName,
  });

  @override
  String get createdName => viewName;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCreateViewStatement(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    query = transformer.transformChild(query, this, arg);
    moorTableName =
        transformer.transformNullableChild(moorTableName, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes =>
      [query, if (moorTableName != null) moorTableName!];
}
