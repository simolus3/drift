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

/// Used internally by drift when calling [SimpleSelectStatement.join].
///
/// You should use [innerJoin], [leftOuterJoin] or [crossJoin] to obtain a
/// [Join] instance.
class Join<T extends HasResultSet, D> extends Component {
  /// The [_JoinType] of this join.
  final _JoinType type;

  /// The [TableInfo] that will be added to the query
  final Table table;

  /// For joins that aren't [_JoinType.cross], contains an additional predicate
  /// that must be matched for the join.
  final Expression<bool>? on;

  /// Whether [table] should appear in the result set (defaults to true).
  /// Default value can be changed by `includeJoinedTableColumns` in
  /// `selectOnly` statements.
  ///
  /// It can be useful to exclude some tables. Sometimes, tables are used in a
  /// join only to run aggregate functions on them.
  final bool? includeInResult;

  /// Constructs a [Join] by providing the relevant fields. [on] is optional for
  /// [_JoinType.cross].
  Join._(this.type, this.table, this.on, {this.includeInResult}) {
    if (table is! ResultSetImplementation<T, D>) {
      throw ArgumentError(
          'Invalid table parameter. You must provide the table reference from '
              'generated database object.',
          'table');
    }
  }

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write(_joinKeywords[type]);
    context.buffer.write(' JOIN ');

    final resultSet = table as ResultSetImplementation<T, D>;
    context.buffer.write(resultSet.tableWithAlias);
    context.watchedTables.add(resultSet);

    if (type != _JoinType.cross) {
      context.buffer.write(' ON ');
      on!.writeInto(context);
    }
  }
}

/// Creates a sql inner join that can be used in [SimpleSelectStatement.join].
///
/// {@template drift_join_include_results}
/// The optional [useColumns] parameter (defaults to true) can be used to
/// exclude the [other] table from the result set. When set to false,
/// [TypedResult.readTable] will return `null` for that table.
/// {@endtemplate}
///
/// See also:
///  - https://drift.simonbinder.eu/docs/advanced-features/joins/#joins
///  - http://www.sqlitetutorial.net/sqlite-inner-join/
Join innerJoin(Table other, Expression<bool> on, {bool? useColumns}) {
  return Join._(_JoinType.inner, other, on, includeInResult: useColumns);
}

/// Creates a sql left outer join that can be used in
/// [SimpleSelectStatement.join].
///
/// {@macro drift_join_include_results}
///
/// See also:
///  - https://drift.simonbinder.eu/docs/advanced-features/joins/#joins
///  - http://www.sqlitetutorial.net/sqlite-left-join/
Join leftOuterJoin(Table other, Expression<bool> on, {bool? useColumns}) {
  return Join._(_JoinType.leftOuter, other, on, includeInResult: useColumns);
}

/// Creates a sql cross join that can be used in
/// [SimpleSelectStatement.join].
///
/// {@macro drift_join_include_results}
///
/// See also:
///  - https://drift.simonbinder.eu/docs/advanced-features/joins/#joins
///  - http://www.sqlitetutorial.net/sqlite-cross-join/
Join crossJoin(Table other, {bool? useColumns}) {
  return Join._(_JoinType.cross, other, null, includeInResult: useColumns);
}
