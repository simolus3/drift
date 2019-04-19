import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/expressions/expression.dart';

enum JoinType { inner, leftOuter, cross }

const Map<JoinType, String> _joinKeywords = {
  JoinType.inner: 'INNER',
  JoinType.leftOuter: 'LEFT OUTER',
  JoinType.cross: 'CROSS',
};

class Join<T extends Table, D> extends Component {
  final JoinType type;
  final TableInfo<T, D> table;
  final Expression<bool, BoolType> on;

  Join(this.type, this.table, this.on);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write(_joinKeywords[type]);
    context.buffer.write(' JOIN ');

    context.buffer.write(table.tableWithAlias);

    if (type != JoinType.cross) {
      context.buffer.write(' ON ');
      on.writeInto(context);
    }
  }
}

/// Creates a sql inner join that can be used in [SimpleSelectStatement.join].
///
/// See also:
///  - http://www.sqlitetutorial.net/sqlite-inner-join/
Join innerJoin<T extends Table, D>(
    TableInfo<T, D> other, Expression<bool, BoolType> on) {
  return Join(JoinType.inner, other, on);
}

/// Creates a sql left outer join that can be used in
/// [SimpleSelectStatement.join].
///
/// See also:
///  - http://www.sqlitetutorial.net/sqlite-left-join/
Join leftOuterJoin<T extends Table, D>(
    TableInfo<T, D> other, Expression<bool, BoolType> on) {
  return Join(JoinType.leftOuter, other, on);
}

/// Creates a sql cross join that can be used in
/// [SimpleSelectStatement.join].
///
/// See also:
///  - http://www.sqlitetutorial.net/sqlite-cross-join/
Join crossJoin<T, D>(TableInfo other) {
  return Join(JoinType.cross, other, null);
}
