// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'manager.dart';

class Annotation<T extends Object> {
  final List<JoinBuilder> _joinBuilders;

  final Expression<T> _expression;

  ColumnFilters<T> get filter {
    return ColumnFilters(_expression);
  }

  ColumnOrderings<T> get order {
    return ColumnOrderings(_expression);
  }

  const Annotation(this._expression, this._joinBuilders);

  @override
  bool operator ==(covariant Annotation<T> other) {
    if (identical(this, other)) return true;

    return other._expression == _expression;
  }

  @override
  int get hashCode => _expression.hashCode;

  T? read(BaseReferences refs) {
    return refs.$_typedResult.read(_expression);
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
