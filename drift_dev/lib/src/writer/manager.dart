// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:drift/drift.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:recase/recase.dart';

extension on DriftColumn {
  bool get isForeignKey {
    return constraints.whereType<ForeignKeyReference>().isNotEmpty;
  }
}

class ManagerWriter {
  final Scope scope;
  final String dbClassName;

  ManagerWriter(this.scope, this.dbClassName);

  void addTable(DriftTable table) {
    final leaf = scope.leaf();

    final filters = StringBuffer();
    final orderings = StringBuffer();

    for (var col in table.columns) {
      final getterName =
          ReCase(col.nameInDart + (col.isForeignKey ? " id" : " ")).camelCase;

      filters.writeln(
          "ColumnFilters get $getterName => ColumnFilters(state.table.${col.nameInDart});");
      orderings.writeln(
          "ComposableOrdering get ${getterName}Asc => ComposableOrdering.simple({OrderingBuilder( OrderingMode.asc, state.table.${col.nameInDart})});");
      orderings.writeln(
          "ComposableOrdering get ${getterName}Desc => ComposableOrdering.simple({OrderingBuilder( OrderingMode.desc, state.table.${col.nameInDart})});");

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

ComposableFilter ${col.nameInDart}OrderBy(
          ComposableFilter Function(${referencedEntityInfoName}FilterComposer) f) {
        return referenced(
            referencedTable: state.db.${referencedTableGetter},
            getCurrentColumn: (p0) => p0.${col.nameInDart},
            getReferencedColumn: (p0) => p0.${referencedCol.nameInDart},
            getReferencedQueryComposer: (data) =>
                ${referencedEntityInfoName}FilterComposer.withAliasedTable(data),
            builder: f);
          }
          
          ''');

              orderings.write('''

ComposableOrdering ${col.nameInDart}OrderBy(
          ComposableOrdering Function(${referencedEntityInfoName}OrderingComposer) f) {
        return referenced(
            referencedTable: state.db.${referencedTableGetter},
            getCurrentColumn: (p0) => p0.${col.nameInDart},
            getReferencedColumn: (p0) => p0.${referencedCol.nameInDart},
            getReferencedQueryComposer: (data) =>
                ${referencedEntityInfoName}OrderingComposer.withAliasedTable(data),
            builder: f);
          }
          
          ''');
            }
          }
        }
      }
    }

    leaf.write("""

class ${table.entityInfoName}FilterComposer extends FilterComposer<$dbClassName, ${table.entityInfoName}> {
  ${table.entityInfoName}FilterComposer.empty(super.db, super.table) : super.empty();
  ${table.entityInfoName}FilterComposer.withAliasedTable(super.data) : super.withAliasedTable();

  $filters
}

class ${table.entityInfoName}OrderingComposer extends OrderingComposer<$dbClassName, ${table.entityInfoName}> {
  ${table.entityInfoName}OrderingComposer.empty(super.db, super.table) : super.empty();
  ${table.entityInfoName}OrderingComposer.withAliasedTable(super.data) : super.withAliasedTable();

  $orderings
}

class ${table.entityInfoName}ProcessedTableManager extends ProcessedTableManager<$dbClassName,
    ${table.entityInfoName}, ${table.nameOfRowClass}, ${table.entityInfoName}FilterComposer, ${table.entityInfoName}OrderingComposer> {
  ${table.entityInfoName}ProcessedTableManager(super.data);
}

class ${table.entityInfoName}ProcessedTableManagerWithFiltering extends ProcessedTableManager<$dbClassName,
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

class ${table.entityInfoName}ProcessedTableManagerWithOrdering extends ProcessedTableManager<$dbClassName,
    ${table.entityInfoName}, ${table.nameOfRowClass}, ${table.entityInfoName}FilterComposer, ${table.entityInfoName}OrderingComposer> {
  ${table.entityInfoName}ProcessedTableManagerWithOrdering(super.data);

  ${table.entityInfoName}ProcessedTableManager orderBy(
      ComposableOrdering Function(${table.entityInfoName}OrderingComposer o) order) {
    final ordering = order(state.orderingComposer);
    return ${table.entityInfoName}ProcessedTableManager(state.copyWith(
        orderingTerms: state.orderingBuilders.union(ordering.orderingBuilders),
        joinBuilders: state.joinBuilders.union(ordering.joinBuilders)));
  }
}

class ${table.entityInfoName}TableManager extends ${table.entityInfoName}ProcessedTableManager {
  ${table.entityInfoName}TableManager($dbClassName db, ${table.entityInfoName} table)
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
      ComposableOrdering Function(${table.entityInfoName}OrderingComposer o) order) {
    final ordering = order(state.orderingComposer);
    return ${table.entityInfoName}ProcessedTableManagerWithFiltering(state.copyWith(
        orderingTerms: state.orderingBuilders.union(ordering.orderingBuilders),
        joinBuilders: state.joinBuilders.union(ordering.joinBuilders)));
  }
}
""");
  }
}
