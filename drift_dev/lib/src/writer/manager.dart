// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:recase/recase.dart';

extension on DriftColumn {
  bool get isForeignKey {
    return constraints.whereType<ForeignKeyReference>().isNotEmpty;
  }
}

class ManagerWriter {
  final Scope _scope;
  final String _dbClassName;
  final List<DriftTable> _addedTables;

  ManagerWriter(this._scope, this._dbClassName) : _addedTables = [];

  void _writeTableManagers(DriftTable table) {
    final leaf = _scope.leaf();

    final filters = StringBuffer();
    final orderings = StringBuffer();

    for (var col in table.columns) {
      final getterName =
          (col.nameInDart + (col.isForeignKey ? " id" : " ")).camelCase;

      // The type this column stores
      final innerColumnType = leaf.dartCode(leaf.innerColumnType(col.sqlType));

      if (col.typeConverter == null) {
        filters.writeln(
            "ColumnFilters<$innerColumnType> get $getterName => ColumnFilters(state.table.${col.nameInDart});");
      } else {
        filters.writeln(
            "ColumnFilters<$innerColumnType> get ${getterName}Value => ColumnFilters(state.table.${col.nameInDart});");
        final mappedType = leaf.dartCode(leaf.writer.dartType(col));
        filters.writeln(
            "ColumnWithTypeConverterFilters<$mappedType,$innerColumnType> get $getterName => ColumnWithTypeConverterFilters(state.table.${col.nameInDart});");
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
            final referencedEntityInfoName = referencedCol.owner.entityInfoName;

            if (referencedTableGetter != null) {
              filters.write('''

ComposableFilter ${col.nameInDart}Filter(
          ComposableFilter Function(${referencedEntityInfoName}FilterComposer f) f) {
        return referenced(
            referencedTable: state.db.$referencedTableGetter,
            getCurrentColumn: (f) => f.${col.nameInDart},
            getReferencedColumn: (f) => f.${referencedCol.nameInDart},
            getReferencedQueryComposer: (data) =>
                ${referencedEntityInfoName}FilterComposer.withAliasedTable(data),
            builder: f);
          }
          
          ''');

              orderings.write('''

ComposableOrdering ${col.nameInDart}OrderBy(
          ComposableOrdering Function(${referencedEntityInfoName}OrderingComposer o) o) {
        return referenced(
            referencedTable: state.db.$referencedTableGetter,
            getCurrentColumn: (f) => f.${col.nameInDart},
            getReferencedColumn: (f) => f.${referencedCol.nameInDart},
            getReferencedQueryComposer: (data) =>
                ${referencedEntityInfoName}OrderingComposer.withAliasedTable(data),
            builder: o);
          }
          
          ''');
            }
          }
        }
      }
    }

    leaf.write("""

class ${table.entityInfoName}FilterComposer extends FilterComposer<$_dbClassName, ${table.entityInfoName}> {
  ${table.entityInfoName}FilterComposer.empty(super.db, super.table) : super.empty();
  ${table.entityInfoName}FilterComposer.withAliasedTable(super.data) : super.withAliasedTable();

  $filters
}

class ${table.entityInfoName}OrderingComposer extends OrderingComposer<$_dbClassName, ${table.entityInfoName}> {
  ${table.entityInfoName}OrderingComposer.empty(super.db, super.table) : super.empty();
  ${table.entityInfoName}OrderingComposer.withAliasedTable(super.data) : super.withAliasedTable();

  $orderings
}

class ${table.entityInfoName}ProcessedTableManager extends ProcessedTableManager<$_dbClassName,
    ${table.entityInfoName}, ${table.nameOfRowClass}, ${table.entityInfoName}FilterComposer, ${table.entityInfoName}OrderingComposer> {
  ${table.entityInfoName}ProcessedTableManager(super.data);
}

class ${table.entityInfoName}ProcessedTableManagerWithFiltering extends ProcessedTableManager<$_dbClassName,
    ${table.entityInfoName}, ${table.nameOfRowClass}, ${table.entityInfoName}FilterComposer, ${table.entityInfoName}OrderingComposer> {
  ${table.entityInfoName}ProcessedTableManagerWithFiltering(super.data);

  ${table.entityInfoName}ProcessedTableManager filter(
      ComposableFilter Function(${table.entityInfoName}FilterComposer f) f) {
    final filter = f(state.filteringComposer);
    return ${table.entityInfoName}ProcessedTableManager(state.copyWith(
        filter: filter.expression,
        joinBuilders: state.joinBuilders.union(filter.joinBuilders)));
  }
}

class ${table.entityInfoName}ProcessedTableManagerWithOrdering extends ProcessedTableManager<$_dbClassName,
    ${table.entityInfoName}, ${table.nameOfRowClass}, ${table.entityInfoName}FilterComposer, ${table.entityInfoName}OrderingComposer> {
  ${table.entityInfoName}ProcessedTableManagerWithOrdering(super.data);

  ${table.entityInfoName}ProcessedTableManager orderBy(
      ComposableOrdering Function(${table.entityInfoName}OrderingComposer o) o) {
    final ordering = o(state.orderingComposer);
    return ${table.entityInfoName}ProcessedTableManager(state.copyWith(
        orderingTerms: state.orderingBuilders.union(ordering.orderingBuilders),
        joinBuilders: state.joinBuilders.union(ordering.joinBuilders)));
  }
}

class ${table.entityInfoName}TableManager extends RootTableManager<$_dbClassName,
    ${table.entityInfoName}, ${table.nameOfRowClass}, ${table.entityInfoName}FilterComposer, ${table.entityInfoName}OrderingComposer> {
  ${table.entityInfoName}TableManager($_dbClassName db, ${table.entityInfoName} table)
      : super(TableManagerState(
            db: db,
            table: table,
            filteringComposer: ${table.entityInfoName}FilterComposer.empty(db, table),
            orderingComposer: ${table.entityInfoName}OrderingComposer.empty(db, table)));

  ${table.entityInfoName}ProcessedTableManagerWithOrdering filter(
      ComposableFilter Function(${table.entityInfoName}FilterComposer f) f) {
    final filter = f(state.filteringComposer);
    return ${table.entityInfoName}ProcessedTableManagerWithOrdering(state.copyWith(
        filter: filter.expression,
        joinBuilders: state.joinBuilders.union(filter.joinBuilders)));
  }

    ${table.entityInfoName}ProcessedTableManagerWithFiltering orderBy(
      ComposableOrdering Function(${table.entityInfoName}OrderingComposer o) o) {
    final ordering = o(state.orderingComposer);
    return ${table.entityInfoName}ProcessedTableManagerWithFiltering(state.copyWith(
        orderingTerms: state.orderingBuilders.union(ordering.orderingBuilders),
        joinBuilders: state.joinBuilders.union(ordering.joinBuilders)));
  }
}
""");
  }

  String get managerGetter {
    return '''${_dbClassName}Manager get managers => ${_dbClassName}Manager(this);''';
  }

  void addTable(DriftTable table) {
    _addedTables.add(table);
  }

  void write() {
    for (var table in _addedTables) {
      _writeTableManagers(table);
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
