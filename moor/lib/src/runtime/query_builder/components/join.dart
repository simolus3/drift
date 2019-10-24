part of '../query_builder.dart';

/// A type for a [Join] (e.g. inner, outer).
enum _JoinType {
  /// Perform an inner join, see the [innerJoin] function for details.
  inner,

  /// Perform a (left) outer join, see also [leftOuterJoin]
  leftOuter,

  /// Perform a full cross join, see also [crossJoin].
  cross
}

const Map<_JoinType, String> _joinKeywords = {
  _JoinType.inner: 'INNER',
  _JoinType.leftOuter: 'LEFT OUTER',
  _JoinType.cross: 'CROSS',
};

/// Used internally by moor when calling [SimpleSelectStatement.join].
///
/// You should use [innerJoin], [leftOuterJoin] or [crossJoin] to obtain a
/// [Join] instance.
class Join<T extends Table, D extends DataClass> extends Component {
  /// The [_JoinType] of this join.
  final _JoinType type;

  /// The [TableInfo] that will be added to the query
  final TableInfo<T, D> table;

  /// For joins that aren't [_JoinType.cross], contains an additional predicate
  /// that must be matched for the join.
  final Expression<bool, BoolType> on;

  /// Constructs a [Join] by providing the relevant fields. [on] is optional for
  /// [_JoinType.cross].
  Join._(this.type, this.table, this.on);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write(_joinKeywords[type]);
    context.buffer.write(' JOIN ');

    context.buffer.write(table.tableWithAlias);

    if (type != _JoinType.cross) {
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
  return Join._(_JoinType.inner, other, on);
}

/// Creates a sql left outer join that can be used in
/// [SimpleSelectStatement.join].
///
/// See also:
///  - http://www.sqlitetutorial.net/sqlite-left-join/
Join leftOuterJoin<T extends Table, D extends DataClass>(
    TableInfo<T, D> other, Expression<bool, BoolType> on) {
  return Join._(_JoinType.leftOuter, other, on);
}

/// Creates a sql cross join that can be used in
/// [SimpleSelectStatement.join].
///
/// See also:
///  - http://www.sqlitetutorial.net/sqlite-cross-join/
Join crossJoin<T, D>(TableInfo other) {
  return Join._(_JoinType.cross, other, null);
}
