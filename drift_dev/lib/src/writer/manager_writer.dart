// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/writer/modules.dart';
import 'package:drift_dev/src/writer/writer.dart';

abstract class _FilterWriter {
  /// The getter for the column on this table
  ///
  /// E.G `id` in `table.id`
  final String fieldGetter;

  /// The getter for the columns filter
  ///
  /// E.G `id` in `f.id.equals(5)`
  final String filterName;

  /// An abstract class for all filters
  _FilterWriter(this.filterName, {required this.fieldGetter});

  /// Write the filter to a provider [TextEmitter]
  void writeFilter(TextEmitter leaf);
}

class _RegularFilterWriter extends _FilterWriter {
  /// The type that this column is
  ///
  /// E.G `int`, `String`, etc
  final String type;

  /// A class used for writing `ColumnFilters` with regular types
  _RegularFilterWriter(super.filterName,
      {required super.fieldGetter, required this.type});

  @override
  void writeFilter(TextEmitter leaf) {
    leaf
      ..writeDriftRef("ColumnFilters")
      ..write("<$type> get $filterName =>")
      ..writeDriftRef("ColumnFilters")
      ..write("(\$table.$fieldGetter);");
  }
}

class _FilterWithConverterWriter extends _FilterWriter {
  /// The type that this column is
  ///
  /// E.G `int`, `String`, etc
  final String type;

  /// The type of the user provided converter
  ///
  /// E.G `Color` etc
  final String converterType;

  /// A class used for writing `ColumnFilters` with custom converters
  _FilterWithConverterWriter(super.filterName,
      {required super.fieldGetter,
      required this.type,
      required this.converterType});

  @override
  void writeFilter(TextEmitter leaf) {
    leaf
      ..writeDriftRef("ColumnWithTypeConverterFilters")
      ..write("<$converterType,$type> get $filterName =>")
      ..writeDriftRef("ColumnWithTypeConverterFilters")
      ..writeln("(\$table.$fieldGetter);");
  }
}

class _ReferencedFilterWriter extends _FilterWriter {
  /// The full function used to get the referenced table
  ///
  /// E.G `\$db.resultSet<$CategoryTable>('categories')`
  /// or `\$db.categories`
  final String referencedTableField;

  /// The getter for the column on the referenced table
  ///
  /// E.G `id` in `table.id`
  final String referencedColumnGetter;

  /// The name of the referenced table's filter composer
  ///
  /// E.G `CategoryFilterComposer`
  final String referencedFilterComposer;

  /// A class used for building filters for referenced tables
  _ReferencedFilterWriter(
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
      ..write("return ")
      ..writeUriRef(
          Uri.parse('package:drift/internal/manager.dart'), 'composeWithJoins')
      ..writeln('(')
      ..writeln("\$db: \$db,")
      ..writeln("\$table: \$table,")
      ..writeln("referencedTable: $referencedTableField,")
      ..writeln("getCurrentColumn: (f) => f.$fieldGetter,")
      ..writeln("getReferencedColumn: (f) => f.$referencedColumnGetter,")
      ..writeln(
          "getReferencedComposer: (db, table) => $referencedFilterComposer(db, table),")
      ..writeln("builder: f);")
      ..writeln("}");
  }
}

abstract class _OrderingWriter {
  /// The getter for the column on this table
  ///
  /// E.G `id` in `table.id`
  final String fieldGetter;

  /// The getter for the columns ordering
  ///
  /// E.G `id` in `f.id.equals(5)`
  final String orderingName;

  /// Abstract class for all orderings
  _OrderingWriter(this.orderingName, {required this.fieldGetter});

  /// Write the ordering to a provider [TextEmitter]
  void writeOrdering(TextEmitter leaf);
}

class _RegularOrderingWriter extends _OrderingWriter {
  /// The type that this column is
  ///
  /// E.G `int`, `String`, etc
  final String type;

  /// A class used for writing `ColumnOrderings` with regular types
  _RegularOrderingWriter(super.orderingName,
      {required super.fieldGetter, required this.type});

  @override
  void writeOrdering(TextEmitter leaf) {
    leaf
      ..writeDriftRef("ColumnOrderings")
      ..write(" get $orderingName =>")
      ..writeDriftRef("ColumnOrderings")
      ..write("(\$table.$fieldGetter);");
  }
}

class _ReferencedOrderingWriter extends _OrderingWriter {
  /// The full function used to get the referenced table
  ///
  /// E.G `\$db.resultSet<$CategoryTable>('categories')`
  /// or `\$db.categories`
  final String referencedTableField;

  /// The getter for the column on the referenced table
  ///
  /// E.G `id` in `table.id`
  final String referencedColumnGetter;

  /// The name of the referenced table's ordering composer
  ///
  /// E.G `CategoryOrderingComposer`
  final String referencedOrderingComposer;

  /// A class used for building orderings for referenced tables
  _ReferencedOrderingWriter(super.orderingName,
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
      ..write("return ")
      ..writeUriRef(
          Uri.parse('package:drift/internal/manager.dart'), 'composeWithJoins')
      ..writeln('(')
      ..writeln("\$db: \$db,")
      ..writeln("\$table: \$table,")
      ..writeln("referencedTable: $referencedTableField,")
      ..writeln("getCurrentColumn: (f) => f.$fieldGetter,")
      ..writeln("getReferencedColumn: (f) => f.$referencedColumnGetter,")
      ..writeln(
          "getReferencedComposer: (db, table) => $referencedOrderingComposer(db, table),")
      ..writeln("builder: o);")
      ..writeln("}");
  }
}

class _ColumnWriter {
  /// The getter for the field
  ///
  /// E.G `id` in `table.id`
  final String fieldGetter;

  /// List of filters for this column
  final List<_FilterWriter> filters;

  /// List of orderings for this column
  final List<_OrderingWriter> orderings;

  /// A class used for writing filters and orderings for columns
  _ColumnWriter(this.fieldGetter)
      : filters = [],
        orderings = [];
}

class _TableWriter {
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

  /// Writers for the columns of this table
  final List<_ColumnWriter> columns;

  /// Filters for back references
  final List<_ReferencedFilterWriter> backRefFilters;

  _TableWriter(this.table, this.scope, this.dbScope, this.databaseGenericName)
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
      ..writeln('const $processedTableManager(super.\$state);')
      ..writeln('}');
  }

  /// Build the builder for a companion class
  /// This is used to build the insert and update companions
  /// Returns a tuple with the typedef and the builder
  /// Use [isUpdate] to determine if the builder is for an update or insert companion
  (String, String) _companionBuilder(String typedefName,
      {required bool isUpdate}) {
    final companionClassName = scope.dartCode(scope.companionType(table));

    final companionBuilderTypeDef =
        StringBuffer('typedef $typedefName = $companionClassName Function({');

    final companionBuilderArguments = StringBuffer('({');

    final StringBuffer companionBuilderBody;
    if (isUpdate) {
      companionBuilderBody = StringBuffer('=> $companionClassName(');
    } else {
      companionBuilderBody = StringBuffer('=> $companionClassName.insert(');
    }

    for (final column in table.columns) {
      final value = scope.drift('Value');
      final param = column.nameInDart;
      final typeName = scope.dartCode(scope.dartType(column));

      companionBuilderBody.write('$param: $param,');

      if (isUpdate) {
        // The update companion has no required fields, they are all defaulted to absent
        companionBuilderTypeDef.write('$value<$typeName> $param,');
        companionBuilderArguments
            .write('$value<$typeName> $param = const $value.absent(),');
      } else {
        // The insert compantion has some required arguments and some that are defaulted to absent
        if (!column.isImplicitRowId &&
            table.isColumnRequiredForInsert(column)) {
          companionBuilderTypeDef.write('required $typeName $param,');
          companionBuilderArguments.write('required $typeName $param,');
        } else {
          companionBuilderTypeDef.write('$value<$typeName> $param,');
          companionBuilderArguments
              .write('$value<$typeName> $param = const $value.absent(),');
        }
      }
    }
    companionBuilderTypeDef.write('});');
    companionBuilderArguments.write('})');
    companionBuilderBody.write(")");
    return (
      companionBuilderTypeDef.toString(),
      companionBuilderArguments.toString() + companionBuilderBody.toString()
    );
  }

  void _writeRootTable(TextEmitter leaf) {
    final (insertCompanionBuilderTypeDef, insertCompanionBuilder) =
        _companionBuilder(insertCompanionBuilderTypeDefName, isUpdate: false);
    final (updateCompanionBuilderTypeDef, updateCompanionBuilder) =
        _companionBuilder(updateCompanionBuilderTypeDefName, isUpdate: true);

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
            getChildManagerBuilder :(p0) => $processedTableManager(p0),getUpdateCompanionBuilder: $updateCompanionBuilder,
            getInsertCompanionBuilder:$insertCompanionBuilder));""")
      ..writeln('}');
  }

  /// Write the manager for this table, with all the filters and orderings
  void writeManager(TextEmitter leaf) {
    _writeFilterComposer(leaf);
    _writeOrderingComposer(leaf);
    _writeProcessedTableManager(leaf);
    _writeRootTable(leaf);
  }

  /// Add filters and orderings for the columns of this table
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

    // Utility function to get the duplicates in a list
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

    /// First add the filters and orderings for the columns
    /// of the current table
    for (var column in table.columns) {
      final c = _ColumnWriter(column.nameInDart);

      // The type that this column is (int, string, etc)
      final innerColumnType =
          scope.dartCode(scope.innerColumnType(column.sqlType));

      // Get the referenced table and column if this column is a foreign key
      final referenced = getReferencedTableAndColumn(column, tables);
      final isForeignKey = referenced != null;

      // If the column has a type converter, add a filter with a converter
      if (column.typeConverter != null) {
        final converterType = scope.dartCode(scope.writer.dartType(column));
        c.filters.add(_RegularFilterWriter("${c.fieldGetter}Value",
            type: innerColumnType, fieldGetter: c.fieldGetter));
        c.filters.add(_FilterWithConverterWriter(c.fieldGetter,
            converterType: converterType,
            fieldGetter: c.fieldGetter,
            type: innerColumnType));
      } else {
        c.filters.add(_RegularFilterWriter(
            c.fieldGetter + (isForeignKey ? "Id" : ""),
            type: innerColumnType,
            fieldGetter: c.fieldGetter));
      }

      // Add the ordering for the column
      c.orderings.add(_RegularOrderingWriter(
          c.fieldGetter + (isForeignKey ? "Id" : ""),
          type: innerColumnType,
          fieldGetter: c.fieldGetter));

      /// If this column is a foreign key to another table, add a filter and ordering
      /// for the referenced table
      if (referenced != null) {
        final (referencedTable, referencedCol) = referenced;
        final referencedTableNames =
            _TableWriter(referencedTable, scope, dbScope, databaseGenericName);
        final referencedColumnNames = _ColumnWriter(referencedCol.nameInDart);
        final String referencedTableField = scope.generationOptions.isModular
            ? "\$db.resultSet<${referencedTableNames.tableClassName}>('${referencedTable.schemaName}')"
            : "\$db.${referencedTable.dbGetterName}";

        c.filters.add(_ReferencedFilterWriter(c.fieldGetter,
            fieldGetter: c.fieldGetter,
            referencedColumnGetter: referencedColumnNames.fieldGetter,
            referencedFilterComposer: referencedTableNames.filterComposer,
            referencedTableField: referencedTableField));
        c.orderings.add(_ReferencedOrderingWriter(c.fieldGetter,
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
              _TableWriter(ot, scope, dbScope, databaseGenericName);
          final referencedColumnNames = _ColumnWriter(oc.nameInDart);
          final String referencedTableField = scope.generationOptions.isModular
              ? "\$db.resultSet<${referencedTableNames.tableClassName}>('${ot.schemaName}')"
              : "\$db.${ot.dbGetterName}";

          final filterName = oc.referenceName ??
              "${referencedTableNames.table.dbGetterName}Refs";

          backRefFilters.add(_ReferencedFilterWriter(filterName,
              fieldGetter: reference.$2.nameInDart,
              referencedColumnGetter: referencedColumnNames.fieldGetter,
              referencedFilterComposer: referencedTableNames.filterComposer,
              referencedTableField: referencedTableField));
        }
      }
    }

    // Remove the filters and orderings that have duplicates
    // TODO: Add warnings for duplicate filters and orderings
    final duplicatedFilterNames = duplicates(columns
            .map((e) => e.filters.map((e) => e.filterName))
            .expand((e) => e)
            .toList() +
        backRefFilters.map((e) => e.filterName).toList());
    final duplicatedOrderingNames = duplicates(columns
        .map((e) => e.orderings.map((e) => e.orderingName))
        .expand((e) => e)
        .toList());
    // Remove the duplicates
    for (var c in columns) {
      c.filters
          .removeWhere((e) => duplicatedFilterNames.contains(e.filterName));
      c.orderings
          .removeWhere((e) => duplicatedOrderingNames.contains(e.orderingName));
    }
    backRefFilters
        .removeWhere((e) => duplicatedFilterNames.contains(e.filterName));
  }
}

class ManagerWriter {
  final Scope _scope;
  final Scope _dbScope;
  final String _dbClassName;
  late final List<DriftTable> _addedTables;

  /// Class used to write a manager for a database
  ManagerWriter(this._scope, this._dbScope, this._dbClassName) {
    _addedTables = [];
  }

  /// Add a table to the manager
  void addTable(DriftTable table) {
    _addedTables.add(table);
  }

  /// The generic of the database that the manager will use
  /// Will be `GeneratedDatabase` if modular generation is enabled
  /// or the name of the database class if not
  String get databaseGenericName {
    if (_scope.generationOptions.isModular) {
      return _scope.drift("GeneratedDatabase");
    } else {
      return _dbClassName;
    }
  }

  /// The name of the manager class
  String get databaseManagerName => '${_dbClassName}Manager';

  /// The getter for the manager that will be added to the database
  String get managerGetter {
    return '$databaseManagerName get managers => $databaseManagerName(this);';
  }

  /// Write the manager to a provider [TextEmitter]
  void write() {
    final leaf = _scope.leaf();

    // When generating with modular generation, we need to add the imports
    // for the internal `resultSet` helper
    if (_scope.generationOptions.isModular) {
      leaf.refUri(ModularAccessorWriter.modularSupport, '');
    }

    // Write the manager class for each table
    final tableWriters = <_TableWriter>[];
    for (var table in _addedTables) {
      tableWriters.add(
          _TableWriter(table, _scope, _dbScope, databaseGenericName)
            ..addFiltersAndOrderings(_addedTables));
    }

    // Write each tables manager to the leaf and append the getter to the main manager
    final tableManagerGetters = StringBuffer();
    for (var table in tableWriters) {
      table.writeManager(leaf);
      tableManagerGetters.writeln(
          "${table.rootTableManager} get ${table.table.dbGetterName} => ${table.rootTableManager}(_db, _db.${table.table.dbGetterName});");
    }

    // Write the main manager class
    leaf
      ..writeln('class $databaseManagerName{')
      ..writeln('final $_dbClassName _db;')
      ..writeln('$databaseManagerName(this._db);')
      ..writeln(tableManagerGetters)
      ..writeln('}');
  }
}
