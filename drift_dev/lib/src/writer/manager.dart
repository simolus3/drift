// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:recase/recase.dart';

extension on DriftColumn {
  bool get isForeignKey {
    return constraints.whereType<ForeignKeyReference>().isNotEmpty;
  }
}

class Names {
  final String filterComposer;
  final String orderingComposer;
  final String processedTableManager;
  final String tableManagerWithFiltering;
  final String tableManagerWithOrdering;
  final String rootTableManager;

  Names(String name)
      : filterComposer = '${name}FilterComposer',
        orderingComposer = '${name}OrderingComposer',
        processedTableManager = '${name}ProcessedTableManager',
        tableManagerWithFiltering = '${name}TableManagerWithFiltering',
        tableManagerWithOrdering = '${name}TableManagerWithOrdering',
        rootTableManager = '${name}TableManager';
}

class ManagerWriter {
  final Scope _scope;
  final String _dbClassName;
  final List<DriftTable> _addedTables;

  ManagerWriter(this._scope, this._dbClassName) : _addedTables = [];

  void writeManagers(TextEmitter leaf, DriftTable table) {
    final names = Names(table.entityInfoName);

    // Write the ProcessedTableManager
    leaf
      ..write('class ${names.processedTableManager} extends ')
      ..writeDriftRef('ProcessedTableManager')
      ..writeln(
          '<$_dbClassName,${table.entityInfoName},${table.nameOfRowClass},${names.filterComposer},${names.orderingComposer}> {')
      ..writeln('const ${names.processedTableManager}(super.state);')
      ..writeln('}');

    // Write the TableManagerWithFiltering
    leaf
      ..write('class ${names.tableManagerWithFiltering} extends ')
      ..writeDriftRef('TableManagerWithFiltering')
      ..writeln(
          '<$_dbClassName,${table.entityInfoName},${table.nameOfRowClass},${names.filterComposer},${names.orderingComposer},${names.processedTableManager}> {')
      ..writeln(
          'const ${names.tableManagerWithFiltering}(super.state,{required super.getChildManager});')
      ..writeln('}');

    // Write the TableManagerWithOrdering
    leaf
      ..write('class ${names.tableManagerWithOrdering} extends ')
      ..writeDriftRef('TableManagerWithOrdering')
      ..writeln(
          '<$_dbClassName,${table.entityInfoName},${table.nameOfRowClass},${names.filterComposer},${names.orderingComposer},${names.processedTableManager}> {')
      ..writeln(
          'const ${names.tableManagerWithOrdering}(super.state,{required super.getChildManager});')
      ..writeln('}');
    // Write the Root Table Manager
    leaf
      ..write('class ${names.rootTableManager} extends ')
      ..writeDriftRef('RootTableManager')
      ..writeln(
          '<$_dbClassName,${table.entityInfoName},${table.nameOfRowClass},${names.filterComposer},${names.orderingComposer},${names.processedTableManager},${names.tableManagerWithFiltering},${names.tableManagerWithOrdering}> {')
      ..writeln(
          '${names.rootTableManager}($_dbClassName db, ${table.entityInfoName} table)')
      ..writeln(": super(")
      ..writeDriftRef("TableManagerState")
      ..write(
          """(db: db, table: table, filteringComposer:${names.filterComposer}(db, table),orderingComposer:${names.orderingComposer}(db, table)),
            getChildManagerWithFiltering: (f) => ${names.tableManagerWithFiltering}(f,getChildManager: (f) => ${names.processedTableManager}(f)),
            getChildManagerWithOrdering: (f) => ${names.tableManagerWithOrdering}(f,getChildManager: (f) =>${names.processedTableManager}(f)));""")
      ..writeln('}');
  }

  void _writeTableManagers(DriftTable table, List<DriftTable> otherTables) {
    final leaf = _scope.leaf();

    final filters = StringBuffer();
    final orderings = StringBuffer();

    for (var col in table.columns) {
      final getterName =
          (col.nameInDart + (col.isForeignKey ? " id" : " ")).camelCase;

      // The type this column stores
      final innerColumnType = leaf.dartCode(leaf.innerColumnType(col.sqlType));
      filters.writeln(
          "ColumnFilters<$innerColumnType> get $getterName => ColumnFilters(state.table.${col.nameInDart});");

      if (col.typeConverter != null) {
        final mappedType = leaf.dartCode(leaf.writer.dartType(col));
        filters.writeln(
            "ColumnWithTypeConverterFilters<$mappedType,$innerColumnType> get ${getterName}Ref => ColumnWithTypeConverterFilters(state.table.${col.nameInDart});");
      }

      orderings.writeln(
          "ColumnOrderings get $getterName => ColumnOrderings(state.table.${col.nameInDart});");

      if (col.isForeignKey) {
        final referencedCol = col.constraints
            .whereType<ForeignKeyReference>()
            .firstOrNull
            ?.otherColumn;
        if (referencedCol != null) {
          if (referencedCol.owner is DriftTable) {
            final referencedTableGetter = referencedCol.owner.dbGetterName;
            final referencedTableName =
                Names(referencedCol.owner.entityInfoName);

            if (referencedTableGetter != null) {
              filters.write('''
ComposableFilter ${col.nameInDart}Filter(
          ComposableFilter Function(${referencedTableName.filterComposer} f) f) {
        return referenced(
            referencedTable: state.db.$referencedTableGetter,
            getCurrentColumn: (f) => f.${col.nameInDart},
            getReferencedColumn: (f) => f.${referencedCol.nameInDart},
            getReferencedComposer: (db, table) => ${referencedTableName.filterComposer}(db, table),
            builder: f);
          }
          ''');

              orderings.write('''
ComposableOrdering ${col.nameInDart}OrderBy(
          ComposableOrdering Function(${referencedTableName.orderingComposer} o) o) {
        return referenced(
            referencedTable: state.db.$referencedTableGetter,
            getCurrentColumn: (f) => f.${col.nameInDart},
            getReferencedColumn: (f) => f.${referencedCol.nameInDart},
            getReferencedComposer: (db, table) => ${referencedTableName.orderingComposer}(db, table),
            builder: o);
          }
          ''');
            }
          }
        }
      }
    }

    // Any other table who has a reference to this table should have a back ref created for it
    for (var otherTable in otherTables) {
      for (var otherColumn in otherTable.columns) {
        if (otherColumn.isForeignKey) {
          final foreignKey = otherColumn.constraints
              .whereType<ForeignKeyReference>()
              .firstOrNull;
          // Check if this is a foreign key
          if (foreignKey == null) {
            continue;
          }
          // Check if the foreign key references this table
          final thisColumn = foreignKey.otherColumn;
          final thisTable = thisColumn.owner;

          final otherColumnName = Names(otherTable.entityInfoName);
          // Check if the foreign key references this table
          if (thisTable is DriftTable &&
              table.schemaName == thisTable.schemaName) {
            filters.write('''
ComposableFilter ${("referenced ${otherTable.dbGetterName} ${otherColumn.nameInDart}").camelCase}(
          ComposableFilter Function(${otherColumnName.filterComposer} f) f) {
        return referenced(
            getCurrentColumn: (f) => f.${thisColumn.nameInDart},
            referencedTable: state.db.${otherTable.dbGetterName},
            getReferencedColumn: (f) => f.${otherColumn.nameInDart},
            getReferencedComposer: (db, table) => ${otherColumnName.filterComposer}(db, table),
            builder: f);
          }
          ''');
          }
        }
      }
    }
    final names = Names(table.entityInfoName);

    leaf.write("""







class ${names.filterComposer}
    extends FilterComposer<$_dbClassName, ${table.entityInfoName}> {
  ${names.filterComposer}(super.db, super.table);

  $filters

}

class ${names.orderingComposer}
    extends OrderingComposer<$_dbClassName, ${table.entityInfoName}> {
  ${names.orderingComposer}(super.db, super.table);

  $orderings


}""");
    writeManagers(leaf, table);
  }

  String get managerGetter {
    return '''${_dbClassName}Manager get managers => ${_dbClassName}Manager(this);''';
  }

  void addTable(DriftTable table) {
    _addedTables.add(table);
  }

  void write() {
    for (var table in _addedTables) {
      _writeTableManagers(table, _addedTables);
    }
    final leaf = _scope.leaf();
    final tableManagerGetters = StringBuffer();

    for (var table in _addedTables) {
      tableManagerGetters.writeln(
          "${table.entityInfoName}TableManager get ${table.dbGetterName} => ${table.entityInfoName}TableManager(_db, _db.${table.dbGetterName});");
    }

    leaf.write("""
class ${_dbClassName}Manager {
  final $_dbClassName _db;

  ${_dbClassName}Manager(this._db);

  $tableManagerGetters
}
""");
  }
}
