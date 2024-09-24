part of 'manager.dart';

/// A class that contains the information needed to create an annotation
sealed class BaseAnnotation<SqlType extends Object, $Table extends Table> {
  /// The expression/column which will be added to the query
  Expression<SqlType> get _expression;

  /// The join builders that are needed to read the expression
  final Set<JoinBuilder> _joinBuilders;
  BaseAnnotation(this._joinBuilders);

  /// Create an order by clause for this annotation
  ColumnOrderings get order {
    return ColumnOrderings(_expression);
  }
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