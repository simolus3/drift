part of '../analysis.dart';

abstract class SqlFunction with Referencable, VisibleToChildren {
  final String name;

  SqlFunction(this.name);

  void register(AnalysisContext context, Typeable functionCall,
      List<Typeable> parameters);
}

/*class StaticTypeFunction extends SqlFunction {
  final List<SqlType> inputs;
  final SqlType output;

  StaticTypeFunction(
      {@required String name, @required this.inputs, @required this.output})
      : super(name);
}*/
