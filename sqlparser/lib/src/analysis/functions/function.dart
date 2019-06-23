part of '../analysis.dart';

class SqlFunction with Referencable {
  final String name;

  SqlFunction(this.name);
}

class StaticTypeFunction extends SqlFunction {
  final List<SqlType> inputs;
  final SqlType output;

  StaticTypeFunction(
      {@required String name, @required this.inputs, @required this.output})
      : super(name);
}
