part of 'runtime_api.dart';

/// Class that runs queries to a subset of all available queries in a database.
///
/// This comes in handy to structure large amounts of database code better: The
/// migration logic can live in the main [GeneratedDatabase] class, but code
/// can be extracted into [DatabaseAccessor]s outside of that database.
/// For details on how to write a dao, see [DriftAccessor].
/// [T] should be the associated database class you wrote.
abstract class DatabaseAccessor<T extends GeneratedDatabase>
    extends DatabaseConnectionUser {
  /// The main database instance for this dao
  @override
  final T attachedDatabase;

  /// Used internally by drift
  DatabaseAccessor(this.attachedDatabase) : super.delegate(attachedDatabase);
}

/// Extension for generated dao classes to keep the old [db] field that was
/// renamed to [DatabaseAccessor.attachedDatabase] in drift 3.0
extension OldDbFieldInDatabaseAccessor<T extends GeneratedDatabase>
    on DatabaseAccessor<T> {
  /// The generated database that this dao is attached to.
  T get db => attachedDatabase;
}
