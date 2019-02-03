export 'package:sally/src/queries/generation_context.dart';
export 'package:sally/src/queries/expressions/limit.dart';
export 'package:sally/src/queries/expressions/variable.dart';
export 'package:sally/src/queries/expressions/where.dart';

import 'package:sally/src/queries/expressions/expressions.dart';

abstract class SqlExpression {
  void writeInto(GenerationContext context);
}
