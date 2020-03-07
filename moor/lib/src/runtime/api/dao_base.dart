part of 'runtime_api.dart';

/// Class that runs queries to a subset of all available queries in a database.
///
/// This comes in handy to structure large amounts of database code better: The
/// migration logic can live in the main [GeneratedDatabase] class, but code
/// can be extracted into [DatabaseAccessor]s outside of that database.
/// For details on how to write a dao, see [UseDao].
/// [T] should be the associated database class you wrote.
abstract class DatabaseAccessor<T extends GeneratedDatabase>
    extends DatabaseConnectionUser with QueryEngine {
  @override
  final bool topLevel = true;

  /// The main database instance for this dao
  @override
  final T attachedDatabase;

  /// Used internally by moor
  DatabaseAccessor(this.attachedDatabase) : super.delegate(attachedDatabase);
}
