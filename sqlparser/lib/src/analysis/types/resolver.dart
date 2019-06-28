part of '../analysis.dart';

const comparisonOperators = [
  TokenType.equal,
  TokenType.doubleEqual,
  TokenType.exclamationEqual,
  TokenType.lessMore,
  TokenType.and,
  TokenType.or,
  TokenType.less,
  TokenType.lessEqual,
  TokenType.more,
  TokenType.moreEqual
];

class TypeResolver {
  final Map<Typeable, ResolveResult> _results = {};

  ResolveResult _cache<T extends Typeable>(
      ResolveResult Function(T param) resolver, T typeable) {
    if (_results.containsKey(typeable)) {
      return _results[typeable];
    }

    final calculated = resolver(typeable);
    if (calculated.type != null) {
      _results[typeable] = calculated;
    }
    return calculated;
  }

  ResolveResult resolveColumn(Column column) {
    return _cache((column) {
      if (column is TableColumn) {
        // todo probably needs to be nullable when coming from a join?
        return ResolveResult(column.type);
      } else if (column is ExpressionColumn) {
        return resolveExpression(column.expression);
      }

      throw StateError('Unknown column $column');
    }, column);
  }

  ResolveResult resolveExpression(Expression expr) {
    return _cache((expr) {
      if (expr is Literal) {
        return resolveLiteral(expr);
      } else if (expr is UnaryExpression) {
        return resolveExpression(expr.inner);
      } else if (expr is Parentheses) {
        return resolveExpression(expr.expression);
      } else if (expr is Variable) {
        return const ResolveResult.needsContext();
      } else if (expr is Reference) {
        return resolveColumn(expr.resolved as Column);
      } else if (expr is FunctionExpression) {
        return resolveFunctionCall(expr);
      } else if (expr is IsExpression) {
        return const ResolveResult(ResolvedType.bool());
      } else if (expr is BinaryExpression) {
        final operator = expr.operator.type;
        if (comparisonOperators.contains(operator)) {
          return const ResolveResult(ResolvedType.bool());
        } else {
          final type = _encapsulate(expr.childNodes.cast(),
              [BasicType.int, BasicType.real, BasicType.text, BasicType.blob]);
          return ResolveResult(type);
        }
      } else if (expr is SubQuery) {
        // todo
      }

      throw StateError('Unknown expression $expr');
    }, expr);
  }

  ResolveResult resolveLiteral(Literal l) {
    return _cache((l) {
      if (l is StringLiteral) {
        return ResolveResult(
            ResolvedType(type: l.isBinary ? BasicType.blob : BasicType.text));
      } else if (l is NumericLiteral) {
        if (l is BooleanLiteral) {
          return const ResolveResult(ResolvedType.bool());
        } else {
          return ResolveResult(
              ResolvedType(type: l.isInt ? BasicType.int : BasicType.real));
        }
      } else if (l is NullLiteral) {
        return const ResolveResult(
            ResolvedType(type: BasicType.nullType, nullable: true));
      }

      throw StateError('Unknown literal $l');
    }, l);
  }

  ResolveResult resolveFunctionCall(FunctionExpression call) {
    // todo
    return const ResolveResult.unknown();
  }

  /// Returns the type of an expression in [expressions] that has the highest
  /// order in [types].
  ResolvedType _encapsulate(
      Iterable<Expression> expressions, List<BasicType> types) {
    final argTypes = expressions
        .map((expr) => resolveExpression(expr).type)
        .where((t) => t != null);
    final type = types.lastWhere((t) => argTypes.any((arg) => arg.type == t));
    final notNull = argTypes.any((t) => !t.nullable);

    return ResolvedType(type: type, nullable: !notNull);
  }
}

class ResolveResult {
  final ResolvedType type;
  final bool needsContext;
  final bool unknown;

  const ResolveResult(this.type)
      : needsContext = false,
        unknown = false;
  const ResolveResult.needsContext()
      : type = null,
        needsContext = true,
        unknown = false;
  const ResolveResult.unknown()
      : type = null,
        needsContext = false,
        unknown = true;
}
