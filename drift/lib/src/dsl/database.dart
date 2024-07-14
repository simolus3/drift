part of 'dsl.dart';

/// Use this class as an annotation to inform the generator that a database
/// class should be generated using the specified [DriftDatabase.tables].
///
/// To write a database class, first annotate an empty class with
/// [DriftDatabase] and run the build runner using
/// `dart pub run build_runner build`.
/// Drift will have generated a class that has the same name as your database
/// class, but with `_$` as a prefix. You can now extend that class and provide
/// a [QueryExecutor] to use drift:
///
/// ```dart
/// import 'package:drift/drift.dart';
/// import 'package:drift_flutter/drift_flutter.dart';
///
/// @DriftDatabase(tables: [...])
/// class MyDatabase extends _$MyDatabase { // _$MyDatabase was generated
///   MyDatabase(): super(driftDatabase(name: 'path.db'));
/// }
/// ```
///
/// For more information on getting started with drift, which also describes
/// options for using drift outside of Flutter apps, see the [getting started]
/// section in the documentation.
///
/// [getting started]: https://drift.simonbinder.eu/docs/getting-started/
class DriftDatabase {
  /// The tables to include in the database
  final List<Type> tables;

  /// The views to include in the database
  final List<Type> views;

  /// Optionally, the list of daos to use. A dao can also make queries like a
  /// regular database class, making is suitable to extract parts of your
  /// database logic into smaller components.
  ///
  /// For instructions on how to write a dao, see the documentation of
  /// [DriftAccessor].
  final List<Type> daos;

  /// {@template drift_compile_queries_param}
  /// Optionally, a list of named sql queries. During a build, drift will look
  /// at the defined sql, figure out what they do, and write appropriate
  /// methods in your generated database.
  ///
  /// For instance, when using
  /// ```dart
  /// @DriftDatabase(
  ///   tables: [Users],
  ///   queries: {
  ///     'userById': 'SELECT * FROM users WHERE id = ?',
  ///   },
  /// )
  /// ```
  /// Drift will generate two methods for you: `userById(int id)` and
  /// `watchUserById(int id)`.
  /// {@endtemplate}
  final Map<String, String> queries;

  /// {@template drift_include_param}
  ///
  /// Defines the `.drift` files to include when building the table structure
  /// for this database. For details on how to integrate `.drift` files into
  /// your Dart code, see [the documentation](https://drift.simonbinder.eu/docs/using-sql/custom_tables/).
  /// {@endtemplate}
  final Set<String> include;

  /// Use this class as an annotation to inform the generator that a database
  /// class should be generated using the specified [DriftDatabase.tables].
  const DriftDatabase({
    this.tables = const [],
    this.views = const [],
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
/// After having run the build step once more, drift will have generated a mixin
/// called `_$MyDaoMixin`. Change your class definition to
/// `class MyDao extends DatabaseAccessor<MyDatabase> with _$MyDaoMixin` and
/// you're ready to make queries inside your dao. You can obtain an instance of
/// that dao by using the getter that will be generated inside your database
/// class.
///
/// See also:
/// - https://drift.simonbinder.eu/daos/
class DriftAccessor {
  /// The tables accessed by this DAO.
  final List<Type> tables;

  /// The views to make accessible in this DAO.
  final List<Type> views;

  /// {@macro drift_compile_queries_param}
  final Map<String, String> queries;

  /// {@macro drift_include_param}
  final Set<String> include;

  /// Annotation for a class to declare it as an dao. See [DriftAccessor] and
  /// the referenced documentation on how to use daos with drift.
  const DriftAccessor({
    this.tables = const [],
    this.views = const [],
    this.queries = const {},
    this.include = const {},
  });
}
