import 'package:sqlparser/sqlparser.dart';

/// Interface for sqlite extensions providing additional functions or module.
///
/// Extension support in the sqlparser package is still experimental, and only
/// supports modules for `CREATE VIRTUAL TABLE` statements at the moment.
abstract class Extension {
  void register(SqlEngine engine);
}

/// An sqlite module, which can be used in a `CREATE VIRTUAL TABLE` statement
/// to find providers.
abstract class Module implements Referencable, VisibleToChildren {
  /// The name of this module, which is referenced by the `USING` clause in a
  /// `CREATE VIRTUAL TABLE` statement.
  final String name;

  Module(this.name);

  /// Extracts the table structure from a `CREATE VIRTUAL TABLE` statement that
  /// refers to this module. The module is responsible for setting
  /// [Table.definition].
  Table parseTable(CreateVirtualTableStatement stmt);
}
