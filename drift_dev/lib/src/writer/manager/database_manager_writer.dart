import 'package:collection/collection.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/writer/tables/update_companion_writer.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:recase/recase.dart';

part 'manager_templates.dart';
part 'table_manager_writer.dart';

class DatabaseManagerWriter {
  final Scope _scope;
  final String _dbClassName;
  final List<DriftTable> _addedTables;

  /// Class used to write a manager for a database
  DatabaseManagerWriter(this._scope, this._dbClassName) : _addedTables = [];

  _ManagerCodeTemplates get _templates => _ManagerCodeTemplates(_scope);

  /// Add a table to the manager writer
  ///
  /// Ignores tables that have custom row classes
  void addTable(DriftTable table) {
    _addedTables.add(table);
  }

  /// Write a table manager for each table.
  void writeTableManagers() {
    final leaf = _scope.leaf();
    for (var table in _addedTables) {
      final otherTables = _addedTables
          .whereNot(
            (otherTable) => otherTable.equals(table),
          )
          .toList();
      _TableManagerWriter(
              table: table,
              scope: _scope,
              dbClassName: _dbClassName,
              otherTables: otherTables)
          .write(leaf);
    }
  }

  /// The code for the database manager getter which will be added to the main database class
  ///
  /// E.g. `AppDatabase get managers => AppDatabaseManager(this);`
  String get databaseManagerGetter =>
      '${_templates.databaseManagerName(_dbClassName)} get managers => ${_templates.databaseManagerName(_dbClassName)}(this);';

  /// Write the database manager class
  void writeDatabaseManager() {
    final leaf = _scope.leaf();

    // Write the database manager class with the required getters
    leaf
      ..writeln('class ${_templates.databaseManagerName(_dbClassName)} {')
      ..writeln('final $_dbClassName _db;')
      ..writeln('${_templates.databaseManagerName(_dbClassName)}(this._db);');

    for (final table in _addedTables) {
      // Get the name of the table manager class
      final rootTableManagerClass =
          _templates.rootTableManagerWithPrefix(table, leaf);

      /// Write the getter for the table manager
      leaf.writeln(
          '$rootTableManagerClass get ${table.dbGetterName} => $rootTableManagerClass(_db, _db.${table.dbGetterName});');
    }
    leaf.writeln('}');
  }
}
