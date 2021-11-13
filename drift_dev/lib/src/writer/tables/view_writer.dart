import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/utils/string_escaper.dart';

import '../database_writer.dart';
import '../writer.dart';
import 'data_class_writer.dart';
import 'table_writer.dart';

class ViewWriter extends TableOrViewWriter {
  final MoorView view;
  final Scope scope;
  final DatabaseWriter databaseWriter;

  @override
  late StringBuffer buffer;

  @override
  MoorView get tableOrView => view;

  ViewWriter(this.view, this.scope, this.databaseWriter);

  void write() {
    if (scope.generationOptions.writeDataClasses &&
        !tableOrView.hasExistingRowClass) {
      DataClassWriter(view, scope).write();
    }

    _writeViewInfoClass();
  }

  void _writeViewInfoClass() {
    buffer = scope.leaf();

    buffer.write('class ${view.entityInfoName} extends View with ViewInfo');
    if (scope.generationOptions.writeDataClasses) {
      buffer.write('<${view.entityInfoName}, '
          '${view.dartTypeCode(scope.generationOptions)}>');
    } else {
      buffer.write('<${view.entityInfoName}, Never>');
    }

    buffer
      ..write('{\n')
      // write the generated database reference that is set in the constructor
      ..write('final ${databaseWriter.dbClassName} _db;\n')
      ..write('final ${scope.nullableType('String')} _alias;\n')
      ..write('${view.entityInfoName}(this._db, [this._alias]);\n');

    writeGetColumnsOverride();
    buffer
      ..write('@override\nString get aliasedName => '
          '_alias ?? actualViewName;\n')
      ..write('@override\n String get actualViewName =>'
          ' ${asDartLiteral(view.name)};\n')
      ..write('@override\n String get createViewStmt =>'
          ' ${asDartLiteral(view.createSql(scope.options))};\n');

    writeAsDslTable();
    writeMappingMethod(scope);

    for (final column in view.columns) {
      writeColumnGetter(column, scope.generationOptions, false);
    }

    _writeAliasGenerator();
    _writeAs();

    buffer.writeln('}');
  }

  void _writeAliasGenerator() {
    final typeName = view.entityInfoName;

    buffer
      ..write('@override\n')
      ..write('$typeName createAlias(String alias) {\n')
      ..write('return $typeName(_db, alias);')
      ..write('}');
  }

  void _writeAs() {
    buffer
      ..write('@override\n')
      ..write('Query<${view.entityInfoName}, ${view.dartTypeName}> as() =>\n')
      ..write('_db.select(_db.${view.dbGetterName});\n');
  }
}
