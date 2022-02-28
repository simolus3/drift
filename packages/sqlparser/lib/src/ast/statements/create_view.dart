import '../../reader/tokenizer/token.dart';
import '../ast.dart'; // todo: Remove this import

/// A "CREATE VIEW" statement, see https://sqlite.org/lang_createview.html
class CreateViewStatement extends Statement implements CreatingStatement {
  final bool ifNotExists;

  final String viewName;
  IdentifierToken? viewNameToken;

  BaseSelectStatement query;

  final List<String>? columns;

  /// Drift-specific information about the desired name of a Dart class for this
  /// table.
  ///
  /// This will always be `null` when drift extensions are not enabled.
  DriftTableName? driftTableName;

  CreateViewStatement({
    this.ifNotExists = false,
    required this.viewName,
    this.columns,
    required this.query,
    this.driftTableName,
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
    driftTableName =
        transformer.transformNullableChild(driftTableName, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes =>
      [query, if (driftTableName != null) driftTableName!];
}
