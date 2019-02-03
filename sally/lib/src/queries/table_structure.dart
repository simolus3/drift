import 'package:sally/sally.dart';
import 'package:sally/src/dsl/columns.dart';
import 'package:sally/src/queries/expressions/expressions.dart';
import 'package:sally/src/queries/expressions/variable.dart';
import 'package:sally/src/queries/generation_context.dart';
import 'package:sally/src/queries/predicates/numbers.dart';
import 'package:sally/src/queries/predicates/predicate.dart';
import 'package:sally/src/queries/predicates/text.dart';
import 'package:sally/src/queries/statement/delete.dart';
import 'package:sally/src/queries/statement/select.dart';

abstract class TableStructure<UserSpecifiedTable, ResolvedType> {
  QueryExecutor executor;

  UserSpecifiedTable get asTable;
  String get sqlTableName;

  ResolvedType parse(Map<String, dynamic> result);

  SelectStatement<UserSpecifiedTable, ResolvedType> select() =>
      SelectStatement<UserSpecifiedTable, ResolvedType>(this);

  DeleteStatement<UserSpecifiedTable> delete() => DeleteStatement(this);
}

class StructuredColumn<T> implements SqlExpression, Column<T> {
  final String sqlName;

  StructuredColumn(this.sqlName);

  @override
  void writeInto(GenerationContext context) {
    // todo table name lookup, as-expressions etc?
    context.buffer.write(sqlName);
    context.buffer.write(' ');
  }

  @override
  Predicate equals(T compare) => EqualityPredicate(this, Variable(compare));
}

class StructuredIntColumn extends StructuredColumn<int> implements IntColumn {
  StructuredIntColumn(String sqlName) : super(sqlName);

  @override
  Predicate isBiggerThan(int i) =>
      NumberComparisonPredicate(this, ComparisonOperator.more, Variable(i));
  @override
  Predicate isSmallerThan(int i) =>
      NumberComparisonPredicate(this, ComparisonOperator.less, Variable(i));
}

class StructuredBoolColumn extends StructuredColumn<bool>
    implements BoolColumn {
  StructuredBoolColumn(String sqlName) : super(sqlName);

  // Booleans will be stored as integers, where 0 means false and 1 means true

  @override
  Predicate isFalse() {
    return EqualityPredicate(this, HardcodedConstant(0));
  }
  @override
  Predicate isTrue() {
    return EqualityPredicate(this, HardcodedConstant(1));
  }
}

class StructuredTextColumn extends StructuredColumn<String>
    implements TextColumn {
  StructuredTextColumn(String sqlName) : super(sqlName);

  @override
  Predicate like(String regex) => LikePredicate(this, Variable(regex));
}
