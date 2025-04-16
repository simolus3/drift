import 'package:meta/meta.dart';

import '../../runtime/type_converter.dart';
import '../compiler.dart';
import '../expressions/custom.dart';
import '../expressions/expression.dart';
import '../statements/select.dart';
import 'column.dart';
import 'entities.dart';
import 'result_set.dart';

@immutable
abstract interface class GeneratedView<Row extends Object,
    Self extends GeneratedView<Row, Self>> implements ResultSet<Row, Self> {
  SelectStatement? get query;
  CustomComponent? get sqlDefinition;

  /// The names of tables that this view is reading from.
  Set<String> get readsFrom;
}

@immutable
final class ViewColumn<T extends Object> extends SchemaColumn<T> {
  final Expression<T> expression;

  const ViewColumn({
    required super.name,
    required super.type,
    super.isNullable,
    required this.expression,
  });

  ViewColumn.forDriftFile({
    required super.name,
    required super.type,
    super.isNullable,
  }) : expression = const CustomExpression(CustomComponent(''));

  /// Applies a type converter to this column.
  ///
  /// This is mainly used by the generator.
  ViewColumnWithTypeConverter<D, T> withConverter<D>(
      TypeConverter<D, T?> converter) {
    return ViewColumnWithTypeConverter._(
      base: this,
      converter: converter,
    );
  }
}

/// A [Expression] that has a [TypeConverter] attached to it.
///
/// This provides methods like [SchemaColumnWithTypeConverter.equalsValue],
/// which can be used to apply the type converter when building comparisons.
@immutable
final class ViewColumnWithTypeConverter<D, S extends Object>
    extends ViewColumn<S> with SchemaColumnWithTypeConverter<D, S> {
  @override
  final TypeConverter<D, S?> converter;

  ViewColumnWithTypeConverter._({
    required this.converter,
    required ViewColumn<S> base,
  }) : super(
          name: base.name,
          type: base.type,
          isNullable: base.isNullable,
          expression: base.expression,
        );
}

/// Represents a `CREATE VIEW` statement in SQL.
@immutable
final class CreateViewStatement extends CreateStatement<GeneratedView> {
  /// Create a statement that will `CREATE` the [entity] when issued.
  CreateViewStatement(super.entity, {super.ifNotExists});

  @override
  void compileWith(StatementCompiler compiler) {
    return compiler.addCreateViewStatement(this);
  }
}
