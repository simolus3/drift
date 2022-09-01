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
    final fields = <EqualityField>[];
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
      final runtimeType = column.dartTypeCode();

      into.write('$modifier $runtimeType $name\n;');

      fields.add(EqualityField(name, isList: column.isUint8ListInDart));
      if (!column.nullable) nonNullableFields.add(name);
    }

    for (final nested in resultSet.nestedResults) {
      if (nested is NestedResultTable) {
        var typeName = nested.table.dartTypeCode();
        final fieldName = nested.dartFieldName;

        if (nested.isNullable) {
          typeName += '?';
        }

        into.write('$modifier $typeName $fieldName;\n');

        fields.add(EqualityField(fieldName));
        if (!nested.isNullable) nonNullableFields.add(fieldName);
      } else if (nested is NestedResultQuery) {
        final fieldName = nested.filedName();
        final typeName = nested.resultTypeCode();

        if (nested.query.resultSet.needsOwnClass) {
          ResultSetWriter(nested.query, scope).write();
        }

        into.write('$modifier List<$typeName> $fieldName;\n');

        fields.add(EqualityField(fieldName));
        nonNullableFields.add(fieldName);
      }
    }

    // write the constructor
    if (scope.options.rawResultSetData) {
      into.write('$className({required QueryRow row,');
    } else {
      into.write('$className({');
    }

    for (final column in fields) {
      if (nonNullableFields.contains(column.lexeme)) {
        into.write('required ');
      }
      into.write('this.${column.lexeme},');
    }

    if (scope.options.rawResultSetData) {
      into.write('}): super(row);\n');
    } else {
      into.write('});\n');
    }

    // if requested, override hashCode and equals
    if (scope.writer.options.overrideHashAndEqualsInResultSets) {
      into.write('@override int get hashCode => ');
      writeHashCode(fields, into);
      into.write(';\n');

      overrideEquals(fields, className, into);
      overrideToString(className, fields.map((f) => f.lexeme).toList(), into);
    }

    into.write('}\n');
  }
}
