import '../compiler.dart';
import 'statement.dart';

/// A statement to begin a transaction.
final class BeginStatement extends SqlStatement {
  /// For nested transactions, an incrementing counter for each level of
  /// nesting.
  /// The first transaction opened in a session with have a [depth] of zero.
  final int depth;

  /// @nodoc
  BeginStatement({this.depth = 0});

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addBegin(this);
  }
}

/// A statement to commit a transaction.
final class CommitStatement extends SqlStatement {
  /// The depth of the corresponding [BeginStatement.depth] to commit.
  final int depth;

  /// @nodoc
  CommitStatement({this.depth = 0});

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addCommit(this);
  }
}

/// A statement to roll back (possibly nested) transactions.
final class RollbackStatement extends SqlStatement {
  /// The depth of the corresponding [BeginStatement.depth] to roll back.
  final int depth;

  /// @nodoc
  RollbackStatement({this.depth = 0});

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addRollback(this);
  }
}
