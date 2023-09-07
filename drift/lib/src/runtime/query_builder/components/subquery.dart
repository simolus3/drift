part of '../query_builder.dart';

/// A subquery allows reading from another complex query in a join.
///
/// An existing query can be constructed via [DatabaseConnectionUser.select] or
/// [DatabaseConnectionUser.selectOnly] and then wrapped in [Subquery] to be
/// used in another query.
///
/// For instance, assuming database storing todo items with optional categories
/// (through a reference from todo items to categories), this query uses a
/// subquery to count how many of the top-10 todo items (by length) are in each
/// category:
///
/// ```dart
///  final longestTodos = Subquery(
///   select(todosTable)
///     ..orderBy([(row) => OrderingTerm.desc(row.title.length)])
///     ..limit(10),
///   's',
///  );
///
///  final itemCount = subquery.ref(todosTable.id).count();
///  final query = select(categories).join([
///    innerJoin(
///      longestTodos,
///      subquery.ref(todosTable.category).equalsExp(categories.id),
///      useColumns: false,
///    )])
///      ..groupBy([categories.id])
///      ..addColumns([itemCount]);
/// ```
///
/// Note that the column from the subquery (here, the id of a todo entry) is not
/// directly available in the outer query, it needs to be accessed through
/// [Subquery.ref].
/// Columns added to the top-level query (via [ref]) can be accessed directly
/// through [TypedResult.read]. When columns from a subquery are added to the
/// top-level select as well, [TypedResult.readTable] can be used to read an
/// entire row from the subquery. It returns a nested [TypedResult] for the
/// subquery.
///
/// See also: [subqueryExpression], for subqueries which only return one row and
/// one column.
class Subquery<Row> extends ResultSetImplementation<Subquery, Row>
    implements HasResultSet {
  /// The inner [select] statement of this subquery.
  final BaseSelectStatement<Row> select;
  @override
  final String entityName;

  /// Creates a subqery from the inner [select] statement forming the base of
  /// the subquery and a unique name of this subquery in the statement being
  /// executed.
  Subquery(this.select, this.entityName);

  /// Makes a column from the subquery available to the outer select statement.
  ///
  /// For instance, consider a complex column like `subqueryContentLength` being
  /// added into a subquery:
  ///
  /// ```dart
  ///  final subqueryContentLength = todoEntries.content.length.sum();
  ///  final subquery = Subquery(
  ///    db.selectOnly(todoEntries)
  ///      ..addColumns([todoEntries.category, subqueryContentLength])
  ///      ..groupBy([todoEntries.category]),
  ///    's');
  /// ```
  ///
  /// When the `subqueryContentLength` column gets written, drift will write
  /// the actual `SUM()` expression which is only valid in the subquery itself.
  /// When an outer query joining the subqery wants to read the column, it needs
  /// to refer to that expression by name. This is what [ref] is doing:
  ///
  /// ```dart
  ///  final readableLength = subquery.ref(subqueryContentLength);
  ///  final query = selectOnly(categories)
  ///    ..addColumns([categories.id, readableLength])
  ///    ..join([
  ///      innerJoin(subquery,
  ///          subquery.ref(db.todosTable.category).equalsExp(db.categories.id))
  ///    ]);
  /// ```
  ///
  /// Here, [ref] is called two times: Once to obtain a column selected by the
  /// outer query and once as a join condition.
  ///
  /// [ref] needs to be used every time a column from a subquery is used in an
  /// outer query, regardless of the context.
  Expression<T> ref<T extends Object>(Expression<T> inner) {
    final name = select._nameForColumn(inner);
    if (name == null) {
      throw ArgumentError(
          'The source select statement does not contain that column');
    }

    return columnsByName[name]!.dartCast();
  }

  @override
  late final List<GeneratedColumn<Object>> $columns = [
    for (final (expr, name) in select._expandedColumns)
      GeneratedColumn(
        name,
        entityName,
        true,
        type: expr.driftSqlType,
      ),
  ];

  @override
  late final Map<String, GeneratedColumn<Object>> columnsByName = {
    for (final column in $columns) column.name: column,
  };

  @override
  Subquery get asDslTable => this;

  @override
  DatabaseConnectionUser get attachedDatabase => (select as Query).database;

  @override
  FutureOr<Row> map(Map<String, dynamic> data, {String? tablePrefix}) {
    return select._mapRow(data.withoutPrefix(tablePrefix));
  }
}
