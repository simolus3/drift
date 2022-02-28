import '../../reader/tokenizer/token.dart';
import '../ast.dart' show Variable;
import '../expressions/expressions.dart';
import '../node.dart';
import '../statements/statement.dart';
import '../statements/transaction.dart';
import '../visitor.dart';
import 'drift_file.dart';

/// A declared statement inside a `.moor` file. It consists of an identifier,
/// followed by a colon and the query to run.
class DeclaredStatement extends Statement implements PartOfDriftFile {
  final DeclaredStatementIdentifier identifier;
  AstNode statement;
  List<StatementParameter> parameters;

  /// The desired result class name, if set.
  final String? as;

  Token? colon;

  /// Whether this is a regular query, meaning that Dart methods are generated
  /// for it. Special queries are annotated with an `@` and have special
  /// meaning.
  bool get isRegularQuery => identifier is SimpleName;

  DeclaredStatement(this.identifier, this.statement,
      {this.parameters = const [], this.as});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDriftSpecificNode(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    statement = transformer.transformChild(statement, this, arg);
    parameters = transformer.transformChildren(parameters, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [statement, ...parameters];
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
  IdentifierToken? identifier;

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
  AtSignVariableToken? nameToken;

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

/// A statement parameter, which appears between brackets after the statement
/// identifier.
/// In `selectString(:name AS TEXT): SELECT :name`, `:name AS TEXT` is a
/// statement parameter.
abstract class StatementParameter extends AstNode implements DriftSpecificNode {
  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDriftSpecificNode(this, arg);
  }
}

/// Construct to explicitly set a variable type.
///
/// Users can use `:name AS TYPE` as a statement parameter. Any use of `:name`
/// in the query will then be resolved to the type set here. This is useful for
/// cases in which the resolver doesn't yield acceptable results.
class VariableTypeHint extends StatementParameter {
  Variable variable;
  final bool isRequired;
  final String? typeName;
  final bool orNull;

  Token? as;

  VariableTypeHint(this.variable, this.typeName,
      {this.orNull = false, this.isRequired = false});

  @override
  Iterable<AstNode> get childNodes => [variable];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    variable = transformer.transformChild(variable, this, arg);
  }
}

/// Set a default value for a dart placeholder.
///
/// For instance,
/// ```
/// query($predicate = TRUE): SELECT * FROM tbl WHERE $predicate;
/// ```
///
/// Would generate an optional `predicate` parameter in Dart, having a default
/// value of `CustomExpression('TRUE')`.
class DartPlaceholderDefaultValue extends StatementParameter {
  final String variableName;
  Expression defaultValue;

  DollarSignVariableToken? variableToken;

  DartPlaceholderDefaultValue(this.variableName, this.defaultValue);

  @override
  Iterable<AstNode> get childNodes => [defaultValue];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    defaultValue = transformer.transformChild(defaultValue, this, arg);
  }
}

class TransactionBlock extends AstNode implements DriftSpecificNode {
  BeginTransactionStatement begin;
  List<CrudStatement> innerStatements;
  CommitStatement commit;

  TransactionBlock({
    required this.begin,
    required this.innerStatements,
    required this.commit,
  });

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitDriftSpecificNode(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => [];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    begin = transformer.transformChild(begin, this, arg);
    innerStatements = transformer.transformChildren(innerStatements, this, arg);
    commit = transformer.transformChild(commit, this, arg);
  }
}
