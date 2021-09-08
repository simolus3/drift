import '../../reader/tokenizer/token.dart';
import '../node.dart';
import '../visitor.dart';
import 'statement.dart';

enum TransactionMode { none, deferred, immediate, exclusive }

class BeginTransactionStatement extends Statement {
  Token? begin, modeToken, transaction;

  final TransactionMode mode;

  BeginTransactionStatement([this.mode = TransactionMode.none]);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitBeginTransaction(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => const Iterable.empty();

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

class CommitStatement extends Statement {
  Token? commitOrEnd, transaction;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitCommitStatement(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => const Iterable.empty();

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}
