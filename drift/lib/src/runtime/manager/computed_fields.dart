part of 'manager.dart';

/// The base class for all computed fields
///
/// An `computed field` is an regular drift [expression](https://drift.simonbinder.eu/docs/getting-started/expressions/) with
/// the additional ability to create the necessary joins automatically.
///
/// Typically, when using drift expression you would have to manually create the joins for the tables that you want to use.
/// However, with computed fields, drift will automatically create the necessary joins for you.
///
/// Computed fields can be used in filters, orderings and in the select statement.
/// Computed fields should not be constructed directly. Instead, use the `.computed field` method on a table manager to create an computed field.
///
/// Example:
/// {@macro computed_field_example}
///
/// See also:
/// - [ComputedField] for a simple computed field
/// - [ComputedFieldWithConverter] for computed fields which have a converter
/// - [RootTableManager.computed field] for creating computed fields
/// - [RootTableManager.computed fieldWithConverter] for creating computed fields with a converter
/// - [Computed Field Documentation](https://drift.simonbinder.eu/docs/manager/#computed fields)
sealed class BaseComputedField<SqlType extends Object, $Table extends Table> {
  /// The expression/column which will be added to the query
  Expression<SqlType> get _expression;

  /// The join builders that are needed to read the expression
  final Set<JoinBuilder> _joinBuilders;
  BaseComputedField(this._joinBuilders);

  /// Create an order by clause for this computed field
  ColumnOrderings get order {
    return ColumnOrderings(_expression);
  }
}

/// An computed field for a table.
///
/// This class implements [BaseComputedField] and is used to create a computed fields which do not have a converter.
///
/// See [BaseComputedField] for more information on computed fields and how to use them.
class ComputedField<SqlType extends Object, $Table extends Table>
    extends BaseComputedField<SqlType, $Table> {
  @override
  final Expression<SqlType> _expression;

  /// Create a filter for this computed field
  ColumnFilters<SqlType> get filter {
    return ColumnFilters(_expression);
  }

  /// Read the result of the computed field from the [BaseReferences] object
  ///
  /// Example:
  /// {@macro computed_field_example}
  SqlType? read(BaseReferences<dynamic, $Table, dynamic> refs) {
    try {
      return refs.$_typedResult.read(_expression);
    } on ArgumentError {
      throw ArgumentError(
          'This computed field has not been added to the query. '
          'Use the .withComputedFields(...) method to add it to the query. ');
    }
  }

  /// Create a new computed field
  ComputedField(this._expression, super._joinBuilders);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComputedField<SqlType, $Table> &&
        other._expression == _expression &&
        SetEquality<JoinBuilder>().equals(other._joinBuilders, _joinBuilders);
  }

  @override
  int get hashCode => _expression.hashCode ^ _joinBuilders.hashCode;
}

/// An computed field for a table which has a converter
///
/// See [BaseComputedField] for more information on computed fields and how to use them.
class ComputedFieldWithConverter<DartType, SqlType extends Object,
    $Table extends Table> extends BaseComputedField<SqlType, $Table> {
  @override
  final GeneratedColumnWithTypeConverter<DartType, SqlType> _expression;

  /// Create a filter for this computed field
  ColumnWithTypeConverterFilters<DartType, DartType, SqlType> get filter {
    return ColumnWithTypeConverterFilters(_expression);
  }

  /// Create a new computed field with a converter
  ComputedFieldWithConverter(this._expression, super._joinBuilders);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ComputedFieldWithConverter<DartType, SqlType, $Table> &&
        other._expression == _expression &&
        SetEquality<JoinBuilder>().equals(other._joinBuilders, _joinBuilders);
  }

  @override
  int get hashCode => _expression.hashCode ^ _joinBuilders.hashCode;

  /// Read the result of the computed field from the a [BaseReferences] object
  ///
  /// Example:
  /// {@macro computed_field_example}
  DartType? read(BaseReferences<dynamic, $Table, dynamic> refs) {
    final dartType = refs.$_typedResult.read(_expression);
    if (dartType == null) {
      return null;
    }
    return _expression.converter.fromSql(dartType);
  }
}
