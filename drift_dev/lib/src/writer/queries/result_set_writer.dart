import '../../analysis/results/results.dart';
import '../utils/hash_and_equals.dart';
import '../utils/override_toString.dart';
import '../writer.dart';
import 'utils.dart';

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
      final runtimeType = into.dartCode(into.dartType(column));

      into.write('$modifier $runtimeType $name\n;');

      fields.add(EqualityField(name, isList: column.isUint8ListInDart));
      if (!column.nullable) nonNullableFields.add(name);
    }

    for (final nested in resultSet.nestedResults) {
      if (nested is NestedResultTable) {
        final fieldName = nested.dartFieldName;

        into
          ..write('$modifier ')
          ..writeDart(nested.resultRowType(scope))
          ..write(nested.isNullable ? '? ' : ' ')
          ..writeln('$fieldName;');

        fields.add(EqualityField(fieldName));
        if (!nested.isNullable) nonNullableFields.add(fieldName);
      } else if (nested is NestedResultQuery) {
        final fieldName = nested.filedName();

        if (nested.query.resultSet.needsOwnClass) {
          ResultSetWriter(nested.query, scope).write();
        }

        into
          ..write('$modifier ')
          ..writeDart(nested.resultRowType(scope))
          ..writeln('$fieldName;');

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
      writeHashCode(fields, into.buffer);
      into.write(';\n');

      overrideEquals(fields, className, into.buffer);
      overrideToString(
          className, fields.map((f) => f.lexeme).toList(), into.buffer);
    }

    into.write('}\n');
  }
}
