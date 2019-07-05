import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/expressions/expression.dart';
import 'package:moor/src/runtime/expressions/text.dart';
import 'package:moor/src/runtime/expressions/variables.dart';
import 'package:moor/src/types/sql_types.dart';
import 'package:moor/sqlite_keywords.dart';

import 'error_handling.dart';

const VerificationResult _invalidNull = VerificationResult.failure(
    "This column is not nullable and doesn't have a default value. "
    "Null fields thus can't be inserted.");

/// Base class for the implementation of [Column].
abstract class GeneratedColumn<T, S extends SqlType<T>> extends Column<T, S> {
  /// The sql name of this column.
  final String $name;
  String get escapedName => escapeIfNeeded($name);

  /// The name of the table that contains this column
  final String tableName;

  /// Whether null values are allowed for this column.
  final bool $nullable;

  /// If custom constraints have been specified for this column via
  /// [ColumnBuilder.customConstraint], these are kept here. Otherwise, this
  /// field is going to be null.
  final String $customConstraints;

  /// The default expression to be used during inserts when no value has been
  /// specified. Can be null if no default value is set.
  final Expression<T, S> defaultValue;

  GeneratedColumn(this.$name, this.tableName, this.$nullable,
      {this.$customConstraints, this.defaultValue});

  /// Writes the definition of this column, as defined
  /// [here](https://www.sqlite.org/syntax/column-def.html), into the given
  /// buffer.
  void writeColumnDefinition(GenerationContext into) {
    into.buffer.write('$escapedName $typeName ');

    if ($customConstraints == null) {
      into.buffer.write($nullable ? 'NULL' : 'NOT NULL');

      if (defaultValue != null) {
        into.buffer.write(' DEFAULT ');

        // we need to write brackets if the default value is not a literal.
        // see https://www.sqlite.org/syntax/column-constraint.html
        final writeBrackets = !defaultValue.isLiteral;

        if (writeBrackets) into.buffer.write('(');
        defaultValue.writeInto(into);
        if (writeBrackets) into.buffer.write(')');
      }

      // these custom constraints refer to builtin constraints from moor
      writeCustomConstraints(into.buffer);
    } else {
      into.buffer.write($customConstraints);
    }
  }

  @visibleForOverriding
  void writeCustomConstraints(StringBuffer into) {}

  /// The sql type name, such as VARCHAR for texts.
  @visibleForOverriding
  String get typeName;

  @override
  void writeInto(GenerationContext context, {bool ignoreEscape = false}) {
    if (context.hasMultipleTables) {
      context.buffer..write(tableName)..write('.');
    }
    context.buffer.write(ignoreEscape ? $name : escapedName);
  }

  /// Checks whether the given value fits into this column. The default
  /// implementation only checks for nullability, but subclasses might enforce
  /// additional checks. For instance, the [GeneratedTextColumn] can verify
  /// that a text has a certain length.
  ///
  /// Note: The behavior of this method was changed in moor 1.5. Before, null
  /// values were interpreted as an absent value during updates or if the
  /// [defaultValue] is set. Verification was skipped for absent values.
  /// This is no longer the case, all null values are assumed to be an sql
  /// `NULL`.
  VerificationResult isAcceptableValue(T value, VerificationMeta meta) {
    final nullOk = $nullable;
    if (!nullOk && value == null) {
      return _invalidNull;
    } else {
      return const VerificationResult.success();
    }
  }

  /// Returns true if this column needs to be set when writing a new row into
  /// a table.
  bool get isRequired {
    return !$nullable && defaultValue == null;
  }
}

class GeneratedTextColumn extends GeneratedColumn<String, StringType>
    implements TextColumn {
  final int minTextLength;
  final int maxTextLength;

  GeneratedTextColumn(
    String name,
    String tableName,
    bool nullable, {
    this.minTextLength,
    this.maxTextLength,
    String $customConstraints,
    Expression<String, StringType> defaultValue,
  }) : super(name, tableName, nullable,
            $customConstraints: $customConstraints, defaultValue: defaultValue);

  @override
  Expression<bool, BoolType> like(String pattern) =>
      LikeOperator(this, Variable<String, StringType>(pattern));

  @override
  final String typeName = 'VARCHAR';

  @override
  VerificationResult isAcceptableValue(String value, VerificationMeta meta) {
    // handle nullability check in common column
    if (value == null) return super.isAcceptableValue(null, meta);

    final length = value.length;
    if (minTextLength != null && minTextLength > length) {
      return VerificationResult.failure(
          'Must at least be $minTextLength characters long.');
    }
    if (maxTextLength != null && maxTextLength < length) {
      return VerificationResult.failure(
          'Must at most be $maxTextLength characters long.');
    }

    return const VerificationResult.success();
  }
}

class GeneratedBoolColumn extends GeneratedColumn<bool, BoolType>
    implements BoolColumn {
  GeneratedBoolColumn(String name, String tableName, bool nullable,
      {String $customConstraints, Expression<bool, BoolType> defaultValue})
      : super(name, tableName, nullable,
            $customConstraints: $customConstraints, defaultValue: defaultValue);

  @override
  final String typeName = 'BOOLEAN';

  @override
  void writeCustomConstraints(StringBuffer into) {
    into.write(' CHECK (${$name} in (0, 1))');
  }
}

class GeneratedIntColumn extends GeneratedColumn<int, IntType>
    with ComparableExpr
    implements IntColumn {
  final bool hasAutoIncrement;

  @override
  final String typeName = 'INTEGER';

  GeneratedIntColumn(
    String name,
    String tableName,
    bool nullable, {
    this.hasAutoIncrement = false,
    String $customConstraints,
    Expression<int, IntType> defaultValue,
  }) : super(name, tableName, nullable,
            $customConstraints: $customConstraints, defaultValue: defaultValue);

  @override
  void writeColumnDefinition(GenerationContext into) {
    // todo make this work with custom constraints, default values, etc.
    if (hasAutoIncrement) {
      into.buffer.write('${$name} $typeName PRIMARY KEY AUTOINCREMENT');
    } else {
      super.writeColumnDefinition(into);
    }
  }

  @override
  bool get isRequired {
    return !hasAutoIncrement && super.isRequired;
  }
}

class GeneratedDateTimeColumn extends GeneratedColumn<DateTime, DateTimeType>
    with ComparableExpr
    implements DateTimeColumn {
  GeneratedDateTimeColumn(
    String $name,
    String tableName,
    bool $nullable, {
    String $customConstraints,
    Expression<DateTime, DateTimeType> defaultValue,
  }) : super($name, tableName, $nullable,
            $customConstraints: $customConstraints, defaultValue: defaultValue);

  @override
  String get typeName => 'INTEGER'; // date-times are stored as unix-timestamps
}

class GeneratedBlobColumn extends GeneratedColumn<Uint8List, BlobType>
    implements BlobColumn {
  GeneratedBlobColumn(String $name, String tableName, bool $nullable,
      {String $customConstraints, Expression<Uint8List, BlobType> defaultValue})
      : super($name, tableName, $nullable,
            $customConstraints: $customConstraints, defaultValue: defaultValue);

  @override
  final String typeName = 'BLOB';
}

class GeneratedRealColumn extends GeneratedColumn<double, RealType>
    with ComparableExpr
    implements RealColumn {
  GeneratedRealColumn(
    String $name,
    String tableName,
    bool $nullable, {
    Expression<double, RealType> defaultValue,
    String $customConstraints,
  }) : super($name, tableName, $nullable,
            defaultValue: defaultValue, $customConstraints: $customConstraints);

  @override
  String get typeName => 'REAL';
}
