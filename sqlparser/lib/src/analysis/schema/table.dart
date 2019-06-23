part of '../analysis.dart';

class Table with Referencable {
  final String name;
  final List<Column> columns;

  Table({@required this.name, @required this.columns});
}
