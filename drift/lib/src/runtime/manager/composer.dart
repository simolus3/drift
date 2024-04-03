// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'manager.dart';

/// A class that holds the state for a query composer
@internal
class ComposerState<DB extends GeneratedDatabase, T extends Table> {
  /// The database that the query will be executed on
  final DB db;

  /// The table that the query will be executed on
  final T table;
  ComposerState._(
    this.db,
    this.table,
  );
}

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
///
/// The [ComposerState] that is held in this class only holds temporary state, as the final state will be held in the composable classes.
/// E.G. In the example above, only the resulting [ComposableFilter] object is returned, and the [FilterComposer] is discarded.
///
@internal
sealed class Composer<DB extends GeneratedDatabase, CT extends Table> {
  /// The state of the composer
  final ComposerState<DB, CT> $state;

  Composer(DB db, CT table) : $state = ComposerState._(db, table);
}
