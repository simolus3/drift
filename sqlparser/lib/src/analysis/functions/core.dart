part of '../analysis.dart';

// https://www.sqlite.org/lang_corefunc.html
final abs = _AbsFunction();

class _AbsFunction extends SqlFunction {
  _AbsFunction() : super('ABS');

  @override
  void register(AnalysisContext context, Typeable functionCall,
      List<Typeable> parameters) {}
}

final coreFunctions = <SqlFunction>[
  abs,
];
