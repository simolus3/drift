import 'package:drift_dev/src/model/sql_query.dart';
import 'package:drift_dev/src/model/types.dart';
import 'package:drift_dev/src/writer/utils/override_toString.dart';
import 'package:drift_dev/writer.dart';

/// Writes a class holding the result of an sql query into Dart.
class ResultSetWriter {
  final SqlQuery query;
  final Scope scope;

  ResultSetWriter(this.query, this.scope);

  void write() {
    final className = query.resultClassName;
    final fieldNames = <String>[];
    final nonNullableFields = <String>{};
    final into = scope.leaf();

    final resultSet = query.resultSet!;

    into.write('class $className ');
    if (scope.options.rawResultSetData) {
      into.write('extends CustomResultSet {\n');
    } else {
      into.write('{\n');
    }

    final modifier = scope.options.fieldModifier;

    // write fields
    for (final column in resultSet.columns) {
      final name = resultSet.dartNameFor(column);
      final runtimeType = column.dartTypeCode(scope.generationOptions);

      into.write('$modifier $runtimeType $name\n;');

      fieldNames.add(name);
      if (!column.nullable) nonNullableFields.add(name);
    }

    for (final nested in resultSet.nestedResults) {
      if (nested is NestedResultTable) {
        var typeName = nested.table.dartTypeCode(scope.generationOptions);
        final fieldName = nested.dartFieldName;

        if (nested.isNullable) {
          typeName = scope.nullableType(typeName);
        }

        into.write('$modifier $typeName $fieldName;\n');

        fieldNames.add(fieldName);
        if (!nested.isNullable) nonNullableFields.add(fieldName);
      } else if (nested is NestedResultQuery) {
        final fieldName = nested.filedName();
        final typeName = nested.resultTypeCode(className);

        if (nested.query.resultSet.needsOwnClass) {
          ResultSetWriter(nested.query, scope).write();
        }

        into.write('$modifier List<$typeName> $fieldName;\n');

        fieldNames.add(fieldName);
        nonNullableFields.add(fieldName);
      }
    }

    // write the constructor
    if (scope.options.rawResultSetData) {
      into.write('$className({${scope.required} QueryRow row,');
    } else {
      into.write('$className({');
    }

    for (final column in fieldNames) {
      if (nonNullableFields.contains(column)) {
        into
          ..write(scope.required)
          ..write(' ');
      }
      into.write('this.$column,');
    }

    if (scope.options.rawResultSetData) {
      into.write('}): super(row);\n');
    } else {
      into.write('});\n');
    }

    // if requested, override hashCode and equals
    if (scope.writer.options.overrideHashAndEqualsInResultSets) {
      into.write('@override int get hashCode => ');
      const HashCodeWriter().writeHashCode(fieldNames, into);
      into.write(';\n');

      overrideEquals(fieldNames, className, into);
      overrideToString(className, fieldNames, into);
    }

    into.write('}\n');
  }
}
