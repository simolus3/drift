import 'dart:math';
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

part 'composer.dart';
part 'filter.dart';
part 'join.dart';
part 'ordering.dart';

/// Defines a class that holds the state for a [BaseTableManager]
class TableManagerState<
    DB extends GeneratedDatabase,
    T extends Table,
    DT extends DataClass,
    FS extends FilterComposer<DB, T>,
    OS extends OrderingComposer<DB, T>> {
  /// The database that the query will be executed on
  final DB db;

  /// The table that the query will be executed on
  final T table;

  /// The expression that will be applied to the query
  final Expression<bool>? filter;

  /// A set of [OrderingBuilder] which will be used to apply
  /// [OrderingTerm]s to the statement when it's eventually built
  final Set<OrderingBuilder> orderingBuilders;

  /// A set of [JoinBuilder] which will be used to create [Join]s
  /// that will be applied to the build statement
  final Set<JoinBuilder> joinBuilders;

  /// Whether the query should return distinct results
  final bool? distinct;

  /// If set, the maximum number of rows that will be returned
  final int? limit;

  /// If set, the number of rows that will be skipped
  final int? offset;

  /// The [FilterComposer] for this [TableManagerState]
  /// This class will be used to create filtering [Expression]s
  /// which will be applied to the statement when its eventually created
  final FS filteringComposer;

  /// The [OrderingComposer] for this [TableManagerState]
  /// This class will be used to create [OrderingTerm]s
  /// which will be applied to the statement when its eventually created
  final OS orderingComposer;

  /// Defines a class which holds the state for a table manager
  /// It contains the database instance, the table instance, and any filters/orderings that will be applied to the query
  /// This is held in a seperate class than the [BaseTableManager] so that the state can be passed down from the root manager to the lower level managers
  TableManagerState({
    required this.db,
    required this.table,
    required this.filteringComposer,
    required this.orderingComposer,
    this.filter,
    this.distinct,
    this.limit,
    this.offset,
    Set<OrderingBuilder>? orderingTerms,
    Set<JoinBuilder>? joinBuilders,
  })  : orderingBuilders = orderingTerms ?? {},
        joinBuilders = joinBuilders ?? {};

  /// Copy this state with the given values
  TableManagerState<DB, T, DT, FS, OS> copyWith({
    bool? distinct,
    int? limit,
    int? offset,
    Expression<bool>? filter,
    Set<OrderingBuilder>? orderingTerms,
    Set<JoinBuilder>? joinBuilders,
  }) {
    return TableManagerState(
      db: db,
      table: table,
      filteringComposer: filteringComposer,
      orderingComposer: orderingComposer,
      filter: filter ?? this.filter,
      joinBuilders: joinBuilders ?? this.joinBuilders,
      orderingTerms: orderingTerms ?? this.orderingBuilders,
      distinct: distinct ?? this.distinct,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  /// Helper for getting the table that's casted as a TableInfo
  /// This is needed due to dart's limitations with generics
  TableInfo<T, DT> get _tableAsTableInfo => table as TableInfo<T, DT>;

  /// Builds a joined  select statement, should be used when joins are present
  /// Will order, filter, and limit the statement using the state
  JoinedSelectStatement _buildJoinedSelectStatement() {
    // Build the joins
    final joins = joinBuilders.map((e) => e.buildJoin()).toList();

    // Create the joined statement
    final statement =
        db.select(_tableAsTableInfo, distinct: distinct ?? false).join(joins);

    // Apply the expression to the statement
    if (filter != null) {
      statement.where(filter!);
    }

    // Add orderings
    statement.orderBy(orderingBuilders.map((e) => e.buildTerm()).toList());

    // Set the limit and offset
    if (limit != null) {
      statement.limit(limit!, offset: offset);
    }
    return statement;
  }

  /// Builds a simple select statement, this should be used when there are no joins
  /// Will order, filter, and limit the statement using the state
  SimpleSelectStatement<T, DT> _buildSimpleSelectStatement() {
    // Create the statement
    final statement = db.select(_tableAsTableInfo, distinct: distinct ?? false);

    // Apply the expression to the statement
    if (filter != null) {
      statement.where((_) => filter!);
    }

    // Add orderings
    statement
        .orderBy(orderingBuilders.map((e) => (_) => e.buildTerm()).toList());

    // Set the limit and offset
    if (limit != null) {
      statement.limit(limit!, offset: offset);
    }
    return statement;
  }

  /// Build a select statement based on the manager state
  Selectable<DT> buildSelectStatement() {
    if (joinBuilders.isEmpty) {
      return _buildSimpleSelectStatement();
    } else {
      return _buildJoinedSelectStatement()
          .map((p0) => p0.readTable(_tableAsTableInfo));
    }
  }

  /// Build a delete statement based on the manager state
  // DeleteStatement buildDeleteStatement() {
  //   // Being that drift doesnt support joins on deletes, if there are any joins we will use 2 queries
  //   final DeleteStatement deleteStatement;
  //   // Check if there are any joins
  //   if (_joins.isEmpty) {
  //     // If there are no joins, we can just use a single delete statement
  //     deleteStatement = db.delete(_tableAsTableInfo);
  //     if (filter?.expression != null) {
  //       deleteStatement.where((_) => filter!.expression);
  //     }
  //   } else {
  //     // If there are joins, we need to use a subquery to get the rowIds
  //     final selectOnlyRowIdStatement =
  //         _buildJoinedStatement(onlyWithRowId: true);
  //     deleteStatement = db.delete(_tableAsTableInfo)
  //       ..where(
  //           (_) => _tableAsTableInfo.rowId.isInQuery(selectOnlyRowIdStatement));
  //   }
  //   return deleteStatement;
  // }
}

/// Defines the base class for a table manager
@internal
abstract class BaseTableManager<
    DB extends GeneratedDatabase,
    T extends TableInfo,
    DT extends DataClass,
    FS extends FilterComposer<DB, T>,
    OS extends OrderingComposer<DB, T>> {
  /// The state for this manager
  final TableManagerState<DB, T, DT, FS, OS> state;

  /// Create a new [BaseTableManager] instance
  BaseTableManager(this.state);
}

/// Defines the top level manager for a table
abstract class RootTableManager<
        DB extends GeneratedDatabase,
        T extends TableInfo,
        D extends DataClass,
        FS extends FilterComposer<DB, T>,
        OS extends OrderingComposer<DB, T>>
    extends BaseTableManager<DB, T, D, FS, OS> {
  /// Top level manager for a table.
  /// This class contains the top level manager functions for the table.
  RootTableManager(super.state);
  Future<int> insert(Insertable<D> item) =>
      state.db.into(state._tableAsTableInfo).insert(item);
  Future<void> insertAllBatch(List<Insertable<D>> items) => state.db
      .batch((batch) => batch.insertAll(state._tableAsTableInfo, items));
  Future<List<D>> getAll() => state.buildSelectStatement().get();
  Stream<List<D>> watchAll() => state.buildSelectStatement().watch();
  // Future<int> deleteAll() => state.buildDeleteStatement().go();
}

/// Defines a manager for a table that can be used to build queries
abstract class ProcessedTableManager<
        DB extends GeneratedDatabase,
        T extends TableInfo,
        D extends DataClass,
        FS extends FilterComposer<DB, T>,
        OS extends OrderingComposer<DB, T>>
    extends BaseTableManager<DB, T, D, FS, OS> {
  /// A table manager which uses it's internal state to build queries
  ProcessedTableManager(super.state);
  Future<D> getSingle() => state.buildSelectStatement().getSingle();
  Stream<D> watchSingle() => state.buildSelectStatement().watchSingle();
  Future<List<D>> get() => state.buildSelectStatement().get();
  Stream<List<D>> watch() => state.buildSelectStatement().watch();
  // Future<int> delete() => state.buildDeleteStatement().go();
}
