// todo more datatypes (at least DateTime and Binary blobs)!
// todo nullability

import 'package:sally/src/runtime/expressions/expression.dart';
import 'package:sally/src/runtime/sql_types.dart';

abstract class Column<T, S extends SqlType<T>> extends Expression<S> {
  Expression<BoolType> equalsExp(Expression<S> compare);
  Expression<BoolType> equals(T compare);
}

abstract class IntColumn extends Column<int, IntType> {
  Expression<BoolType> isBiggerThan(int i);
  Expression<BoolType> isSmallerThan(int i);
}

abstract class BoolColumn extends Column<bool, BoolType> {}

abstract class TextColumn extends Column<String, StringType> {
  Expression<BoolType> like(String regex);
}

class ColumnBuilder<Builder, ResultColumn> {
  /// By default, the field name will be used as the column name, e.g.
  /// `IntColumn get id = integer()` will have "id" as its associated name. To change
  /// this, use `IntColumn get id = integer((c) => c.named('user_id'))`.
  Builder named(String name) => null;
  Builder primaryKey() => null;

  ResultColumn call() => null;
}

class IntColumnBuilder extends ColumnBuilder<IntColumnBuilder, IntColumn> {
  IntColumnBuilder autoIncrement() => this;
}

class BoolColumnBuilder extends ColumnBuilder<BoolColumnBuilder, BoolColumn> {}

class TextColumnBuilder extends ColumnBuilder<TextColumnBuilder, TextColumn> {
  TextColumnBuilder withLength({int min, int max}) => this;
}
