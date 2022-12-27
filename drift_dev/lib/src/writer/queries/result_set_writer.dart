import '../../analysis/results/results.dart';
import '../utils/hash_and_equals.dart';
import '../utils/override_toString.dart';
import '../writer.dart';

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

    // Write fields
    for (final column in resultSet.columns) {
      final fieldName = resultSet.dartNameFor(column);

      if (column is ScalarResultColumn) {
        final runtimeType = into.dartCode(into.dartType(column));

        into.write('$modifier $runtimeType $fieldName\n;');

        fields.add(EqualityField(fieldName, isList: column.isUint8ListInDart));
        if (!column.nullable) nonNullableFields.add(fieldName);
      } else if (column is NestedResultTable) {
        into
          ..write('$modifier ')
          ..writeDart(
              AnnotatedDartCode.build((b) => b.addTypeOfNestedResult(column)))
          ..write(column.isNullable ? '? ' : ' ')
          ..writeln('$fieldName;');

        fields.add(EqualityField(fieldName));
        if (!column.isNullable) nonNullableFields.add(fieldName);
      } else if (column is NestedResultQuery) {
        if (column.query.resultSet.needsOwnClass) {
          ResultSetWriter(column.query, scope).write();
        }

        into
          ..write('$modifier ')
          ..writeDart(
              AnnotatedDartCode.build((b) => b.addTypeOfNestedResult(column)))
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
