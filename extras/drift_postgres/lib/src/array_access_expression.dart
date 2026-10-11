// ignore: implementation_imports
import 'package:drift/src/drift3_preview/drift.dart';

import 'dialect.dart';

/// An array index access expression in postgres.
///
/// See also: https://www.postgresql.org/docs/current/arrays.html#ARRAYS-ACCESSING
final class ArrayAccessExpression<T extends Object> extends Expression<T> {
  /// The array expression being indexed.
  final Expression<List<T?>> array;

  /// The index of the element to extract.
  final Expression<int> index;

  @override
  final SqlType<T> sqlType;

  /// @nodoc
  ArrayAccessExpression({
    required this.array,
    required this.index,
    required this.sqlType,
  });

  @override
  Precedence get precedence => Precedence.primary;

  @override
  void compileWith(StatementCompiler compiler) {
    return (compiler as PostgresSqlCompiler).addArrayAccessExpression(this);
  }

  @override
  int get hashCode => Object.hash(array, index);

  @override
  bool operator ==(Object other) {
    return other is ArrayAccessExpression &&
        other.array == array &&
        other.index == index;
  }
}
