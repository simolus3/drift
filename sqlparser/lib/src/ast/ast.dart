import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:sqlparser/src/analysis/analysis.dart';
import 'package:sqlparser/src/utils/meta.dart';

part 'clauses/limit.dart';
part 'clauses/ordering.dart';
part 'clauses/with.dart';

part 'common/queryables.dart';
part 'common/renamable.dart';
part 'common/tuple.dart';

part 'expressions/aggregate.dart';
part 'expressions/case.dart';
part 'expressions/expressions.dart';
part 'expressions/function.dart';
part 'expressions/literals.dart';
part 'expressions/reference.dart';
part 'expressions/simple.dart';
part 'expressions/subquery.dart';
part 'expressions/variables.dart';

part 'moor/declared_statement.dart';
part 'moor/import_statement.dart';
part 'moor/inline_dart.dart';
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
abstract class AstNode with HasMetaMixin {
  /// The parent of this node, or null if this is the root node. Will be set
  /// by the analyzer after the tree has been parsed.
  AstNode parent;

  /// The first token that appears in this node. This information is not set for
  /// all nodes.
  Token first;

  /// The last token that appears in this node. This information is not set for
  /// all nodes.
  Token last;

  /// Whether this ast node is synthetic, meaning that it doesn't appear in the
  /// actual source.
  bool synthetic;

  /// The first index in the source that belongs to this node. Not set for all
  /// nodes.
  int get firstPosition => first.span.start.offset;

  /// The (exclusive) last index of this node in the source. In other words, the
  /// first index that is _not_ a part of this node. Not set for all nodes.
  int get lastPosition => last.span.end.offset;

  FileSpan get span {
    if (!hasSpan) return null;
    return first.span.expand(last.span);
  }

  /// Whether a source span has been set on this node. The span describes what
  /// range in the source code is covered by this node.
  bool get hasSpan => first != null && last != null;

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

  /// Returns an iterable that fields yields this node, followed by
  /// [allDescendants].
  Iterable<AstNode> get selfAndDescendants sync* {
    yield this;
    yield* allDescendants;
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

  @override
  String toString() {
    if (hasSpan) {
      return '$runtimeType: ${span.text}';
    }
    return super.toString();
  }
}

abstract class AstVisitor<T> {
  T visitSelectStatement(SelectStatement e);
  T visitCompoundSelectStatement(CompoundSelectStatement e);
  T visitCompoundSelectPart(CompoundSelectPart e);
  T visitResultColumn(ResultColumn e);
  T visitInsertStatement(InsertStatement e);
  T visitDeleteStatement(DeleteStatement e);
  T visitUpdateStatement(UpdateStatement e);
  T visitCreateTableStatement(CreateTableStatement e);

  T visitWithClause(WithClause e);
  T visitCommonTableExpression(CommonTableExpression e);
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
  T visitTuple(Tuple e);
  T visitInExpression(InExpression e);

  T visitAggregateExpression(AggregateExpression e);
  T visitWindowDefinition(WindowDefinition e);
  T visitFrameSpec(FrameSpec e);

  T visitNumberedVariable(NumberedVariable e);
  T visitNamedVariable(ColonNamedVariable e);

  T visitMoorFile(MoorFile e);
  T visitMoorImportStatement(ImportStatement e);
  T visitMoorDeclaredStatement(DeclaredStatement e);
  T visitDartPlaceholder(DartPlaceholder e);
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
  T visitTuple(Tuple e) => visitChildren(e);

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
  T visitCompoundSelectStatement(CompoundSelectStatement e) => visitChildren(e);

  @override
  T visitCompoundSelectPart(CompoundSelectPart e) => visitChildren(e);

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
  T visitWithClause(WithClause e) => visitChildren(e);

  @override
  T visitCommonTableExpression(CommonTableExpression e) => visitChildren(e);

  @override
  T visitMoorFile(MoorFile e) => visitChildren(e);

  @override
  T visitMoorImportStatement(ImportStatement e) => visitChildren(e);

  @override
  T visitMoorDeclaredStatement(DeclaredStatement e) => visitChildren(e);

  @override
  T visitDartPlaceholder(DartPlaceholder e) => visitChildren(e);

  @protected
  T visitChildren(AstNode e) {
    for (var child in e.childNodes) {
      child.accept(this);
    }
    return null;
  }
}
