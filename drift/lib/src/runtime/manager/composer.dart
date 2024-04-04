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

  Composer(this.$db, this.$table);
}
