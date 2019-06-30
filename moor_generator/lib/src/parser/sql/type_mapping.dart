import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:sqlparser/sqlparser.dart';

/// Converts tables and types between the moor_generator and the sqlparser
/// library.
class TypeMapper {
  final Map<Table, SpecifiedTable> _engineTablesToSpecified = {};

  /// Convert a [SpecifiedTable] from moor into something that can be understood
  /// by the sqlparser library.
  Table extractStructure(SpecifiedTable table) {
    final columns = <TableColumn>[];
    for (var specified in table.columns) {
      final type =
          resolveForColumnType(specified.type).withNullable(specified.nullable);
      columns.add(TableColumn(specified.name.name, type));
    }

    final engineTable = Table(name: table.sqlName, resolvedColumns: columns);
    _engineTablesToSpecified[engineTable] = table;
    return engineTable;
  }

  ResolvedType resolveForColumnType(ColumnType type) {
    switch (type) {
      case ColumnType.integer:
        return const ResolvedType(type: BasicType.int);
      case ColumnType.text:
        return const ResolvedType(type: BasicType.text);
      case ColumnType.boolean:
        return const ResolvedType(type: BasicType.int, hint: IsBoolean());
      case ColumnType.datetime:
        return const ResolvedType(type: BasicType.int, hint: IsDateTime());
      case ColumnType.blob:
        return const ResolvedType(type: BasicType.blob);
      case ColumnType.real:
        return const ResolvedType(type: BasicType.real);
    }
    throw StateError('cant happen');
  }

  ColumnType resolvedToMoor(ResolvedType type) {
    if (type == null) {
      return ColumnType.text;
    }

    switch (type.type) {
      case BasicType.nullType:
        return ColumnType.text;
      case BasicType.int:
        if (type.hint is IsBoolean) {
          return ColumnType.boolean;
        } else if (type.hint is IsDateTime) {
          return ColumnType.datetime;
        }
        return ColumnType.integer;
      case BasicType.real:
        return ColumnType.real;
      case BasicType.text:
        return ColumnType.text;
      case BasicType.blob:
        return ColumnType.blob;
    }
    throw StateError('Unexpected type: $type');
  }

  List<FoundVariable> extractVariables(AnalysisContext ctx) {
    // this contains variable references. For instance, SELECT :a = :a would
    // contain two entries, both referring to the same variable. To do that,
    // we use the fact that each variable has a unique index.
    final usedVars = ctx.root.allDescendants.whereType<Variable>().toList()
      ..sort((a, b) => a.resolvedIndex.compareTo(b.resolvedIndex));

    final foundVariables = <FoundVariable>[];
    var currentIndex = 0;

    for (var used in usedVars) {
      if (used.resolvedIndex == currentIndex) {
        continue; // already handled
      }

      currentIndex++;
      final name = (used is ColonNamedVariable) ? used.name : null;
      final type = resolvedToMoor(ctx.typeOf(used).type);

      foundVariables.add(FoundVariable(currentIndex, name, type));
    }

    return foundVariables;
  }

  SpecifiedTable tableToMoor(Table table) {
    return _engineTablesToSpecified[table];
  }
}
