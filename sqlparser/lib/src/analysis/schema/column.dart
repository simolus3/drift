part of '../analysis.dart';

abstract class Column with Referencable, Typeable {
  String get name;
}

class TableColumn extends Column {
  @override
  final String name;

  TableColumn(this.name);
}

class ExpressionColumn extends Column {
  @override
  final String name;
  final Expression expression;

  ExpressionColumn({@required this.name, this.expression});
}
