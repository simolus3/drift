// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:recase/recase.dart';

extension on DriftColumn {
  bool get isForeignKey {
    return constraints.whereType<ForeignKeyReference>().isNotEmpty;
  }
}

abstract class _Filter {
  void writeFilter(TextEmitter leaf);
}

class _RegularFilter extends _Filter {
  final String fieldGetter;
  final String type;
  final String filterName;
  _RegularFilter(this.fieldGetter, this.type, this.filterName);

  @override
  void writeFilter(TextEmitter leaf) {
    leaf
      ..writeDriftRef("ColumnFilters")
      ..write("<$type> get $filterName =>")
      ..writeDriftRef("ColumnFilters")
      ..write("(state.table.$fieldGetter);");
  }
}

class _FilterWithConverter extends _Filter {
  final String fieldGetter;
  final String type;
  final String filterName;
  final String converterType;
  _FilterWithConverter(
      this.fieldGetter, this.type, this.filterName, this.converterType);

  @override
  void writeFilter(TextEmitter leaf) {
    leaf
      ..writeDriftRef("ColumnWithTypeConverterFilters")
      ..write("<$converterType,$type> get $filterName =>")
      ..writeDriftRef("ColumnWithTypeConverterFilters")
      ..writeln("(state.table.$fieldGetter);");
    leaf
      ..writeDriftRef("ColumnFilters")
      ..write("<$type> get ${filterName}Value =>")
      ..writeDriftRef("ColumnFilters")
      ..writeln("(state.table.$fieldGetter);");
  }
}

class _ReferencedFilter extends _Filter {
  final String fieldGetter;
  final String filterName;
  final _TableNames referencedTable;
  final _ColumnNames referencedColumn;
  _ReferencedFilter(this.fieldGetter, this.filterName, this.referencedTable,
      this.referencedColumn);

  @override
  void writeFilter(TextEmitter leaf) {
    leaf
      ..writeDriftRef("ComposableFilter")
      ..write(" $filterName(")
      ..writeDriftRef("ComposableFilter")
      ..writeln(" Function( ${referencedTable.filterComposer} f) f) {")
      ..writeln('''
return referenced(
            referencedTable: state.db.${referencedTable.tableGetterName},
            getCurrentColumn: (f) => f.$fieldGetter,
            getReferencedColumn: (f) => f.${referencedColumn.fieldGetter},
            getReferencedComposer: (db, table) => ${referencedTable.filterComposer}(db, table),
            builder: f);
          }''');
  }
}

abstract class _Ordering {
  void writeOrdering(TextEmitter leaf);
}

class _RegularOrdering extends _Ordering {
  final String fieldGetter;
  final String type;
  final String orderingName;
  _RegularOrdering(this.fieldGetter, this.type, this.orderingName);

  @override
  void writeOrdering(TextEmitter leaf) {
    leaf
      ..writeDriftRef("ColumnOrderings")
      ..write(" get $orderingName =>")
      ..writeDriftRef("ColumnOrderings")
      ..write("(state.table.$fieldGetter);");
  }
}

class _ReferencedOrdering extends _Ordering {
  final String fieldGetter;
  final String orderingName;
  final _TableNames referencedTable;
  final _ColumnNames referencedColumn;
  _ReferencedOrdering(this.fieldGetter, this.orderingName, this.referencedTable,
      this.referencedColumn);

  @override
  void writeOrdering(TextEmitter leaf) {
    leaf
      ..writeDriftRef("ComposableOrdering")
      ..write(" $orderingName(")
      ..writeDriftRef("ComposableOrdering")
      ..writeln(" Function( ${referencedTable.orderingComposer} o) o) {")
      ..writeln('''
return referenced(
            referencedTable: state.db.${referencedTable.tableGetterName},
            getCurrentColumn: (f) => f.$fieldGetter,
            getReferencedColumn: (f) => f.${referencedColumn.fieldGetter},
            getReferencedComposer: (db, table) => ${referencedTable.orderingComposer}(db, table),
            builder: o);
          }''');
  }
}

class _ColumnNames {
  /// The getter for the field
  ///
  /// E.G `id`
  final String fieldGetter;
  final List<_Filter> filters;
  final List<_Ordering> orderings;
  _ColumnNames(this.fieldGetter, this.filters, this.orderings);
}

class _TableNames {
  /// The current table
  final DriftTable table;

  /// The name of the filter composer class
  ///
  /// E.G `UserFilterComposer`
  final String filterComposer;

  /// The name of the filter composer class
  ///
  /// E.G `UserOrderingComposer`
  final String orderingComposer;

  /// The name of the processed table manager class
  ///
  /// E.G `UserProcessedTableManager`
  final String processedTableManager;

  /// The name of the table manager with filtering class
  ///
  /// E.G `UserTableManagerWithFiltering`
  final String tableManagerWithFiltering;

  /// The name of the table manager with ordering class
  ///
  /// E.G `UserTableManagerWithOrdering`
  final String tableManagerWithOrdering;

  /// The name of the root table manager class
  ///
  /// E.G `UserTableManager`
  final String rootTableManager;

  /// Name of the table class that will be generated
  ///
  /// E.G `$CategoriesTable`
  final String tableClassName;

  /// Name of the getter for the table
  ///
  /// E.G `categories`
  final String tableGetterName;

  /// Name of the class that cooresponds to a table row
  ///
  /// E.G `Category`
  final String rowClassName;

  /// Columns with their names, filters and orderings
  final List<_ColumnNames> columns;

  final List<_ReferencedFilter> backRefFilters;

  _TableNames(this.table)
      : filterComposer = '${table.entityInfoName}FilterComposer',
        orderingComposer = '${table.entityInfoName}OrderingComposer',
        processedTableManager = '${table.entityInfoName}ProcessedTableManager',
        tableManagerWithFiltering =
            '${table.entityInfoName}TableManagerWithFiltering',
        tableManagerWithOrdering =
            '${table.entityInfoName}TableManagerWithOrdering',
        rootTableManager = '${table.entityInfoName}TableManager',
        rowClassName = table.nameOfRowClass,
        tableClassName = table.entityInfoName,
        tableGetterName = table.dbGetterName,
        backRefFilters = [],
        columns = [];

  void writeManager(TextEmitter leaf, String dbClassName) {
    // Write the FilterComposer
    leaf
      ..write('class $filterComposer extends ')
      ..writeDriftRef('FilterComposer')
      ..writeln('<$dbClassName,$tableClassName> {')
      ..writeln('$filterComposer(super.db, super.table);');
    for (var c in columns) {
      for (var f in c.filters) {
        f.writeFilter(leaf);
      }
    }
    for (var f in backRefFilters) {
      f.writeFilter(leaf);
    }
    leaf.writeln('}');

    // Write the OrderingComposer
    leaf
      ..write('class $orderingComposer extends ')
      ..writeDriftRef('OrderingComposer')
      ..writeln('<$dbClassName,$tableClassName> {')
      ..writeln('$orderingComposer(super.db, super.table);');
    for (var c in columns) {
      for (var o in c.orderings) {
        o.writeOrdering(leaf);
      }
    }
    leaf.writeln('}');

    // Write the ProcessedTableManager
    leaf
      ..write('class $processedTableManager extends ')
      ..writeDriftRef('ProcessedTableManager')
      ..writeln(
          '<$dbClassName,$tableClassName,$rowClassName,$filterComposer,$orderingComposer> {')
      ..writeln('const $processedTableManager(super.state);')
      ..writeln('}');

    // Write the TableManagerWithFiltering
    leaf
      ..write('class $tableManagerWithFiltering extends ')
      ..writeDriftRef('TableManagerWithFiltering')
      ..writeln(
          '<$dbClassName,$tableClassName,$rowClassName,$filterComposer,$orderingComposer,$processedTableManager> {')
      ..writeln(
          'const $tableManagerWithFiltering(super.state,{required super.getChildManager});')
      ..writeln('}');

    // Write the TableManagerWithOrdering
    leaf
      ..write('class $tableManagerWithOrdering extends ')
      ..writeDriftRef('TableManagerWithOrdering')
      ..writeln(
          '<$dbClassName,$tableClassName,$rowClassName,$filterComposer,$orderingComposer,$processedTableManager> {')
      ..writeln(
          'const $tableManagerWithOrdering(super.state,{required super.getChildManager});')
      ..writeln('}');
    // Write the Root Table Manager
    leaf
      ..write('class $rootTableManager extends ')
      ..writeDriftRef('RootTableManager')
      ..writeln(
          '<$dbClassName,$tableClassName,$rowClassName,$filterComposer,$orderingComposer,$processedTableManager,$tableManagerWithFiltering,$tableManagerWithOrdering> {')
      ..writeln('$rootTableManager($dbClassName db, $tableClassName table)')
      ..writeln(": super(")
      ..writeDriftRef("TableManagerState")
      ..write(
          """(db: db, table: table, filteringComposer:$filterComposer(db, table),orderingComposer:$orderingComposer(db, table)),
            getChildManagerWithFiltering: (f) => $tableManagerWithFiltering(f,getChildManager: (f) => $processedTableManager(f)),
            getChildManagerWithOrdering: (f) => $tableManagerWithOrdering(f,getChildManager: (f) =>$processedTableManager(f)));""")
      ..writeln('}');
  }

  void addFiltersAndOrderings(List<DriftTable> tables, TextEmitter leaf) {
    /// First add the filters and orderings for the columns
    /// of the current table
    for (var column in table.columns) {
      final c = _ColumnNames(column.nameInDart, [], []);
      final innerColumnType =
          leaf.dartCode(leaf.innerColumnType(column.sqlType));
      if (column.typeConverter != null) {
        final mappedType = leaf.dartCode(leaf.writer.dartType(column));
        c.filters.add(_FilterWithConverter(
            c.fieldGetter, innerColumnType, c.fieldGetter, mappedType));
      } else {
        c.filters
            .add(_RegularFilter(c.fieldGetter, innerColumnType, c.fieldGetter));
      }
      c.orderings
          .add(_RegularOrdering(c.fieldGetter, innerColumnType, c.fieldGetter));

      final referencedCol = column.constraints
          .whereType<ForeignKeyReference>()
          .firstOrNull
          ?.otherColumn;
      final referencedTable = referencedCol?.owner;
      if (referencedCol != null && referencedTable is DriftTable) {
        final referencedTableNames = _TableNames(referencedTable);
        final referencedColumnNames =
            _ColumnNames(referencedCol.nameInDart, [], []);
        c.filters.add(_ReferencedFilter(c.fieldGetter, "${c.fieldGetter}Ref",
            referencedTableNames, referencedColumnNames));
        c.orderings.add(_ReferencedOrdering(
            c.fieldGetter,
            "${c.fieldGetter}OrderBy",
            referencedTableNames,
            referencedColumnNames));
      }
      columns.add(c);
    }
    for (var otherTable in tables) {
      final otherTableNames = _TableNames(otherTable);

      /// We are adding backrefs now, skip the current table
      if (otherTableNames.tableClassName == tableClassName) {
        continue;
      }
      for (var otherColumn in otherTable.columns) {
        final referencedCol = otherColumn.constraints
            .whereType<ForeignKeyReference>()
            .firstOrNull
            ?.otherColumn;
        final referencedTable = referencedCol?.owner;
        if (referencedCol != null && referencedTable is DriftTable) {
          final referencedTableNames = _TableNames(referencedTable);
          final referencedColumnNames =
              _ColumnNames(referencedCol.nameInDart, [], []);

          // If we are referencing the current table, add a back ref
          if (referencedTableNames.tableClassName == tableClassName) {
            backRefFilters.add(_ReferencedFilter(
                referencedColumnNames.fieldGetter,
                "${otherTableNames.tableClassName.camelCase}Refs",
                otherTableNames,
                referencedColumnNames));
          }
        }
      }
    }
  }
}

class ManagerWriter {
  final Scope _scope;
  final String _dbClassName;
  final List<DriftTable> _addedTables;

  ManagerWriter(this._scope, this._dbClassName) : _addedTables = [];

  String get managerGetter {
    return '''$_dbMangerName get managers => $_dbMangerName(this);''';
  }

  void addTable(DriftTable table) {
    _addedTables.add(table);
  }

  String get _dbMangerName => '${_dbClassName}Manager';

  void write() {
    final leaf = _scope.leaf();
    final tableNames = <_TableNames>[];
    for (var table in _addedTables) {
      final t = _TableNames(table);
      t.addFiltersAndOrderings(_addedTables, leaf);
      t.writeManager(leaf, _dbClassName);
      tableNames.add(t);
    }
    final tableManagerGetters = StringBuffer();

    for (var table in tableNames) {
      tableManagerGetters.writeln(
          "${table.rootTableManager} get ${table.tableGetterName} => ${table.rootTableManager}(_db, _db.${table.tableGetterName});");
    }

    leaf.write("""
class $_dbMangerName{
  final $_dbClassName _db;

  $_dbMangerName(this._db);

  $tableManagerGetters
}
""");
  }
}
