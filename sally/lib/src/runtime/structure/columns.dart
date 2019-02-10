import 'package:meta/meta.dart';
import 'package:sally/sally.dart';
import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';
import 'package:sally/src/runtime/expressions/text.dart';
import 'package:sally/src/runtime/expressions/variables.dart';
import 'package:sally/src/runtime/sql_types.dart';

abstract class GeneratedColumn<T, S extends SqlType<T>> extends Column<T, S> {
  final String $name;
  final bool $nullable;

  GeneratedColumn(this.$name, this.$nullable);

  /// Writes the definition of this column, as defined
  /// [here](https://www.sqlite.org/syntax/column-def.html), into the given
  /// buffer.
  void writeColumnDefinition(StringBuffer into) {
    into
      ..write('${$name} $typeName ')
      ..write($nullable ? 'NULL' : 'NOT NULL')
      ..write(' ');
    writeCustomConstraints(into);
  }

  @visibleForOverriding
  void writeCustomConstraints(StringBuffer into) {}
  @visibleForOverriding
  String get typeName;

  @override
  Expression<BoolType> equalsExp(Expression<S> compare) =>
      Comparison.equal(this, compare);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write($name);
  }

  @override
  Expression<BoolType> equals(T compare) => equalsExp(Variable<T, S>(compare));
}

class GeneratedTextColumn extends GeneratedColumn<String, StringType>
    implements TextColumn {
  GeneratedTextColumn(String name, bool nullable) : super(name, nullable);

  @override
  Expression<BoolType> like(String regex) =>
      LikeOperator(this, Variable<String, StringType>(regex));

  @override
  final String typeName = 'VARCHAR';
}

class GeneratedBoolColumn extends GeneratedColumn<bool, BoolType>
    implements BoolColumn {
  GeneratedBoolColumn(String name, bool nullable) : super(name, nullable);

  @override
  final String typeName = 'BOOLEAN';

  @override
  void writeCustomConstraints(StringBuffer into) {
    into.write('CHECK (${$name} in (0, 1))');
  }

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('(');
    context.buffer.write($name);
    context.buffer.write(' = 1)');
  }
}

class GeneratedIntColumn extends GeneratedColumn<int, IntType>
    implements IntColumn {
  final bool hasAutoIncrement;

  @override
  final String typeName = 'INTEGER';

  GeneratedIntColumn(String name, bool nullable,
      {this.hasAutoIncrement = false})
      : super(name, nullable);

  @override
  Expression<BoolType> isBiggerThan(int i) =>
      Comparison(this, ComparisonOperator.more, Variable<int, IntType>(i));

  @override
  Expression<BoolType> isSmallerThan(int i) =>
      Comparison(this, ComparisonOperator.less, Variable<int, IntType>(i));
}
