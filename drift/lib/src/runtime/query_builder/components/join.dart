part of '../query_builder.dart';

/// A type for a [Join] (e.g. inner, outer).
enum _JoinType {
  /// Perform an inner join, see the [innerJoin] function for details.
  inner('INNER'),

  /// Perform a (left) outer join, see also [leftOuterJoin]
  leftOuter('LEFT OUTER'),

  /// Perform a right outer join, see also [rightOuterJoin].
  rightOuter('RIGHT OUTER'),

  /// Perform a full outer join, see also [fullOuterJoin].
  fullOuter('FULL OUTER'),

  /// Perform a full cross join, see also [crossJoin].
  cross('CROSS');

  final String _keyword;

  const _JoinType(this._keyword);
}

/// Used internally by drift when calling [SimpleSelectStatement.join].
///
/// You should use [innerJoin], [leftOuterJoin] or [crossJoin] to obtain a
/// [Join] instance.
class Join<T extends HasResultSet, D> extends Component {
  /// The [_JoinType] of this join.
  final _JoinType _type;

  /// The [TableInfo] that will be added to the query
  final HasResultSet table;

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
  Join._(this._type, this.table, this.on, {this.includeInResult}) {
    if (table is! ResultSetImplementation<T, D>) {
      throw ArgumentError(
        'Invalid table parameter. You must provide the table reference from '
            'generated database object.',
        'table',
      );
    }
  }

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write(_type._keyword);
    context.buffer.write(' JOIN ');

    final resultSet = table as ResultSetImplementation<T, D>;
    context.writeResultSet(resultSet);

    if (_type != _JoinType.cross) {
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
@pragma('drift:v3-rename', 'Join.inner')
Join innerJoin(HasResultSet other, Expression<bool> on, {bool? useColumns}) {
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
@pragma('drift:v3-rename', 'Join.leftOuter')
Join leftOuterJoin(
  HasResultSet other,
  Expression<bool> on, {
  bool? useColumns,
}) {
  return Join._(_JoinType.leftOuter, other, on, includeInResult: useColumns);
}

/// Creates an SQL right outer join that can be used in
/// [SimpleSelectStatement.join].
///
/// {@macro drift_join_include_results}
@pragma('drift:v3-rename', 'Join.rightOuter')
Join rightOuterJoin(
  HasResultSet other,
  Expression<bool> on, {
  bool? useColumns,
}) {
  return Join._(_JoinType.rightOuter, other, on, includeInResult: useColumns);
}

/// Creates an SQL full outer join that can be used in
/// [SimpleSelectStatement.join].
///
/// {@macro drift_join_include_results}
@pragma('drift:v3-rename', 'Join.fullOuter')
Join fullOuterJoin(
  HasResultSet other,
  Expression<bool> on, {
  bool? useColumns,
}) {
  return Join._(_JoinType.fullOuter, other, on, includeInResult: useColumns);
}

/// Creates a sql cross join that can be used in
/// [SimpleSelectStatement.join].
///
/// {@macro drift_join_include_results}
///
/// See also:
///  - https://drift.simonbinder.eu/docs/advanced-features/joins/#joins
///  - http://www.sqlitetutorial.net/sqlite-cross-join/
@pragma('drift:v3-rename', 'Join.cross')
Join crossJoin(HasResultSet other, {bool? useColumns}) {
  return Join._(_JoinType.cross, other, null, includeInResult: useColumns);
}
