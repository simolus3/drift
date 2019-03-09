import 'package:meta/meta.dart';
import 'package:moor/moor.dart';

/// Use this class as an annotation to inform moor_generator that a database
/// class should be generated using the specified [Usemoor.tables].
class Usemoor {
  /// The tables to include in the database
  final List<Type> tables;

  /// Optionally, the list of daos to use. A dao can also make queries like a
  /// regular database class, making is suitable to extract parts of your
  /// database logic into smaller components.
  final List<Type> daos;

  /// Use this class as an annotation to inform moor_generator that a database
  /// class should be generated using the specified [Usemoor.tables].
  const Usemoor({@required this.tables, this.daos = const []});
}

/// Annotation to use on classes that implement [DatabaseAccessor]. It specified
/// which tables should be managed in this dao.
class UseDao {
  /// The tables accessed by this DAO.
  final List<Type> tables;

  const UseDao({@required this.tables});
}
