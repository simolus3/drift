// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'manager.dart';

sealed class _BaseAnnotation<SqlType extends Object, $Table extends Table> {
  Expression<SqlType> get _expression;
  final Set<JoinBuilder> _joinBuilders;
  _BaseAnnotation(this._joinBuilders);
}

class Annotation<SqlType extends Object, $Table extends Table>
    extends _BaseAnnotation<SqlType, $Table> {
  @override
  final Expression<SqlType> _expression;

  ColumnFilters<SqlType> get filter {
    return ColumnFilters(_expression);
  }

  SqlType? read(BaseReferences refs) {
    return refs.$_typedResult.read(_expression);
  }

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

class AnnotationWithConverter<DartType, SqlType extends Object,
    $Table extends Table> extends _BaseAnnotation<SqlType, $Table> {
  @override
  final GeneratedColumnWithTypeConverter<DartType, SqlType> _expression;

  ColumnWithTypeConverterFilters<DartType, DartType, SqlType> get filter {
    return ColumnWithTypeConverterFilters(_expression);
  }

  final DartType Function(SqlType) converter;

  AnnotationWithConverter(this._expression, super._joinBuilders,
      {required this.converter});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AnnotationWithConverter<DartType, SqlType, $Table> &&
        other._expression == _expression &&
        SetEquality<JoinBuilder>().equals(other._joinBuilders, _joinBuilders);
  }

  @override
  int get hashCode => _expression.hashCode ^ _joinBuilders.hashCode;

  DartType? read(BaseReferences refs) {
    final dartType = refs.$_typedResult.read(_expression);
    if (dartType == null) {
      return null;
    }
    return converter(dartType);
  }
}

/// The class that orchestrates the composition of orderings
class AnnotationComposer<DB extends GeneratedDatabase, T extends Table>
    extends Composer<DB, T> {
  @internal
  AnnotationComposer(
      {required super.$db,
      required super.$table,
      super.joinBuilder,
      super.$addJoinBuilderToRootComposer,
      super.$removeJoinBuilderFromRootComposer});
}
