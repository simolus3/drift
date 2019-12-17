part of '../ast.dart';

/// A declared statement inside a `.moor` file. It consists of an identifier,
/// followed by a colon and the query to run.
class DeclaredStatement extends Statement implements PartOfMoorFile {
  final DeclaredStatementIdentifier identifier;
  final CrudStatement statement;

  Token colon;

  /// Whether this is a regular query, meaning that Dart methods are generated
  /// for it. Special queries are annotated with an `@` and have special
  /// meaning.
  bool get isRegularQuery => identifier is SimpleName;

  DeclaredStatement(this.identifier, this.statement);

  @override
  T accept<T>(AstVisitor<T> visitor) =>
      visitor.visitMoorDeclaredStatement(this);

  @override
  Iterable<AstNode> get childNodes => [statement];

  @override
  bool contentEquals(DeclaredStatement other) {
    return other.identifier == identifier;
  }
}

/// How a statement was declared in a moor file.
///
/// We support [SimpleName]s (`name: SELECT * FROM tbl`) and special keywords
/// starting with an `@` in
abstract class DeclaredStatementIdentifier {
  String get name;
}

/// The normal, named statement identifier for regular statements.
class SimpleName extends DeclaredStatementIdentifier {
  @override
  final String name;
  IdentifierToken identifier;

  SimpleName(this.name);

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is SimpleName && other.name == name);
  }
}

/// A special statement identifier for statements declared with a `@`-name.
///
/// Those names have a special meaning, like running a statement when the
/// database is created.
class SpecialStatementIdentifier extends DeclaredStatementIdentifier {
  final String specialName;
  AtSignVariableToken nameToken;

  SpecialStatementIdentifier(this.specialName);

  @override
  int get hashCode => specialName.hashCode;

  @override
  String get name => specialName;

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is SpecialStatementIdentifier &&
            other.specialName == specialName);
  }
}
