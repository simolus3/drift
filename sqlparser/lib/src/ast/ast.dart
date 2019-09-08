import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:sqlparser/src/analysis/analysis.dart';

part 'clauses/limit.dart';
part 'clauses/ordering.dart';

part 'common/queryables.dart';
part 'common/renamable.dart';

part 'expressions/aggregate.dart';
part 'expressions/case.dart';
part 'expressions/expressions.dart';
part 'expressions/function.dart';
part 'expressions/literals.dart';
part 'expressions/reference.dart';
part 'expressions/simple.dart';
part 'expressions/subquery.dart';
part 'expressions/tuple.dart';
part 'expressions/variables.dart';

part 'moor/declared_statement.dart';
part 'moor/import_statement.dart';
part 'moor/moor_file.dart';

part 'schema/column_definition.dart';
part 'schema/table_definition.dart';

part 'statements/create_table.dart';
part 'statements/delete.dart';
part 'statements/insert.dart';
part 'statements/select.dart';
part 'statements/statement.dart';
part 'statements/update.dart';

/// A node in the abstract syntax tree of an SQL statement.
abstract class AstNode {
  /// The parent of this node, or null if this is the root node. Will be set
  /// by the analyzer after the tree has been parsed.
  AstNode parent;

  /// The first token that appears in this node. This information is not set for
  /// all nodes.
  Token first;

  /// The last token that appears in this node. This information is not set for
  /// all nodes.
  Token last;

  /// The first index in the source that belongs to this node. Not set for all
  /// nodes.
  int get firstPosition => first.span.start.offset;

  /// The last position that belongs to node, exclusive. Not set for all nodes.
  int get lastPosition => last.span.end.offset;

  FileSpan get span {
    if (first == null || last == null) return null;
    return first.span.expand(last.span);
  }

  /// Sets the [AstNode.first] and [AstNode.last] property in one go.
  void setSpan(Token first, Token last) {
    this.first = first;
    this.last = last;
  }

  /// Returns all parents of this node up to the root. If this node is the root,
  /// the iterable will be empty.
  Iterable<AstNode> get parents sync* {
    var node = parent;
    while (node != null) {
      yield node;
      node = node.parent;
    }
  }

  /// Returns an iterable containing `this` node and all [parents].
  Iterable<AstNode> get selfAndParents sync* {
    yield this;
    yield* parents;
  }

  /// Recursively returns all descendants of this node, e.g. its children, their
  /// children and so on. The tree will be pre-order traversed.
  Iterable<AstNode> get allDescendants sync* {
    for (var child in childNodes) {
      yield child;
      yield* child.allDescendants;
    }
  }

  final Map<Type, dynamic> _metadata = {};

  /// Returns the metadata of type [T] that might have been set on this node, or
  /// null if none was found.
  /// Nodes can have arbitrary annotations on them set via [setMeta] and
  /// obtained via [meta]. This mechanism is used to, for instance, attach
  /// variable scopes to a subtree.
  T meta<T>() {
    return _metadata[T] as T;
  }

  /// Sets the metadata of type [T] to the specified [value].
  /// Nodes can have arbitrary annotations on them set via [setMeta] and
  /// obtained via [meta]. This mechanism is used to, for instance, attach
  /// variable scopes to a subtree.
  void setMeta<T>(T value) {
    _metadata[T] = value;
  }

  /// The [ReferenceScope], which contains available tables, column references
  /// and functions for this node.
  ReferenceScope get scope {
    var node = this;

    while (node != null) {
      final scope = node.meta<ReferenceScope>();
      if (scope != null) return scope;
      node = node.parent;
    }

    throw StateError('No reference scope found in this or any parent node');
  }

  /// Applies a [ReferenceScope] to this node. Variables declared in [scope]
  /// will be visible to this node and to [allDescendants].
  set scope(ReferenceScope scope) {
    setMeta<ReferenceScope>(scope);
  }

  /// All direct children of this node.
  Iterable<AstNode> get childNodes;

  /// Calls the appropriate method on the [visitor] to make it recognize this
  /// node.
  T accept<T>(AstVisitor<T> visitor);

  /// Whether the content of this node is equal to the [other] node of the same
  /// type. The "content" refers to anything stored only in this node, children
  /// are ignored.
  bool contentEquals(covariant AstNode other);
}

abstract class AstVisitor<T> {
  T visitSelectStatement(SelectStatement e);
  T visitResultColumn(ResultColumn e);
  T visitInsertStatement(InsertStatement e);
  T visitDeleteStatement(DeleteStatement e);
  T visitUpdateStatement(UpdateStatement e);
  T visitCreateTableStatement(CreateTableStatement e);

  T visitOrderBy(OrderBy e);
  T visitOrderingTerm(OrderingTerm e);
  T visitLimit(Limit e);
  T visitQueryable(Queryable e);
  T visitJoin(Join e);
  T visitGroupBy(GroupBy e);

  T visitSetComponent(SetComponent e);

  T visitColumnDefinition(ColumnDefinition e);
  T visitColumnConstraint(ColumnConstraint e);
  T visitTableConstraint(TableConstraint e);
  T visitForeignKeyClause(ForeignKeyClause e);

  T visitBinaryExpression(BinaryExpression e);
  T visitStringComparison(StringComparisonExpression e);
  T visitUnaryExpression(UnaryExpression e);
  T visitIsExpression(IsExpression e);
  T visitBetweenExpression(BetweenExpression e);
  T visitLiteral(Literal e);
  T visitReference(Reference e);
  T visitFunction(FunctionExpression e);
  T visitSubQuery(SubQuery e);
  T visitExists(ExistsExpression e);
  T visitCaseExpression(CaseExpression e);
  T visitWhen(WhenComponent e);
  T visitTuple(TupleExpression e);
  T visitInExpression(InExpression e);

  T visitAggregateExpression(AggregateExpression e);
  T visitWindowDefinition(WindowDefinition e);
  T visitFrameSpec(FrameSpec e);

  T visitNumberedVariable(NumberedVariable e);
  T visitNamedVariable(ColonNamedVariable e);

  T visitMoorFile(MoorFile e);
  T visitMoorImportStatement(ImportStatement e);
  T visitMoorDeclaredStatement(DeclaredStatement e);
}

/// Visitor that walks down the entire tree, visiting all children in order.
class RecursiveVisitor<T> extends AstVisitor<T> {
  @override
  T visitBinaryExpression(BinaryExpression e) => visitChildren(e);

  @override
  T visitStringComparison(StringComparisonExpression e) => visitChildren(e);

  @override
  T visitFunction(FunctionExpression e) => visitChildren(e);

  @override
  T visitGroupBy(GroupBy e) => visitChildren(e);

  @override
  T visitIsExpression(IsExpression e) => visitChildren(e);

  @override
  T visitBetweenExpression(BetweenExpression e) => visitChildren(e);

  @override
  T visitCaseExpression(CaseExpression e) => visitChildren(e);

  @override
  T visitWhen(WhenComponent e) => visitChildren(e);

  @override
  T visitTuple(TupleExpression e) => visitChildren(e);

  @override
  T visitInExpression(InExpression e) => visitChildren(e);

  @override
  T visitSubQuery(SubQuery e) => visitChildren(e);

  @override
  T visitExists(ExistsExpression e) => visitChildren(e);

  @override
  T visitSetComponent(SetComponent e) => visitChildren(e);

  @override
  T visitJoin(Join e) => visitChildren(e);

  @override
  T visitLimit(Limit e) => visitChildren(e);

  @override
  T visitLiteral(Literal e) => visitChildren(e);

  @override
  T visitNamedVariable(ColonNamedVariable e) => visitChildren(e);

  @override
  T visitNumberedVariable(NumberedVariable e) => visitChildren(e);

  @override
  T visitOrderBy(OrderBy e) => visitChildren(e);

  @override
  T visitOrderingTerm(OrderingTerm e) => visitChildren(e);

  @override
  T visitQueryable(Queryable e) => visitChildren(e);

  @override
  T visitReference(Reference e) => visitChildren(e);

  @override
  T visitResultColumn(ResultColumn e) => visitChildren(e);

  @override
  T visitSelectStatement(SelectStatement e) => visitChildren(e);

  @override
  T visitInsertStatement(InsertStatement e) => visitChildren(e);

  @override
  T visitDeleteStatement(DeleteStatement e) => visitChildren(e);

  @override
  T visitUpdateStatement(UpdateStatement e) => visitChildren(e);

  @override
  T visitCreateTableStatement(CreateTableStatement e) => visitChildren(e);

  @override
  T visitUnaryExpression(UnaryExpression e) => visitChildren(e);

  @override
  T visitColumnDefinition(ColumnDefinition e) => visitChildren(e);

  @override
  T visitTableConstraint(TableConstraint e) => visitChildren(e);

  @override
  T visitColumnConstraint(ColumnConstraint e) => visitChildren(e);

  @override
  T visitForeignKeyClause(ForeignKeyClause e) => visitChildren(e);

  @override
  T visitAggregateExpression(AggregateExpression e) => visitChildren(e);

  @override
  T visitWindowDefinition(WindowDefinition e) => visitChildren(e);

  @override
  T visitFrameSpec(FrameSpec e) => visitChildren(e);

  @override
  T visitMoorFile(MoorFile e) => visitChildren(e);

  @override
  T visitMoorImportStatement(ImportStatement e) => visitChildren(e);

  @override
  T visitMoorDeclaredStatement(DeclaredStatement e) => visitChildren(e);

  @protected
  T visitChildren(AstNode e) {
    for (var child in e.childNodes) {
      child.accept(this);
    }
    return null;
  }
}
