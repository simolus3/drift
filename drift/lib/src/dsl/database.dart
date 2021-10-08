part of 'dsl.dart';

/// Use this class as an annotation to inform moor_generator that a database
/// class should be generated using the specified [DriftDatabase.tables].
///
/// To write a database class, first annotate an empty class with
/// [DriftDatabase] and run the build runner using
/// `dart pub run build_runner build`.
/// Moor will have generated a class that has the same name as your database
/// class, but with `_$` as a prefix. You can now extend that class and provide
/// a [QueryExecutor] to use moor:
/// ```dart
/// class MyDatabase extends _$MyDatabase { // _$MyDatabase was generated
///   MyDatabase():
///     super(FlutterQueryExecutor.inDatabaseFolder(path: 'path.db'));
/// }
/// ```
class DriftDatabase {
  /// The tables to include in the database
  final List<Type> tables;

  /// Optionally, the list of daos to use. A dao can also make queries like a
  /// regular database class, making is suitable to extract parts of your
  /// database logic into smaller components.
  ///
  /// For instructions on how to write a dao, see the documentation of
  /// [DriftAccessor].
  final List<Type> daos;

  /// {@template moor_compile_queries_param}
  /// Optionally, a list of named sql queries. During a build, moor will look at
  /// the defined sql, figure out what they do, and write appropriate
  /// methods in your generated database.
  ///
  /// For instance, when using
  /// ```dart
  /// @UseMoor(
  ///   tables: [Users],
  ///   queries: {
  ///     'userById': 'SELECT * FROM users WHERE id = ?',
  ///   },
  /// )
  /// ```
  /// Moor will generate two methods for you: `userById(int id)` and
  /// `watchUserById(int id)`.
  /// {@endtemplate}
  final Map<String, String> queries;

  /// {@template moor_include_param}
  /// Defines the `.moor` files to include when building the table structure for
  /// this database. For details on how to integrate `.moor` files into your
  /// Dart code, see [the documentation](https://moor.simonbinder.eu/docs/using-sql/custom_tables/).
  /// {@endtemplate}
  final Set<String> include;

  /// Use this class as an annotation to inform moor_generator that a database
  /// class should be generated using the specified [DriftDatabase.tables].
  const DriftDatabase({
    this.tables = const [],
    this.daos = const [],
    this.queries = const {},
    this.include = const {},
  });
}

/// Annotation to use on classes that implement [DatabaseAccessor]. It specifies
/// which tables should be made available in this dao.
///
/// To write a dao, you'll first have to write a database class. See
/// [DriftDatabase] for instructions on how to do that. Then, create an empty
/// class that is annotated with [DriftAccessor] and extends [DatabaseAccessor].
/// For instance, if you have a class called `MyDatabase`, this could look like
/// this:
/// ```dart
/// @DriftAccessor()
/// class MyDao extends DatabaseAccessor<MyDatabase> {
///   MyDao(MyDatabase db) : super(db);
/// }
/// ```
/// After having run the build step once more, moor will have generated a mixin
/// called `_$MyDaoMixin`. Change your class definition to
/// `class MyDao extends DatabaseAccessor<MyDatabase> with _$MyDaoMixin` and
/// you're ready to make queries inside your dao. You can obtain an instance of
/// that dao by using the getter that will be generated inside your database
/// class.
///
/// See also:
/// - https://moor.simonbinder.eu/daos/
class DriftAccessor {
  /// The tables accessed by this DAO.
  final List<Type> tables;

  /// {@macro moor_compile_queries_param}
  final Map<String, String> queries;

  /// {@macro moor_include_param}
  final Set<String> include;

  /// Annotation for a class to declare it as an dao. See [UseDao] and the
  /// referenced documentation on how to use daos with moor.
  const DriftAccessor(
      {this.tables = const [],
      this.queries = const {},
      this.include = const {}});
}
