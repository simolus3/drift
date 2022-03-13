import '../../reader/tokenizer/token.dart';
import '../node.dart';
import '../statements/statement.dart';
import '../visitor.dart';
import 'drift_file.dart';

/// An `import "file.dart";` statement that can appear inside a drift file.
class ImportStatement extends Statement implements PartOfDriftFile {
  Token? importToken;
  StringLiteralToken? importString;
  final String importedFile;

  ImportStatement(this.importedFile);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDriftSpecificNode(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}

  @override
  final Iterable<AstNode> childNodes = const [];
}
