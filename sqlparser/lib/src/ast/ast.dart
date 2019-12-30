import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';
import 'package:sqlparser/src/analysis/analysis.dart';
import 'package:sqlparser/src/reader/syntactic_entity.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:sqlparser/src/utils/meta.dart';

part 'clauses/limit.dart';
part 'clauses/ordering.dart';
part 'clauses/with.dart';
part 'common/queryables.dart';
part 'common/renamable.dart';
part 'common/tuple.dart';
part 'expressions/aggregate.dart';
part 'expressions/case.dart';
part 'expressions/cast.dart';
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
part 'visitor.dart';

/// A node in the abstract syntax tree of an SQL statement.
abstract class AstNode with HasMetaMixin implements SyntacticEntity {
  /// The parent of this node, or null if this is the root node. Will be set
  /// by the analyzer after the tree has been parsed.
  AstNode parent;

  /// The first token that appears in this node. This information is not set for
  /// all nodes.
  Token first;

  /// The last token that appears in this node. This information is not set for
  /// all nodes.
  Token last;

  @override
  bool synthetic = false;

  @override
  int get firstPosition => first.span.start.offset;

  @override
  int get lastPosition => last.span.end.offset;

  @override
  FileSpan get span {
    if (!hasSpan) return null;
    return first.span.expand(last.span);
  }

  @override
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
    for (final child in childNodes) {
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
  R accept<A, R>(AstVisitor<A, R> visitor, A arg);

  /// Like [accept], but without an argument.
  ///
  /// Null will be used for the argument instead.
  R acceptWithoutArg<R>(AstVisitor<void, R> visitor) {
    return accept(visitor, null);
  }

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
