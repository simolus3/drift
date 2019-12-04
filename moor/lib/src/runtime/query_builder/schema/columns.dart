part of '../query_builder.dart';

const VerificationResult _invalidNull = VerificationResult.failure(
    "This column is not nullable and doesn't have a default value. "
    "Null fields thus can't be inserted.");

/// Base class for the implementation of [Column].
abstract class GeneratedColumn<T, S extends SqlType<T>> extends Column<T, S> {
  /// The sql name of this column.
  final String $name;

  /// [$name], but escaped if it's an sql keyword.
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

  /// Used by generated code.
  GeneratedColumn(this.$name, this.tableName, this.$nullable,
      {this.$customConstraints, this.defaultValue});

  /// Writes the definition of this column, as defined
  /// [here](https://www.sqlite.org/syntax/column-def.html), into the given
  /// buffer.
  void writeColumnDefinition(GenerationContext into) {
    into.buffer.write('$escapedName $typeName');

    if ($customConstraints == null) {
      into.buffer.write($nullable ? ' NULL' : ' NOT NULL');

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
    } else if ($customConstraints?.isNotEmpty == true) {
      into.buffer..write(' ')..write($customConstraints);
    }
  }

  /// Writes custom constraints that are supported by the Dart api from moor
  /// (e.g. a `CHECK` for bool columns to ensure that the value is indeed either
  /// 0 or 1).
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

  @override
  int get hashCode => $mrjf($mrjc(tableName.hashCode, $name.hashCode));

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;

    // ignore: test_types_in_equals
    final typedOther = other as GeneratedColumn;
    return typedOther.tableName == tableName && typedOther.$name == $name;
  }
}

/// Implementation for [TextColumn].
class GeneratedTextColumn extends GeneratedColumn<String, StringType>
    implements TextColumn {
  /// Optional. The minimum text length.
  final int minTextLength;

  /// Optional. The maximum text length.
  final int maxTextLength;

  /// Used by generated code.
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

/// Implementation for [BoolColumn].
class GeneratedBoolColumn extends GeneratedColumn<bool, BoolType>
    implements BoolColumn {
  /// Used by generated code
  GeneratedBoolColumn(String name, String tableName, bool nullable,
      {String $customConstraints, Expression<bool, BoolType> defaultValue})
      : super(name, tableName, nullable,
            $customConstraints: $customConstraints, defaultValue: defaultValue);

  @override
  final String typeName = 'INTEGER';

  @override
  void writeCustomConstraints(StringBuffer into) {
    into.write(' CHECK ($escapedName in (0, 1))');
  }
}

/// Implementation for [IntColumn]
class GeneratedIntColumn extends GeneratedColumn<int, IntType>
    implements IntColumn {
  /// Whether this column was declared to be a primary key via a column
  /// constraint. The only way to do this in Dart is with
  /// [IntColumnBuilder.autoIncrement]. In `.moor` files, declaring a column
  /// to be `INTEGER NOT NULL PRIMARY KEY` will set this flag but not
  /// [hasAutoIncrement]. If either field is enabled, this column will be an
  /// alias for the rowid.
  final bool declaredAsPrimaryKey;

  /// Whether this column was declared to be an `AUTOINCREMENT` column, either
  /// with [IntColumnBuilder.autoIncrement] or with an `AUTOINCREMENT` clause
  /// in a `.moor` file.
  final bool hasAutoIncrement;

  @override
  final String typeName = 'INTEGER';

  /// Used by generated code.
  GeneratedIntColumn(
    String name,
    String tableName,
    bool nullable, {
    this.declaredAsPrimaryKey = false,
    this.hasAutoIncrement = false,
    String $customConstraints,
    Expression<int, IntType> defaultValue,
  }) : super(name, tableName, nullable,
            $customConstraints: $customConstraints, defaultValue: defaultValue);

  @override
  void writeCustomConstraints(StringBuffer into) {
    if (hasAutoIncrement) {
      into.write(' PRIMARY KEY AUTOINCREMENT');
    } else if (declaredAsPrimaryKey) {
      into.write(' PRIMARY KEY');
    }
  }

  @override
  bool get isRequired {
    final aliasForRowId = declaredAsPrimaryKey || hasAutoIncrement;
    return !aliasForRowId && super.isRequired;
  }
}

/// Implementation for [DateTimeColumn].
class GeneratedDateTimeColumn extends GeneratedColumn<DateTime, DateTimeType>
    implements DateTimeColumn {
  /// Used by generated code.
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

/// Implementation for [BlobColumn]
class GeneratedBlobColumn extends GeneratedColumn<Uint8List, BlobType>
    implements BlobColumn {
  /// Used by generated code.
  GeneratedBlobColumn(String $name, String tableName, bool $nullable,
      {String $customConstraints, Expression<Uint8List, BlobType> defaultValue})
      : super($name, tableName, $nullable,
            $customConstraints: $customConstraints, defaultValue: defaultValue);

  @override
  final String typeName = 'BLOB';
}

/// Implementation for [RealColumn]
class GeneratedRealColumn extends GeneratedColumn<double, RealType>
    implements RealColumn {
  /// Used by generated code
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
