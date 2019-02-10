import 'package:meta/meta.dart';
import 'package:sally/sally.dart';

abstract class Table {
  const Table();

  @visibleForOverriding
  String get tableName => null;

  @visibleForOverriding
  // todo allow custom primary key
  PrimaryKey get primaryKey => null;

  @protected
  IntColumnBuilder integer() => null;
  @protected
  TextColumnBuilder text() => null;
  @protected
  BoolColumnBuilder boolean() => null;
}

class PrimaryKey {}

/// A class to to be used as an annotation on [Table] classes to customize the
/// name for the data class that will be generated for the table class. The data
/// class is a dart object that will be used to represent a row in the table.
/// {@template sally:custom_data_class}
/// By default, sally will attempt to use the singular form of the table name
/// when naming data classes (e.g. a table named "Users" will generate a data
/// class called "User"). However, this doesn't work for irregular plurals and
/// you might want to choose a different name, for which this annotation can be
/// used.
/// {@template}
class DataClassName {
  final String name;

  /// Customize the data class name for a given table.
  /// {@macro sally:custom_data_class}
  const DataClassName(this.name);
}
