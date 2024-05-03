import 'package:collection/collection.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/writer/modules.dart';
import 'package:drift_dev/src/writer/tables/update_companion_writer.dart';
import 'package:drift_dev/src/writer/writer.dart';

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
    if (table.hasExistingRowClass) {
      return;
    } else {
      _addedTables.add(table);
    }
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

  String get databaseManagerGetter =>
      _templates.databaseManagerGetter(_dbClassName);

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
          _templates.rootTableManagerGetter(table, rootTableManagerClass));
    }
    leaf.writeln('}');
  }
}
