part of 'manager.dart';

/// The base class for all annotations
///
/// An `annotation` is an regular drift [expression](https://drift.simonbinder.eu/docs/getting-started/expressions/) with
/// the additional ability to create the necessary joins automatically.
///
/// Typically, when using drift expression you would have to manually create the joins for the tables that you want to use.
/// However, with annotations, drift will automatically create the necessary joins for you.
///
/// Annotations can be used in filters, orderings and in the select statement.
/// Annotations should not be constructed directly. Instead, use the `.annotation` method on a table manager to create an annotation.
///
/// Example:
/// {@macro annotation_example}
///
/// See also:
/// - [Annotation] for a simple annotation
/// - [AnnotationWithConverter] for annotations which have a converter
/// - [RootTableManager.annotation] for creating annotations
/// - [RootTableManager.annotationWithConverter] for creating annotations with a converter
/// - [Annotation Documentation](https://drift.simonbinder.eu/docs/manager/#annotations)
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

/// An annotation for a table.
///
/// This class implements [BaseAnnotation] and is used to create a annotations which do not have a converter.
///
/// See [BaseAnnotation] for more information on annotations and how to use them.
class Annotation<SqlType extends Object, $Table extends Table>
    extends BaseAnnotation<SqlType, $Table> {
  @override
  final Expression<SqlType> _expression;

  /// Create a filter for this annotation
  ColumnFilters<SqlType> get filter {
    return ColumnFilters(_expression);
  }

  /// Read the result of the annotation from the [BaseReferences] object
  ///
  /// Example:
  /// {@macro annotation_example}
  SqlType? read(BaseReferences<dynamic, $Table, dynamic> refs) {
    try {
      return refs.$_typedResult.read(_expression);
    } on ArgumentError {
      throw ArgumentError('This annotation has not been added to the query. '
          'Use the .withAnnotations(...) method to add it to the query. ');
    }
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

/// An annotation for a table which has a converter
///
/// See [BaseAnnotation] for more information on annotations and how to use them.
class AnnotationWithConverter<DartType, SqlType extends Object,
    $Table extends Table> extends BaseAnnotation<SqlType, $Table> {
  @override
  final GeneratedColumnWithTypeConverter<DartType, SqlType> _expression;

  /// Create a filter for this annotation
  ColumnWithTypeConverterFilters<DartType, DartType, SqlType> get filter {
    return ColumnWithTypeConverterFilters(_expression);
  }

  /// Create a new annotation with a converter
  AnnotationWithConverter(this._expression, super._joinBuilders);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AnnotationWithConverter<DartType, SqlType, $Table> &&
        other._expression == _expression &&
        SetEquality<JoinBuilder>().equals(other._joinBuilders, _joinBuilders);
  }

  @override
  int get hashCode => _expression.hashCode ^ _joinBuilders.hashCode;

  /// Read the result of the annotation from the a [BaseReferences] object
  ///
  /// Example:
  /// {@macro annotation_example}
  DartType? read(BaseReferences<dynamic, $Table, dynamic> refs) {
    final dartType = refs.$_typedResult.read(_expression);
    if (dartType == null) {
      return null;
    }
    return _expression.converter.fromSql(dartType);
  }
}
