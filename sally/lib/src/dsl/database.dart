import 'package:meta/meta.dart';
import 'package:sally/sally.dart';

/// Use this class as an annotation to inform sally_generator that a database
/// class should be generated using the specified [UseSally.tables].
class UseSally {
  /// The tables to include in the database
  final List<Type> tables;

  /// Optionally, the list of daos to use. A dao can also make queries like a
  /// regular database class, making is suitable to extract parts of your
  /// database logic into smaller components.
  final List<Type> daos;

  /// Use this class as an annotation to inform sally_generator that a database
  /// class should be generated using the specified [UseSally.tables].
  const UseSally({@required this.tables, this.daos = const []});
}

/// Annotation to use on classes that implement [DatabaseAccessor]. It specified
/// which tables should be managed in this dao.
class UseDao {
  /// The tables accessed by this DAO.
  final List<Type> tables;

  const UseDao({@required this.tables});
}
