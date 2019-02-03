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
