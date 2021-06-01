// @dart=2.9
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';

import '../writer.dart';
import 'data_class_writer.dart';
import 'table_writer.dart';

class ViewWriter extends TableOrViewWriter {
  final MoorView view;
  final Scope scope;

  @override
  StringBuffer buffer;

  @override
  MoorView get tableOrView => view;

  ViewWriter(this.view, this.scope);

  void write() {
    if (scope.generationOptions.writeDataClasses) {
      DataClassWriter(view, scope).write();
    }

    _writeViewInfoClass();
  }

  void _writeViewInfoClass() {
    buffer = scope.leaf();

    buffer.write('class ${view.entityInfoName} extends View');
    if (scope.generationOptions.writeDataClasses) {
      buffer.write('<${view.entityInfoName}, ${view.dartTypeName}>');
    } else {
      buffer.write('<${view.entityInfoName}, Never>');
    }
    buffer
      ..write('{\n')
      ..write('${view.entityInfoName}(): super(')
      ..write(asDartLiteral(view.name))
      ..write(',')
      ..write(asDartLiteral(view.createSql(scope.options)))
      ..write(');');

    writeGetColumnsOverride();
    writeAsDslTable();
    _writeMappingMethod();

    for (final column in view.columns) {
      writeColumnGetter(column, scope.generationOptions, false);
    }

    buffer.writeln('}');
  }

  // After we support custom row classes for views, we can move this into the
  // shared writer
  void _writeMappingMethod() {
    if (!scope.generationOptions.writeDataClasses) {
      final nullableString = scope.nullableType('String');
      buffer.writeln('''
        @override
        Never map(Map<String, dynamic> data, {$nullableString tablePrefix}) {
          throw UnsupportedError('TableInfo.map in schema verification code');
        }
      ''');
      return;
    }

    final dataClassName = view.dartTypeName;

    buffer.write('@override\n$dataClassName map(Map<String, dynamic> data, '
        '{${scope.nullableType('String')} tablePrefix}) {\n');

    // Use default .fromData constructor in the moor-generated data class
    buffer.write('return $dataClassName.fromData(data, '
        "prefix: tablePrefix != null ? '\$tablePrefix.' : null);\n");

    buffer.write('}\n');
  }
}
