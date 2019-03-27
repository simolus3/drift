import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/expressions/expression.dart';
import 'package:moor/src/runtime/expressions/text.dart';
import 'package:moor/src/runtime/expressions/variables.dart';
import 'package:moor/src/types/sql_types.dart';

/// Base class for the implementation of [Column].
abstract class GeneratedColumn<T, S extends SqlType<T>> extends Column<T, S> {
  /// The sql name of this column.
  final String $name;

  /// Whether null values are allowed for this column.
  final bool $nullable;

  /// If custom constraints have been specified for this column via
  /// [ColumnBuilder.customConstraint], these are kept here. Otherwise, this
  /// field is going to be null.
  final String $customConstraints;

  GeneratedColumn(this.$name, this.$nullable, {this.$customConstraints});

  /// Writes the definition of this column, as defined
  /// [here](https://www.sqlite.org/syntax/column-def.html), into the given
  /// buffer.
  void writeColumnDefinition(StringBuffer into) {
    into.write('${$name} $typeName ');

    if ($customConstraints == null) {
      into.write($nullable ? 'NULL' : 'NOT NULL');
      // these custom constraints refer to builtin constraints from moor
      writeCustomConstraints(into);
    } else {
      into.write($customConstraints);
    }
  }

  @visibleForOverriding
  void writeCustomConstraints(StringBuffer into) {}

  /// The sql type name, such as VARCHAR for texts.
  @visibleForOverriding
  String get typeName;

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write($name);
  }

  /// Checks whether the given value fits into this column. The default
  /// implementation checks whether the value is not null, as null values are
  /// only allowed for updates or if the column is nullable.
  /// If [duringInsert] is true, the method should check whether the value is
  /// suitable for a new row that is being inserted. If it's false, we the
  /// method should check whether the value is valid for an update. Null values
  /// should always be accepted for updates, as the describe a value that should
  /// not be replaced.
  bool isAcceptableValue(T value, bool duringInsert) =>
      ($nullable || !duringInsert) || value != null;
}

class GeneratedTextColumn extends GeneratedColumn<String, StringType>
    implements TextColumn {
  final int minTextLength;
  final int maxTextLength;

  GeneratedTextColumn(String name, bool nullable,
      {this.minTextLength, this.maxTextLength, String $customConstraints})
      : super(name, nullable, $customConstraints: $customConstraints);

  @override
  Expression<bool, BoolType> like(String pattern) =>
      LikeOperator(this, Variable<String, StringType>(pattern));

  @override
  final String typeName = 'VARCHAR';

  @override
  bool isAcceptableValue(String value, bool duringInsert) {
    final nullOk = !duringInsert || $nullable;
    if (value == null) return nullOk;

    final length = value.length;
    if (minTextLength != null && minTextLength > length) return false;
    if (maxTextLength != null && maxTextLength < length) return false;

    return true;
  }
}

class GeneratedBoolColumn extends GeneratedColumn<bool, BoolType>
    implements BoolColumn {
  GeneratedBoolColumn(String name, bool nullable, {String $customConstraints})
      : super(name, nullable, $customConstraints: $customConstraints);

  @override
  final String typeName = 'BOOLEAN';

  @override
  void writeCustomConstraints(StringBuffer into) {
    into.write(' CHECK (${$name} in (0, 1))');
  }

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('(');
    context.buffer.write($name);
    context.buffer.write(' = 1)');
  }
}

class GeneratedIntColumn extends GeneratedColumn<int, IntType>
    with ComparableExpr
    implements IntColumn {
  final bool hasAutoIncrement;

  @override
  final String typeName = 'INTEGER';

  GeneratedIntColumn(String name, bool nullable,
      {this.hasAutoIncrement = false, String $customConstraints})
      : super(name, nullable, $customConstraints: $customConstraints);

  @override
  void writeColumnDefinition(StringBuffer into) {
    if (hasAutoIncrement) {
      into.write('${$name} $typeName PRIMARY KEY AUTOINCREMENT');
    } else {
      super.writeColumnDefinition(into);
    }
  }

  @override
  bool isAcceptableValue(int value, bool duringInsert) =>
      hasAutoIncrement || super.isAcceptableValue(value, duringInsert);
}

class GeneratedDateTimeColumn extends GeneratedColumn<DateTime, DateTimeType>
    implements DateTimeColumn {
  GeneratedDateTimeColumn(String $name, bool $nullable,
      {String $customConstraints})
      : super($name, $nullable, $customConstraints: $customConstraints);

  @override
  String get typeName => 'INTEGER'; // date-times are stored as unix-timestamps
}

class GeneratedBlobColumn extends GeneratedColumn<Uint8List, BlobType>
    implements BlobColumn {
  GeneratedBlobColumn(String $name, bool $nullable, {String $customConstraints})
      : super($name, $nullable, $customConstraints: $customConstraints);

  @override
  final String typeName = 'BLOB';
}
