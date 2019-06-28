part of '../analysis.dart';

abstract class Column with Referencable implements Typeable {
  String get name;

  const Column();
}

class TableColumn extends Column {
  @override
  final String name;
  final ResolvedType type;

  const TableColumn(this.name, this.type);
}

class ExpressionColumn extends Column {
  @override
  final String name;
  final Expression expression;

  ExpressionColumn({@required this.name, this.expression});
}
