// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/writer/writer.dart';

abstract class _Filter {
  /// The getter for the column on this table
  ///
  /// E.G `id`
  final String fieldGetter;

  /// The getter for the columns filter
  ///
  /// E.G `id`
  final String filterName;

  /// Abstract class for all filters
  _Filter(this.filterName, {required this.fieldGetter});

  void writeFilter(TextEmitter leaf);
}

class _RegularFilter extends _Filter {
  /// The type that this filter is for
  final String type;

  /// A class for regular filters
  _RegularFilter(super.filterName,
      {required super.fieldGetter, required this.type});

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
  /// The type that this filter is for
  final String type;

  /// The type of the converter
  final String converterType;

  /// A class for filters with converters
  _FilterWithConverter(super.filterName,
      {required super.fieldGetter,
      required this.type,
      required this.converterType});

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

/// A class for filters that reference other tables
class _ReferencedFilter extends _Filter {
  /// The full function used to get the referenced table
  ///
  /// E.G `state.db.resultSet<$CategoryTable>('categories')`
  /// or `state.db.categories`
  final String referencedTableField;

  /// The getter for the column on the referenced table
  ///
  /// E.G `id`
  final String referencedColumnGetter;

  /// The name of the referenced table's filter composer
  ///
  /// E.G `CategoryFilterComposer`
  final String referencedFilterComposer;

  _ReferencedFilter(
    super.filterName, {
    required this.referencedTableField,
    required this.referencedColumnGetter,
    required this.referencedFilterComposer,
    required super.fieldGetter,
  });

  @override
  void writeFilter(TextEmitter leaf) {
    leaf
      ..writeDriftRef("ComposableFilter")
      ..write(" $filterName(")
      ..writeDriftRef("ComposableFilter")
      ..writeln(" Function( $referencedFilterComposer f) f) {")
      ..write('''
return referenced(
            referencedTable: $referencedTableField,
            getCurrentColumn: (f) => f.$fieldGetter,
            getReferencedColumn: (f) => f.$referencedColumnGetter,
            getReferencedComposer: (db, table) => $referencedFilterComposer(db, table),
            builder: f);
          }''');
  }
}

abstract class _Ordering {
  /// The getter for the column on this table
  ///
  /// E.G `id`
  final String fieldGetter;

  /// The getter for the columns ordering
  ///
  /// E.G `id`
  final String orderingName;

  /// Abstract class for all orderings
  _Ordering(this.orderingName, {required this.fieldGetter});

  void writeOrdering(TextEmitter leaf);
}

class _RegularOrdering extends _Ordering {
  /// The type that this ordering is for
  final String type;

  /// A class for regular orderings
  _RegularOrdering(super.orderingName,
      {required super.fieldGetter, required this.type});

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
  /// The full function used to get the referenced table
  ///
  /// E.G `state.db.resultSet<$CategoryTable>('categories')`
  /// or `state.db.categories`
  final String referencedTableField;

  /// The getter for the column on the referenced table
  ///
  /// E.G `id`
  final String referencedColumnGetter;

  /// The name of the referenced table's ordering composer
  ///
  /// E.G `CategoryOrderingComposer`
  final String referencedOrderingComposer;

  _ReferencedOrdering(super.orderingName,
      {required this.referencedTableField,
      required this.referencedColumnGetter,
      required this.referencedOrderingComposer,
      required super.fieldGetter});

  @override
  void writeOrdering(TextEmitter leaf) {
    leaf
      ..writeDriftRef("ComposableOrdering")
      ..write(" $orderingName(")
      ..writeDriftRef("ComposableOrdering")
      ..writeln(" Function( $referencedOrderingComposer o) o) {")
      ..writeln('''
return referenced(
            referencedTable: $referencedTableField,
            getCurrentColumn: (f) => f.$fieldGetter,
            getReferencedColumn: (f) => f.$referencedColumnGetter,
            getReferencedComposer: (db, table) => $referencedOrderingComposer(db, table),
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
  _ColumnNames(this.fieldGetter)
      : filters = [],
        orderings = [];
}

class _TableNames {
  /// The current table
  final DriftTable table;

  /// Generation Scope
  final Scope scope;

  /// Generation Scope for the entire database
  final Scope dbScope;

  /// The name of the filter composer class
  ///
  /// E.G `UserFilterComposer`
  String get filterComposer => '\$${table.entityInfoName}FilterComposer';

  /// The name of the filter composer class
  ///
  /// E.G `UserOrderingComposer`
  String get orderingComposer => '\$${table.entityInfoName}OrderingComposer';

  /// The name of the processed table manager class
  ///
  /// E.G `UserProcessedTableManager`
  String get processedTableManager =>
      '\$${table.entityInfoName}ProcessedTableManager';

  /// The name of the root table manager class
  ///
  /// E.G `UserTableManager`
  String get rootTableManager => '\$${table.entityInfoName}TableManager';

  /// Name of the typedef for the insertCompanionBuilder
  ///
  /// E.G. `insertCompanionBuilder`
  String get insertCompanionBuilderTypeDefName =>
      '\$${table.entityInfoName}InsertCompanionBuilder';

  /// Name of the arguments for the updateCompanionBuilder
  ///
  /// E.G. `updateCompanionBuilderTypeDef`
  String get updateCompanionBuilderTypeDefName =>
      '\$${table.entityInfoName}UpdateCompanionBuilder';

  /// Table class name, this may be different from the entity name
  /// if modular generation is enabled
  /// E.G. `i5.$CategoriesTable`
  String get tableClassName => dbScope.dartCode(dbScope.entityInfoType(table));

  /// Row class name, this may be different from the entity name
  /// if modular generation is enabled
  /// E.G. `i5.$Category`
  String get rowClassName => dbScope.dartCode(dbScope.writer.rowType(table));

  /// The name of the database class
  ///
  /// E.G. `i5.$GeneratedDatabase`
  final String databaseGenericName;

  /// Columns with their names, filters and orderings
  final List<_ColumnNames> columns;

  /// Filters for back references
  final List<_ReferencedFilter> backRefFilters;

  _TableNames(this.table, this.scope, this.dbScope, this.databaseGenericName)
      : backRefFilters = [],
        columns = [];

  void _writeFilterComposer(TextEmitter leaf) {
    leaf
      ..write('class $filterComposer extends ')
      ..writeDriftRef('FilterComposer')
      ..writeln('<$databaseGenericName,$tableClassName> {')
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
  }

  void _writeOrderingComposer(TextEmitter leaf) {
    // Write the OrderingComposer
    leaf
      ..write('class $orderingComposer extends ')
      ..writeDriftRef('OrderingComposer')
      ..writeln('<$databaseGenericName,$tableClassName> {')
      ..writeln('$orderingComposer(super.db, super.table);');
    for (var c in columns) {
      for (var o in c.orderings) {
        o.writeOrdering(leaf);
      }
    }
    leaf.writeln('}');
  }

  void _writeProcessedTableManager(TextEmitter leaf) {
    leaf
      ..write('class $processedTableManager extends ')
      ..writeDriftRef('ProcessedTableManager')
      ..writeln(
          '<$databaseGenericName,$tableClassName,$rowClassName,$filterComposer,$orderingComposer,$processedTableManager,$insertCompanionBuilderTypeDefName,$updateCompanionBuilderTypeDefName> {')
      ..writeln('const $processedTableManager(super.state);')
      ..writeln('}');
  }

  void _writeRootTable(TextEmitter leaf) {
    final companionClassName = leaf.dartCode(leaf.companionType(table));

    final updateCompanionBuilderTypeDef = StringBuffer(
        'typedef $updateCompanionBuilderTypeDefName = $companionClassName Function({');
    final insertCompanionBuilderTypeDef = StringBuffer(
        'typedef $insertCompanionBuilderTypeDefName =  $companionClassName Function({');

    final updateCompanionBuilderArguments = StringBuffer('({');
    final insertCompanionBuilderArguments = StringBuffer('({');

    final updateCompanionBuilderBody = StringBuffer('=> $companionClassName(');
    final insertCompanionBuilderBody =
        StringBuffer('=> $companionClassName.insert(');

    for (final column in table.columns) {
      final value = leaf.drift('Value');
      final param = column.nameInDart;
      final typeName = leaf.dartCode(leaf.dartType(column));

      // The update companion has no required fields, they are all defaulted to absent
      updateCompanionBuilderTypeDef.write('$value<$typeName> $param,');
      updateCompanionBuilderArguments
          .write('$value<$typeName> $param = const $value.absent(),');
      updateCompanionBuilderBody.write('$param: $param,');

      // The insert compantion has some required arguments and some that are defaulted to absent
      if (!column.isImplicitRowId && table.isColumnRequiredForInsert(column)) {
        insertCompanionBuilderTypeDef.write('required $typeName $param,');
        insertCompanionBuilderArguments.write('required $typeName $param,');
      } else {
        insertCompanionBuilderTypeDef.write('$value<$typeName> $param,');
        insertCompanionBuilderArguments
            .write('$value<$typeName> $param = const $value.absent(),');
      }
      insertCompanionBuilderBody.write('$param: $param,');
    }

    // Close
    // updateCompanionTypedef.write('})');
    insertCompanionBuilderTypeDef.write('});');
    updateCompanionBuilderTypeDef.write('});');
    insertCompanionBuilderArguments.write('})');
    updateCompanionBuilderArguments.write('})');
    insertCompanionBuilderBody.write(")");
    updateCompanionBuilderBody.write(")");
    leaf.writeln(insertCompanionBuilderTypeDef);
    leaf.writeln(updateCompanionBuilderTypeDef);

    leaf
      ..write('class $rootTableManager extends ')
      ..writeDriftRef('RootTableManager')
      ..writeln(
          '<$databaseGenericName,$tableClassName,$rowClassName,$filterComposer,$orderingComposer,$processedTableManager,$insertCompanionBuilderTypeDefName,$updateCompanionBuilderTypeDefName>   {')
      ..writeln(
          '$rootTableManager($databaseGenericName db, $tableClassName table)')
      ..writeln(": super(")
      ..writeDriftRef("TableManagerState")
      ..write(
          """(db: db, table: table, filteringComposer:$filterComposer(db, table),orderingComposer:$orderingComposer(db, table),
            getChildManagerBuilder :(p0) => $processedTableManager(p0),getUpdateCompanionBuilder: $updateCompanionBuilderArguments$updateCompanionBuilderBody,
            getInsertCompanionBuilder:$insertCompanionBuilderArguments$insertCompanionBuilderBody));""")
      ..writeln('}');
  }

  void writeManager(TextEmitter leaf) {
    _writeFilterComposer(leaf);
    _writeOrderingComposer(leaf);
    _writeProcessedTableManager(leaf);
    _writeRootTable(leaf);
  }

  void addFiltersAndOrderings(List<DriftTable> tables) {
    // Utility function to get the referenced table and column
    (DriftTable, DriftColumn)? getReferencedTableAndColumn(
        DriftColumn column, List<DriftTable> tables) {
      final referencedCol = column.constraints
          .whereType<ForeignKeyReference>()
          .firstOrNull
          ?.otherColumn;
      if (referencedCol != null && referencedCol.owner is DriftTable) {
        final referencedTable = tables.firstWhere(
            (t) => t.entityInfoName == referencedCol.owner.entityInfoName);
        return (referencedTable, referencedCol);
      }
      return null;
    }

    /// First add the filters and orderings for the columns
    /// of the current table
    for (var column in table.columns) {
      final c = _ColumnNames(column.nameInDart);

      // The type that this column is (int, string, etc)
      final innerColumnType =
          scope.dartCode(scope.innerColumnType(column.sqlType));

      // Get the referenced table and column if this column is a foreign key
      final referenced = getReferencedTableAndColumn(column, tables);
      final isForeignKey = referenced != null;

      // If the column has a type converter, add a filter with a converter
      if (column.typeConverter != null) {
        final converterType = scope.dartCode(scope.writer.dartType(column));
        c.filters.add(_FilterWithConverter(c.fieldGetter,
            converterType: converterType,
            fieldGetter: c.fieldGetter,
            type: innerColumnType));
      } else {
        c.filters.add(_RegularFilter(
            c.fieldGetter + (isForeignKey ? "Value" : ""),
            type: innerColumnType,
            fieldGetter: c.fieldGetter));
      }

      // Add the ordering for the column
      c.orderings.add(_RegularOrdering(
          c.fieldGetter + (isForeignKey ? "Value" : ""),
          type: innerColumnType,
          fieldGetter: c.fieldGetter));

      /// If this column is a foreign key to another table, add a filter and ordering
      /// for the referenced table

      if (referenced != null) {
        final (referencedTable, referencedCol) = referenced;
        final referencedTableNames =
            _TableNames(referencedTable, scope, dbScope, databaseGenericName);
        final referencedColumnNames = _ColumnNames(referencedCol.nameInDart);
        final String referencedTableField = scope.generationOptions.isModular
            ? "state.db.resultSet<${referencedTableNames.tableClassName}>('${referencedTable.schemaName}')"
            : "state.db.${referencedTable.dbGetterName}";

        c.filters.add(_ReferencedFilter(c.fieldGetter,
            fieldGetter: c.fieldGetter,
            referencedColumnGetter: referencedColumnNames.fieldGetter,
            referencedFilterComposer: referencedTableNames.filterComposer,
            referencedTableField: referencedTableField));
        c.orderings.add(_ReferencedOrdering(c.fieldGetter,
            fieldGetter: c.fieldGetter,
            referencedColumnGetter: referencedColumnNames.fieldGetter,
            referencedOrderingComposer: referencedTableNames.orderingComposer,
            referencedTableField: referencedTableField));
      }
      columns.add(c);
    }

    // Iterate over all other tables to find back references
    for (var ot in tables) {
      for (var oc in ot.columns) {
        // Check if the column is a foreign key to the current table
        final reference = getReferencedTableAndColumn(oc, tables);
        if (reference != null &&
            reference.$1.entityInfoName == table.entityInfoName) {
          final referencedTableNames =
              _TableNames(ot, scope, dbScope, databaseGenericName);
          final referencedColumnNames = _ColumnNames(oc.nameInDart);
          final String referencedTableField = scope.generationOptions.isModular
              ? "state.db.resultSet<${referencedTableNames.tableClassName}>('${ot.schemaName}')"
              : "state.db.${ot.dbGetterName}";

          final filterName = oc.referenceName ??
              "${referencedTableNames.table.dbGetterName}Refs";

          backRefFilters.add(_ReferencedFilter(filterName,
              fieldGetter: reference.$2.nameInDart,
              referencedColumnGetter: referencedColumnNames.fieldGetter,
              referencedFilterComposer: referencedTableNames.filterComposer,
              referencedTableField: referencedTableField));
        }
      }
    }
    // Remove the filters and orderings that have duplicates
    // TODO: Add warnings for duplicate filters and orderings
    List<String> duplicates(List<String> items) {
      final seen = <String>{};
      final duplicates = <String>[];
      for (var item in items) {
        if (!seen.add(item)) {
          duplicates.add(item);
        }
      }
      return duplicates;
    }

    // Gather which filters and orderings are duplicates
    final filterNamesToRemove = duplicates(columns
            .map((e) => e.filters.map((e) => e.filterName))
            .expand((e) => e)
            .toList() +
        backRefFilters.map((e) => e.filterName).toList());
    final orderingNamesToRemove = duplicates(columns
        .map((e) => e.orderings.map((e) => e.orderingName))
        .expand((e) => e)
        .toList());

    // Remove the duplicates
    for (var c in columns) {
      c.filters.removeWhere((e) => filterNamesToRemove.contains(e.filterName));
      c.orderings
          .removeWhere((e) => orderingNamesToRemove.contains(e.orderingName));
    }
    backRefFilters
        .removeWhere((e) => filterNamesToRemove.contains(e.filterName));
  }
}

class ManagerWriter {
  final Scope _scope;
  final Scope _dbScope;
  final String _dbClassName;
  late final List<DriftTable> _addedTables;

  ManagerWriter(this._scope, this._dbScope, this._dbClassName) {
    _addedTables = [];
  }

  void addTable(DriftTable table) {
    _addedTables.add(table);
  }

  String get databaseGenericName {
    if (_scope.generationOptions.isModular) {
      return _scope.drift("GeneratedDatabase");
    } else {
      return _dbClassName;
    }
  }

  String get databaseManagerName => '${_dbClassName}Manager';

  String get managerGetter {
    return '$databaseManagerName get managers => $databaseManagerName(this);';
  }

  void write() {
    final leaf = _scope.leaf();
    final tableNames = <_TableNames>[];

    for (var table in _addedTables) {
      tableNames.add(_TableNames(table, _scope, _dbScope, databaseGenericName)
        ..addFiltersAndOrderings(_addedTables));
    }

    final tableManagerGetters = StringBuffer();

    for (var table in tableNames) {
      table.writeManager(leaf);
      tableManagerGetters.writeln(
          "${table.rootTableManager} get ${table.table.dbGetterName} => ${table.rootTableManager}(_db, _db.${table.table.dbGetterName});");
    }

    leaf.write("""
class $databaseManagerName{
  final $_dbClassName _db;

  $databaseManagerName(this._db);

  $tableManagerGetters
}
""");
  }
}
