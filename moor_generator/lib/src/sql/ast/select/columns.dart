import 'package:built_value/built_value.dart';

import 'package:moor_generator/src/sql/ast/expressions/expressions.dart';

part 'columns.g.dart';

/// https://www.sqlite.org/syntax/result-column.html
abstract class ResultColumn {}

abstract class ExprResultColumn extends ResultColumn
    implements Built<ExprResultColumn, ExprResultColumnBuilder> {
  Expression get expr;
  @nullable
  String get alias;

  ExprResultColumn._();
  factory ExprResultColumn(Function(ExprResultColumnBuilder builder) updates) =
      _$ExprResultColumn;
}

abstract class StarResultColumn extends ResultColumn
    implements Built<StarResultColumn, StarResultColumnBuilder> {
  /// When non-null, refers to the "table.*" select expression. Otherwise,
  /// refers to all tables in the query (just *).
  @nullable
  String get table;

  StarResultColumn._();
  factory StarResultColumn.from({String table}) =>
      StarResultColumn((b) => b.table = table);

  factory StarResultColumn(Function(StarResultColumnBuilder builder) updates) =
      _$StarResultColumn;
}
