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

class ColumnBuilder<T> {
  /// By default, the field name will be used as the column name, e.g.
  /// `IntColumn get id = integer()` will have "id" as its associated name. To change
  /// this, use `IntColumn get id = integer((c) => c.named('user_id'))`.
  ColumnBuilder<T> named(String name) => this;
  ColumnBuilder<T> primaryKey() => this;
//  ColumnBuilder<T> references<Table>(Column<T> extractor(Table table)) => this;

  Column<T, dynamic> call() => null;
}

class IntColumnBuilder extends ColumnBuilder<int> {
  @override
  IntColumnBuilder named(String name) => this;
  @override
  IntColumnBuilder primaryKey() => this;
//  @override
//  IntColumnBuilder references<Table>(Column<int> extractor(Table table)) => this;
  @override
  IntColumn call() => null;

  IntColumnBuilder autoIncrement() => this;
}

class BoolColumnBuilder extends ColumnBuilder<bool> {
  @override
  BoolColumnBuilder named(String name) => this;
  @override
  BoolColumnBuilder primaryKey() => this;
//  @override
//  BoolColumnBuilder references<Table>(Column<bool> extractor(Table table)) => this;
  @override
  BoolColumn call() => null;
}

class TextColumnBuilder extends ColumnBuilder<String> {
  @override
  TextColumnBuilder named(String name) => this;
  @override
  TextColumnBuilder primaryKey() => this;
//  @override
//  TextColumnBuilder references<Table>(Column<String> extractor(Table table)) => this;
  @override
  TextColumn call() => null;

  TextColumnBuilder withLength({int min, int max}) => this;
}
