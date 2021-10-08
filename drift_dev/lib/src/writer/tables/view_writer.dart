import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/utils/string_escaper.dart';

import '../writer.dart';
import 'data_class_writer.dart';
import 'table_writer.dart';

class ViewWriter extends TableOrViewWriter {
  final MoorView view;
  final Scope scope;

  @override
  late StringBuffer buffer;

  @override
  MoorView get tableOrView => view;

  ViewWriter(this.view, this.scope);

  void write() {
    if (scope.generationOptions.writeDataClasses &&
        !tableOrView.hasExistingRowClass) {
      DataClassWriter(view, scope).write();
    }

    _writeViewInfoClass();
  }

  void _writeViewInfoClass() {
    buffer = scope.leaf();

    buffer.write('class ${view.entityInfoName} extends View');
    if (scope.generationOptions.writeDataClasses) {
      buffer.write('<${view.entityInfoName}, '
          '${view.dartTypeCode(scope.generationOptions)}>');
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
    writeMappingMethod(scope);

    for (final column in view.columns) {
      writeColumnGetter(column, scope.generationOptions, false);
    }

    buffer.writeln('}');
  }
}
