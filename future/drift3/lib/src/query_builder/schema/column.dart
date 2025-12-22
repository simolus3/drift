import '../compiler.dart';
import '../dialect.dart';
import '../expressions/boolean.dart';
import '../expressions/expression.dart';
import '../type_converter.dart';
import '../types.dart';
import 'result_set.dart';

/// A column that appears as part of some schema object.
base class SchemaColumn<T extends Object> extends Expression<T> {
  /// The raw name of the column in SQL (without any escaping quotes).
  final String name;

  /// The SQL type of this column.
  final SqlType<T> type;

  /// Whether the column is nullable in SQL, meaning that it doesn't have a
  /// `NOT NULL` constraint applied to it.
  final bool isNullable;

  /// The [ResultSet] that this column is part of.
  late ResultSet owningResultSet;

  /// @nodoc
  SchemaColumn({
    required this.name,
    required this.type,
    this.isNullable = true,
  });

  @override
  PhysicalSqlType<T> resolveType(DriftDialect dialect) {
    return type.resolveIn(dialect);
  }

  @override
  String toString() {
    return '${owningResultSet.alias}.$name';
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addColumnReference(this);
  }
}

/// A [SchemaColumn] with a type converter attached to it.
///
/// This provides the [equalsValue] method, which can be used to compare this
/// column against a value mapped through a type converter.
base mixin SchemaColumnWithTypeConverter<D, S extends Object>
    on SchemaColumn<S> {
  /// The type converted used on this column.
  TypeConverter<D, S?> get converter;

  S? _mapDartValue(D? dartValue) {
    S? mappedValue;

    if (isNullable) {
      // For nullable columns, the type converter needs to accept null values.
      mappedValue = (converter as TypeConverter<D?, S?>).toSql(dartValue);
    } else {
      if (dartValue == null) {
        throw ArgumentError(
          "This non-nullable column can't be equal to `null`.",
          'dartValue',
        );
      }

      mappedValue = converter.toSql(dartValue);
    }

    if (!isNullable && dartValue == null) {
      throw ArgumentError(
        "This non-nullable column can't be equal to `null`.",
        'dartValue',
      );
    }

    return mappedValue;
  }

  /// Compares this column against the mapped [dartValue].
  ///
  /// The value will be mapped using the [converter] applied to this column.
  /// Unlike [Expression.equals], this handles nullability with semantics one
  /// might expect in Dart: `null` is equal to `null`.
  Expression<bool> equalsValue(D? dartValue) {
    final mappedValue = _mapDartValue(dartValue);
    if (mappedValue == null) {
      return isNull();
    } else {
      return isNotNull() & equals(mappedValue);
    }
  }

  /// An expression that is true if `this` resolves to any of the values in
  /// [values].
  ///
  /// The values will be mapped using the [converter] applied to this column.
  /// Unlike [Expression.isIn], this method will also handle nullability with
  /// semantics on might expect in Dart. If [values] contains `null` and this
  /// column is nullable, [isInValues] evaluates to `true`.
  Expression<bool> isInValues(Iterable<D> values) {
    final mappedValues = values.map(_mapDartValue);
    final result = isIn(mappedValues.nonNulls);

    final hasNulls = mappedValues.any((e) => e == null);
    if (hasNulls) {
      return result | isNull();
    } else {
      return result & isNotNull();
    }
  }

  /// An expression that is true if `this` does not resolve to any of the values
  /// in [values].
  ///
  /// The values will be mapped using the [converter] applied to this column.
  Expression<bool> isNotInValues(Iterable<D> values) {
    final mappedValues = values.map(_mapDartValue);
    final result = isNotIn(mappedValues.nonNulls);

    final hasNulls = mappedValues.any((e) => e == null);
    if (hasNulls) {
      return result & isNotNull();
    } else {
      return result | isNull();
    }
  }
}
