import '../../analysis/results/results.dart';
import '../utils/hash_and_equals.dart';
import '../utils/override_toString.dart';
import '../writer.dart';

/// Writes a class holding the result of an sql query into Dart.
class ResultSetWriter {
  final InferredResultSet resultSet;
  final String resultClassName;
  final Scope scope;

  ResultSetWriter(SqlQuery query, this.scope)
      : resultSet = query.resultSet!,
        resultClassName = query.resultClassName;

  ResultSetWriter.fromResultSetAndClassName(
      this.resultSet, this.resultClassName, this.scope);

  void write() {
    final fields = <EqualityField>[];
    final nonNullableFields = <String>{};
    final into = scope.leaf();

    into.write('class $resultClassName ');
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
        if (column.innerResultSet.needsOwnClass) {
          ResultSetWriter.fromResultSetAndClassName(
                  column.innerResultSet, column.nameForGeneratedRowClass, scope)
              .write();
        }

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
      into.write('$resultClassName({required QueryRow row,');
    } else {
      into.write('$resultClassName({');
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

      overrideEquals(fields, resultClassName, into);
      overrideToString(
          resultClassName, fields.map((f) => f.lexeme).toList(), into.buffer);
    }

    into.write('}\n');
  }
}
