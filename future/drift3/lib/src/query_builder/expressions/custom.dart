import 'package:meta/meta.dart';

import '../compiler.dart';
import '../dialect.dart';
import '../types.dart';
import 'expression.dart';

/// A custom expression that can appear in a sql statement.
/// The [CustomExpression.customText] will be written into the query without any
/// modification.
@internal
final class CustomExpression<D extends Object> extends Expression<D> {
  /// The custom SQL text making up this custom expression.
  final CustomComponent customText;

  @override
  final Precedence precedence;

  final SqlType<D>? _customType;

  /// Constructs a custom expression by providing the [customText].
  const CustomExpression(
    this.customText, {
    this.precedence = Precedence.unknown,
    SqlType<D>? customType,
  }) : _customType = customType;

  @override
  PhysicalSqlType<D> resolveType(DriftDialect dialect) {
    return _customType?.resolveIn(dialect) ?? super.resolveType(dialect);
  }

  @override
  void compileWith(StatementCompiler compiler) {
    return customText.compileWith(compiler);
  }

  @override
  int get hashCode => customText.hashCode * 3;

  @override
  bool operator ==(Object other) {
    return other is CustomExpression && other.customText == customText;
  }
}
