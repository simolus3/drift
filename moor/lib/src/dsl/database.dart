import 'package:meta/meta.dart';
import 'package:moor/moor.dart';

/// Use this class as an annotation to inform moor_generator that a database
/// class should be generated using the specified [UseMoor.tables].
///
/// To write a database class, first annotate an empty class with [UseMoor] and
/// run the build runner using (flutter packages) pub run build_runner build.
/// Moor will have generated a class that has the same name as your database
/// class, but with `_$` as a prefix. You can now extend that class and provide
/// a [QueryEngine] to use moor:
/// ```dart
/// class MyDatabase extends _$MyDatabase { // _$MyDatabase was generated
///   MyDatabase() : super(FlutterQueryExecutor.inDatabaseFolder(path: 'path.db'));
/// }
/// ```
class UseMoor {
  /// The tables to include in the database
  final List<Type> tables;

  /// Optionally, the list of daos to use. A dao can also make queries like a
  /// regular database class, making is suitable to extract parts of your
  /// database logic into smaller components.
  ///
  /// For instructions on how to write a dao, see the documentation of [UseDao]
  final List<Type> daos;

  /// Use this class as an annotation to inform moor_generator that a database
  /// class should be generated using the specified [UseMoor.tables].
  const UseMoor({@required this.tables, this.daos = const []});
}

/// Annotation to use on classes that implement [DatabaseAccessor]. It specifies
/// which tables should be made available in this dao.
///
/// To write a dao, you'll first have to write a database class. See [UseMoor]
/// for instructions on how to do that. Then, create an empty class that is
/// annotated with [UseDao] and that extends [DatabaseAccessor]. For instance,
/// if you have a class called `MyDatabase`, this could look like this:
/// ```dart
/// class MyDao extends DatabaseAccessor<MyDatabase> {
///   TodosDao(MyDatabase db) : super(db);
/// }
/// ```
/// After having run the build step once more, moor will have generated a mixin
/// called `_$MyDaoMixin`. Change your class definition to
/// `class MyDao extends DatabaseAccessor<MyDatabase> with _$MyDaoMixin` and
/// you're ready to make queries inside your dao. You can obtain an instance of
/// that dao by using the getter that will be generated inside your database
/// class.
class UseDao {
  /// The tables accessed by this DAO.
  final List<Type> tables;

  const UseDao({@required this.tables});
}
