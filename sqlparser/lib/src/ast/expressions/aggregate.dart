part of '../ast.dart';

class AggregateExpression extends Expression
    implements ExpressionInvocation, ReferenceOwner {
  final IdentifierToken function;

  @override
  String get name => function.identifier;

  @override
  FunctionParameters parameters;
  Expression? filter;

  @override
  Referencable? resolved;
  WindowDefinition? get over {
    if (windowDefinition != null) return windowDefinition;
    return (resolved as NamedWindowDeclaration?)?.definition;
  }

  /// The window definition as declared in the `OVER` clause in sql. If this
  /// aggregate expression didn't declare a window (e.g. it instead uses a
  /// window via a name declared in the surrounding `SELECT` statement), we're
  /// this field will be null. Either [windowDefinition] or [windowName] are
  /// null. The resolved [WindowDefinition] is available in [over] in either
  /// case.
  WindowDefinition? windowDefinition;

  /// An aggregate expression can be written as `OVER <window-name>` instead of
  /// declaring its own [windowDefinition]. Either [windowDefinition] or
  /// [windowName] are null. The resolved [WindowDefinition] is available in
  /// [over] in either case.
  final String? windowName;

  AggregateExpression(
      {required this.function,
      required this.parameters,
      this.filter,
      this.windowDefinition,
      this.windowName})
      // either window definition or name must be null
      : assert((windowDefinition == null) != (windowName == null));

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitAggregateExpression(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    parameters = transformer.transformChild(parameters, this, arg);
    filter = transformer.transformNullableChild(filter, this, arg);
    windowDefinition =
        transformer.transformNullableChild(windowDefinition, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes {
    return [
      parameters,
      if (filter != null) filter!,
      if (windowDefinition != null) windowDefinition!,
    ];
  }
}

/// A window declaration that appears in a `SELECT` statement like
/// `WINDOW <name> AS <window-defn>`. It can be referenced from an
/// [AggregateExpression] if it uses the same name.
class NamedWindowDeclaration with Referencable {
  // todo: Should be an ast node
  final String name;
  final WindowDefinition definition;

  NamedWindowDeclaration(this.name, this.definition);
}

class WindowDefinition extends AstNode {
  final String? baseWindowName;
  List<Expression> partitionBy;
  OrderByBase? orderBy;
  FrameSpec frameSpec;

  WindowDefinition(
      {this.baseWindowName,
      this.partitionBy = const [],
      this.orderBy,
      required this.frameSpec});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitWindowDefinition(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    partitionBy = transformer.transformChildren(partitionBy, this, arg);
    orderBy = transformer.transformNullableChild(orderBy, this, arg);
    frameSpec = transformer.transformChild(frameSpec, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes =>
      [...partitionBy, if (orderBy != null) orderBy!, frameSpec];
}

class FrameSpec extends AstNode {
  final FrameType? type;
  final ExcludeMode? excludeMode;
  FrameBoundary start;
  FrameBoundary end;

  FrameSpec({
    this.type = FrameType.range,
    FrameBoundary? start,
    FrameBoundary? end,
    this.excludeMode = ExcludeMode.noOthers,
  })  : start = start ?? FrameBoundary.unboundedPreceding(),
        end = end ?? FrameBoundary.currentRow();

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitFrameSpec(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    if (start.isExpressionOffset) {
      start.offset = transformer.transformChild(start.offset!, this, arg);
    }
    if (end.isExpressionOffset) {
      end.offset = transformer.transformChild(end.offset!, this, arg);
    }
  }

  @override
  Iterable<AstNode> get childNodes => [
        if (start.isExpressionOffset) start.offset!,
        if (end.isExpressionOffset) end.offset!,
      ];
}

/// Defines how a [FrameBoundary] count rows or groups. See
/// https://www.sqlite.org/windowfunctions.html#frame_type for details.
enum FrameType { rows, groups, range }

/// Defines if rows are omitted inside a [FrameBoundary].
enum ExcludeMode {
  /// default, no rows are excluded from the window frame
  noOthers,

  /// the current row is excluded from the window frame
  currentRow,

  /// The row and and its peers (rows considered to be equal to the ORDER BY
  /// clause) are excluded
  group,

  /// Peers of the row are excluded (see [group]), but not the row itself.
  ties,
}

enum _BoundaryType {
  currentRow,
  exprOffset,
  unboundedOffset,
}

/// Defines how many rows before or after a current row should be included in
/// a window.
class FrameBoundary {
  final _BoundaryType _type;

  /// The (integer) expression that specifies the amount of rows to include
  /// before or after the row being processed.
  Expression? offset;

  /// Whether this boundary refers to a row before the current row.
  final bool preceding;
  bool get following => !preceding;

  /// Whether this boundary is a `<expr> PRECEDING` or `<expr> FOLLOWING`
  /// boundary.
  bool get isExpressionOffset => _type == _BoundaryType.exprOffset;

  /// Whether this boundary is a `UNBOUNDED PRECEDING` or `UNBOUNDED FOLLOWING`.
  bool get isUnbounded => _type == _BoundaryType.unboundedOffset;

  /// Whether this boundary only refers to the current row.
  bool get isCurrentRow => _type == _BoundaryType.currentRow;

  FrameBoundary._(this._type, this.preceding, {this.offset});

  FrameBoundary.unboundedPreceding()
      : this._(_BoundaryType.unboundedOffset, true);
  FrameBoundary.unboundedFollowing()
      : this._(_BoundaryType.unboundedOffset, false);

  FrameBoundary.currentRow() : this._(_BoundaryType.currentRow, false);

  FrameBoundary.preceding(Expression amount)
      : this._(_BoundaryType.exprOffset, true, offset: amount);
  FrameBoundary.following(Expression amount)
      : this._(_BoundaryType.exprOffset, false, offset: amount);

  @override
  int get hashCode {
    return (preceding ? 2 : 3) * (5 * offset.hashCode + _type.hashCode);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    // lint bug: https://github.com/dart-lang/linter/issues/1397
    final typedOther = other as FrameBoundary; // ignore: test_types_in_equals
    return typedOther._type == _type &&
        (typedOther.offset == null && offset == null ||
            typedOther.offset!.contentEquals(offset!)) &&
        typedOther.preceding == preceding;
  }
}
