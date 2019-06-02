import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:moor_generator/src/sql/ast/expressions/expressions.dart';
import 'columns.dart';

part 'select.g.dart';

abstract class SelectStatement
    implements Built<SelectStatement, SelectStatementBuilder> {
  BuiltList<ResultColumn> get columns;
  BuiltList<SelectTarget> get from;
  @nullable
  Expression get where;
  @nullable
  Limit get limit;

  SelectStatement._();
  factory SelectStatement(void Function(SelectStatementBuilder) builder) =
      _$SelectStatement;
}

/// Anything that can appear behind a "FROM" clause in a select statement.
abstract class SelectTarget {}

abstract class TableTarget implements Built<TableTarget, TableTargetBuilder> {
  String get table;

  TableTarget._();
  factory TableTarget(void Function(TableTargetBuilder) builder) =
      _$TableTarget;
}

abstract class Limit implements Built<Limit, LimitBuilder> {
  Expression get amount;
  @nullable
  Expression get offset;

  Limit._();
  factory Limit(void Function(LimitBuilder) builder) = _$Limit;
}
