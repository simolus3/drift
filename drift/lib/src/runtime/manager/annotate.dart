part of 'manager.dart';

/// A class that contains the information needed to create an annotation
sealed class BaseAnnotation<SqlType extends Object, $Table extends Table> {
  /// The expression/column which will be added to the query
  Expression<SqlType> get _expression;

  /// The join builders that are needed to read the expression
  final Set<JoinBuilder> _joinBuilders;
  BaseAnnotation(this._joinBuilders);
}

/// A class that contains the information needed to create an annotation
class Annotation<SqlType extends Object, $Table extends Table>
    extends BaseAnnotation<SqlType, $Table> {
  @override
  final Expression<SqlType> _expression;

  /// Create a filter for this annotation
  ColumnFilters<SqlType> get filter {
    return ColumnFilters(_expression);
  }

  /// Read the result of the annotation from the [BaseReferences] object
  SqlType? read(BaseReferences refs) {
    return refs.$_typedResult.read(_expression);
  }

  /// Create a new annotation
  Annotation(this._expression, super._joinBuilders);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Annotation<SqlType, $Table> &&
        other._expression == _expression &&
        SetEquality<JoinBuilder>().equals(other._joinBuilders, _joinBuilders);
  }

  @override
  int get hashCode => _expression.hashCode ^ _joinBuilders.hashCode;
}

/// A class that contains the information needed to create an annotation for a column with a converter
class AnnotationWithConverter<DartType, SqlType extends Object,
    $Table extends Table> extends BaseAnnotation<SqlType, $Table> {
  @override
  final GeneratedColumnWithTypeConverter<DartType, SqlType> _expression;

  /// Create a filter for this annotation
  ColumnWithTypeConverterFilters<DartType, DartType, SqlType> get filter {
    return ColumnWithTypeConverterFilters(_expression);
  }

  /// Converter function to convert from [SqlType] to [DartType]
  final DartType Function(SqlType) $converter;

  /// Create a new annotation with a converter
  AnnotationWithConverter(this._expression, super._joinBuilders,
      {required this.$converter});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AnnotationWithConverter<DartType, SqlType, $Table> &&
        other._expression == _expression &&
        SetEquality<JoinBuilder>().equals(other._joinBuilders, _joinBuilders);
  }

  @override
  int get hashCode => _expression.hashCode ^ _joinBuilders.hashCode;

  /// Read the result of the annotation from the [BaseReferences] object
  DartType? read(BaseReferences refs) {
    final dartType = refs.$_typedResult.read(_expression);
    if (dartType == null) {
      return null;
    }
    return $converter(dartType);
  }
}

/// The class that orchestrates the composition of orderings
class AnnotationComposer<DB extends GeneratedDatabase, T extends Table>
    extends Composer<DB, T> {
  @internal

  /// Create a new annotation composer which will be used to create annotations
  AnnotationComposer(
      {required super.$db,
      required super.$table,
      super.joinBuilder,
      super.$addJoinBuilderToRootComposer,
      super.$removeJoinBuilderFromRootComposer});
}

/// Extension type for an [Expression] that that should be used in an annotation
///
/// The purpose of this extension type is to cooerce an expression which references
/// multiple rows on another table into an annotation.
extension type AggregateBuilder<T extends Object>(Expression<T> expression) {
  /// {@macro drift_aggregate_base_count}
  Expression<int> count({bool distinct = false, Expression<bool>? filter}) =>
      expression.count(distinct: distinct, filter: filter);

  /// {@macro drift_aggregate_base_max}
  Expression<T> max({Expression<bool>? filter}) =>
      expression.max(filter: filter);

  /// {@macro drift_aggregate_base_min}
  Expression<T> min({Expression<bool>? filter}) =>
      expression.min(filter: filter);

  /// {@macro drift_aggregate_base_max}
  Expression<String> groupConcat({
    String separator = ',',
    bool distinct = false,
    Expression<bool>? filter,
  }) =>
      expression.groupConcat(
          separator: separator, distinct: distinct, filter: filter);
}

/// Provides aggregate functions that are available for numeric expressions.
extension ArithmeticAggregateBuilder<DT extends num> on AggregateBuilder<DT> {
  Expression<double> avg({Expression<bool>? filter}) =>
      expression.avg(filter: filter);
  Expression<DT> max({Expression<bool>? filter}) =>
      expression.max(filter: filter);
  Expression<DT> min({Expression<bool>? filter}) =>
      expression.min(filter: filter);
  Expression<DT> sum({Expression<bool>? filter}) =>
      expression.sum(filter: filter);
  Expression<double> total({Expression<bool>? filter}) =>
      expression.total(filter: filter);
}

/// Provides aggregate functions that are available for BigInt expressions.
extension BigIntAggregateBuilder on AggregateBuilder<BigInt> {
  Expression<double> avg({Expression<bool>? filter}) =>
      expression.avg(filter: filter);
  Expression<BigInt> max({Expression<bool>? filter}) =>
      expression.max(filter: filter);
  Expression<BigInt> min({Expression<bool>? filter}) =>
      expression.min(filter: filter);
  Expression<BigInt> sum({Expression<bool>? filter}) =>
      expression.sum(filter: filter);
  Expression<double> total({Expression<bool>? filter}) =>
      expression.total(filter: filter);
}

/// Provides aggregate functions that are available on date time expressions.
extension DateTimeAggregateBuilder on AggregateBuilder<DateTime> {
  Expression<DateTime> avg({Expression<bool>? filter}) =>
      expression.avg(filter: filter);
  Expression<DateTime> max({Expression<bool>? filter}) =>
      expression.max(filter: filter);
  Expression<DateTime> min({Expression<bool>? filter}) =>
      expression.min(filter: filter);
}
