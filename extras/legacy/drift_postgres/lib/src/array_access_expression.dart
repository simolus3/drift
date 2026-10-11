import 'package:drift/drift.dart';

/// An array index access expression in postgres.
///
/// See also: https://www.postgresql.org/docs/current/arrays.html#ARRAYS-ACCESSING
final class ArrayAccessExpression<T extends Object> extends Expression<T> {
  /// The array expression being indexed.
  final Expression<List<T?>> array;

  /// The index of the element to extract.
  final Expression<int> index;

  final CustomSqlType<T>? customResultType;

  ArrayAccessExpression({
    required this.array,
    required this.index,
    this.customResultType,
  });

  @override
  Precedence get precedence => Precedence.primary;

  @override
  get driftSqlType => customResultType ?? super.driftSqlType;

  @override
  void writeInto(GenerationContext context) {
    array.writeInto(context);
    context.buffer.write('[');
    index.writeInto(context);
    context.buffer.write(']');
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
