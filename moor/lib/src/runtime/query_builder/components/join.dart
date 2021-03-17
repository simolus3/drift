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
  final Expression<bool?>? on;

  /// Whether [table] should appear in the result set (defaults to true).
  ///
  /// It can be useful to exclude some tables. Sometimes, tables are used in a
  /// join only to run aggregate functions on them.
  final bool includeInResult;

  /// Constructs a [Join] by providing the relevant fields. [on] is optional for
  /// [_JoinType.cross].
  Join._(this.type, this.table, this.on, {bool? includeInResult})
      : includeInResult = includeInResult ?? true;

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write(_joinKeywords[type]);
    context.buffer.write(' JOIN ');

    context.buffer.write(table.tableWithAlias);

    if (type != _JoinType.cross) {
      context.buffer.write(' ON ');
      on!.writeInto(context);
    }
  }
}

/// Creates a sql inner join that can be used in [SimpleSelectStatement.join].
///
/// {@template moor_join_include_results}
/// The optional [useColumns] parameter (defaults to true) can be used to
/// exclude the [other] table from the result set. When set to false,
/// [TypedResult.readTable] will return `null` for that table.
/// {@endtemplate}
///
/// See also:
///  - https://moor.simonbinder.eu/docs/advanced-features/joins/#joins
///  - http://www.sqlitetutorial.net/sqlite-inner-join/
Join innerJoin<T extends Table, D extends DataClass>(
    TableInfo<T, D> other, Expression<bool?> on,
    {bool? useColumns}) {
  return Join._(_JoinType.inner, other, on, includeInResult: useColumns);
}

/// Creates a sql left outer join that can be used in
/// [SimpleSelectStatement.join].
///
/// {@macro moor_join_include_results}
///
/// See also:
///  - https://moor.simonbinder.eu/docs/advanced-features/joins/#joins
///  - http://www.sqlitetutorial.net/sqlite-left-join/
Join leftOuterJoin<T extends Table, D extends DataClass>(
    TableInfo<T, D> other, Expression<bool?> on,
    {bool? useColumns}) {
  return Join._(_JoinType.leftOuter, other, on, includeInResult: useColumns);
}

/// Creates a sql cross join that can be used in
/// [SimpleSelectStatement.join].
///
/// {@macro moor_join_include_results}
///
/// See also:
///  - https://moor.simonbinder.eu/docs/advanced-features/joins/#joins
///  - http://www.sqlitetutorial.net/sqlite-cross-join/
Join crossJoin<T, D>(TableInfo other, {bool? useColumns}) {
  return Join._(_JoinType.cross, other, null, includeInResult: useColumns);
}
