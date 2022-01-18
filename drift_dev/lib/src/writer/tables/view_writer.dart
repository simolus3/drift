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

    buffer.write('class ${view.entityInfoName} extends ViewInfo');
    if (scope.generationOptions.writeDataClasses) {
      buffer.write('<${view.entityInfoName}, '
          '${view.dartTypeCode(scope.generationOptions)}>');
    } else {
      buffer.write('<${view.entityInfoName}, Never>');
    }
    buffer.write(' implements HasResultSet');

    buffer
      ..write('{\n')
      // write the generated database reference that is set in the constructor
      ..write('final ${scope.nullableType('String')} _alias;\n')
      ..write('${view.entityInfoName}(DatabaseConnectionUser db, '
          '[this._alias]): super(db);\n');

    final declaration = view.declaration;
    if (declaration is DartViewDeclaration) {
      for (final ref in declaration.staticReferences) {
        buffer.write('${ref.declaration}\n');
      }
    }

    if (view.viewQuery == null) {
      writeGetColumnsOverride();
    } else {
      final columns = view.viewQuery!.columns.keys.join(', ');
      buffer.write('@override\nList<GeneratedColumn> get \$columns => '
          '[$columns];\n');
    }

    buffer
      ..write('@override\nString get aliasedName => '
          '_alias ?? entityName;\n')
      ..write('@override\n String get entityName=>'
          ' ${asDartLiteral(view.name)};\n');

    if (view.declaration is MoorViewDeclaration) {
      buffer.write('@override\n String get createViewStmt =>'
          ' ${asDartLiteral(view.createSql(scope.options))};\n');
    } else {
      buffer.write('@override\n String? get createViewStmt => null;\n');
    }

    writeAsDslTable();
    writeMappingMethod(scope);

    for (final column in view.viewQuery?.columns.values ?? view.columns) {
      writeColumnGetter(column, scope.generationOptions, false);
    }

    _writeAliasGenerator();
    _writeQuery();

    final readTables = view.transitiveTableReferences
        .map((e) => asDartLiteral(e.sqlName))
        .join(', ');
    buffer.writeln('''
      @override
      Set<String> get readTables => const {$readTables};
    ''');

    buffer.writeln('}');
  }

  void _writeAliasGenerator() {
    final typeName = view.entityInfoName;

    buffer
      ..write('@override\n')
      ..write('$typeName createAlias(String alias) {\n')
      ..write('return $typeName(attachedDatabase, alias);')
      ..write('}');
  }

  void _writeQuery() {
    buffer.write('@override\nQuery? get query => ');
    final query = view.viewQuery;
    if (query != null) {
      buffer.write('(attachedDatabase.selectOnly(${query.from}, '
          'includeJoinedTableColumns: false)..addColumns(\$columns))'
          '${query.query};');
    } else {
      buffer.write('null;\n');
    }
  }
}
