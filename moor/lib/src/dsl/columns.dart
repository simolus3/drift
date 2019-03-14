import 'dart:typed_data';

import 'package:moor/moor.dart';
import 'package:moor/src/runtime/expressions/expression.dart';

abstract class Column<T, S extends SqlType<T>> extends Expression<T, S> {}

abstract class IntColumn extends Column<int, IntType> implements IntExpression {
}

/// A column that stores boolean values. Booleans will be stored as an integer
/// that can either be 0 (false) or 1 (true).
abstract class BoolColumn extends Column<bool, BoolType> {}

/// A column that stores text.
abstract class TextColumn extends Column<String, StringType> {
  /// Whether this column matches the given pattern. For details on what patters
  /// are valid and how they are interpreted, check out
  /// [this tutorial](http://www.sqlitetutorial.net/sqlite-like/).
  Expression<bool, BoolType> like(String regex);
}

/// A column that stores a [DateTime]. Times will be stored as unix timestamp
/// and will thus have a second accuracy.
abstract class DateTimeColumn extends Column<DateTime, DateTimeType> {}

/// A column that stores arbitrary blobs of data as a [Uint8List].
abstract class BlobColumn extends Column<Uint8List, BlobType> {}

/// A column builder is used to specify which columns should appear in a table.
/// All of the methods defined in this class and its subclasses are not meant to
/// be called at runtime. Instead, moor_generator will take a look at your
/// source code (specifically, it will analyze which of the methods you use) to
/// figure out the column structure of a table.
class ColumnBuilder<Builder, ResultColumn> {
  /// By default, the field name will be used as the column name, e.g.
  /// `IntColumn get id = integer()` will have "id" as its associated name.
  /// Columns made up of multiple words are expected to be in camelCase and will
  /// be converted to snake_case (e.g. a getter called accountCreationDate will
  /// result in an SQL column called account_creation_date).
  /// To change this default behavior, use something like
  /// `IntColumn get id = integer((c) => c.named('user_id'))`.
  Builder named(String name) => null;

  /// Marks this column as nullable. Nullable columns should not appear in a
  /// primary key. Columns are non-null by default.
  Builder nullable() => null;

  /// Tells moor to write a custom constraint after this column definition when
  /// writing this column, for instance in a CREATE TABLE statement.
  ///
  /// When no custom constraint is set, columns will be written like this:
  /// `name TYPE NULLABILITY NATIVE_CONSTRAINTS`. Native constraints are used to
  /// enforce that booleans are either 0 or 1 (e.g.
  /// `field BOOLEAN NOT NULL CHECK (field in (0, 1)`). Auto-Increment
  /// columns also make use of the native constraints.
  /// If [customConstraint] has been called, the nullability information and
  /// native constraints will never be written. Instead, they will be replaced
  /// with the [constraint]. For example, if you call
  /// `customConstraint('UNIQUE')` on an [IntColumn] named "votes", the
  /// generated column definition will be `votes INTEGER UNIQUE`. Notice how the
  /// nullability information is lost - you'll have to include it in
  /// [constraint] if that is desired.
  ///
  /// This can be used to implement constraints that moor does not (yet)
  /// support (e.g. unique keys, etc.). If you've found a common use-case for
  /// this, it should be considered a limitation of moor itself. Please feel
  /// free to open an issue at https://github.com/simolus3/moor/issues/new to
  /// report that.
  ///
  /// See also:
  /// - https://www.sqlite.org/syntax/column-constraint.html
  /// - [GeneratedColumn.writeCustomConstraints]
  Builder customConstraint(String constraint) => null;

  /// Turns this column builder into a column. This method won't actually be
  /// called in your code. Instead, moor_generator will take a look at your
  /// source code to figure out your table structure.
  ResultColumn call() => null;
}

class IntColumnBuilder extends ColumnBuilder<IntColumnBuilder, IntColumn> {
  /// Enables auto-increment for this column, which will also make this column
  /// the primary key of the table.
  IntColumnBuilder autoIncrement() => this;
}

class BoolColumnBuilder extends ColumnBuilder<BoolColumnBuilder, BoolColumn> {}

class BlobColumnBuilder extends ColumnBuilder<BlobColumnBuilder, BlobColumn> {}

class TextColumnBuilder extends ColumnBuilder<TextColumnBuilder, TextColumn> {
  /// Puts a constraint on the minimum and maximum length of text that can be
  /// stored in this column (will be validated whenever this column is updated
  /// or a value is inserted). If [min] is not null and one tries to write a
  /// string so that [String.length] is smaller than [min], the query will throw
  /// an exception when executed and no data will be written. The same applies
  /// for [max].
  TextColumnBuilder withLength({int min, int max}) => this;
}

class DateTimeColumnBuilder
    extends ColumnBuilder<DateTimeColumnBuilder, DateTimeColumn> {}
