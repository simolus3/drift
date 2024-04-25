// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'manager.dart';

/// Base class for all composers
///
/// Any class that can be composed using the `&` or `|` operator is called a composable.
/// [ComposableFilter] and [ComposableOrdering] are examples of composable classes.
///
/// The [Composer] class is a top level manager for this operation.
/// ```dart
/// filter((f) => f.id.equals(1) & f.name.equals('Bob'));
/// ```
/// `f` in this example is a [Composer] object, and `f.id.equals(1)` returns a [ComposableFilter] object.
///
/// The [Composer] class is responsible for creating joins between tables, and passing them down to the composable classes.
@internal
sealed class Composer<DB extends GeneratedDatabase, CT extends Table> {
  /// The database that the query will be executed on
  final DB $db;

  /// The table that the query will be executed on
  final CT $table;

  /// If this composer was created by a referenced manager, this
  /// holds the JoinBuilder that will be used to join the referenced table
  /// to the current table
  late final JoinBuilder? $joinBuilder;

  Composer(this.$db, this.$table, {this.$joinBuilder});

  JoinBuilder $buildJoinForTable<C extends GeneratedColumn, RT extends Table,
          RC extends GeneratedColumn>(
      {required C Function(CT) getCurrentColumn,
      required RT referencedTable,
      required RC Function(RT) getReferencedColumn}) {
    return JoinBuilder.withAlias(
      db: $db,
      currentTable: $table,
      getCurrentColumn: getCurrentColumn,
      referencedTable: referencedTable,
      getReferencedColumn: getReferencedColumn,
    );
  }
}
