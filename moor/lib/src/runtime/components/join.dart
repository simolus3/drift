import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/expressions/expression.dart';

/// A type for a [Join] (e.g. inner, outer).
enum JoinType {
  /// Perform an inner join, see the [innerJoin] function for details.
  inner,

  /// Perform a (left) outer join, see also [leftOuterJoin]
  leftOuter,

  /// Perform a full cross join, see also [crossJoin].
  cross
}

const Map<JoinType, String> _joinKeywords = {
  JoinType.inner: 'INNER',
  JoinType.leftOuter: 'LEFT OUTER',
  JoinType.cross: 'CROSS',
};

/// Used internally by moor when calling [SimpleSelectStatement.join].
class Join<T extends Table, D extends DataClass> extends Component {
  /// The [JoinType] of this join.
  final JoinType type;

  /// The [TableInfo] that will be added to the query
  final TableInfo<T, D> table;

  /// For joins that aren't [JoinType.cross], contains an additional predicate
  /// that must be matched for the join.
  final Expression<bool, BoolType> on;

  /// Constructs a [Join] by providing the relevant fields. [on] is optional for
  /// [JoinType.cross].
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
Join innerJoin<T extends Table, D extends DataClass>(
    TableInfo<T, D> other, Expression<bool, BoolType> on) {
  return Join(JoinType.inner, other, on);
}

/// Creates a sql left outer join that can be used in
/// [SimpleSelectStatement.join].
///
/// See also:
///  - http://www.sqlitetutorial.net/sqlite-left-join/
Join leftOuterJoin<T extends Table, D extends DataClass>(
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
