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
    buffer.writeln(' implements HasResultSet {');

    buffer
      ..writeln('final String? _alias;')
      ..writeln(
          '@override final ${databaseWriter.dbClassName} attachedDatabase;')
      ..writeln('${view.entityInfoName}(this.attachedDatabase, '
          '[this._alias]);');

    final declaration = view.declaration;
    if (declaration is DartViewDeclaration) {
      // A view may read from the same table more than once, so we implicitly
      // introduce aliases for tables.
      var tableCounter = 0;

      for (final ref in declaration.staticReferences) {
        final table = ref.table;
        final alias = asDartLiteral('t${tableCounter++}');

        final declaration = '${table.entityInfoName} get ${ref.name} => '
            'attachedDatabase.${table.dbGetterName}.createAlias($alias);';
        buffer.writeln(declaration);
      }
    }

    if (view.viewQuery == null) {
      writeGetColumnsOverride();
    } else {
      final columns = view.viewQuery!.columns.map((e) => e.key).join(', ');
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

    final columns = view.viewQuery?.columns.map((e) => e.value) ?? view.columns;
    for (final column in columns) {
      if (view.columns.contains(column)) {
        writeColumnGetter(column, scope.generationOptions, false);
      } else {
        // This column only exists as a getter so that it can be referenced in
        // Dart, but it wasn't defined by the user. Instead, the column is
        // implicitly generated from a entry in the `select()` query clause.
        // We can drop all information from it since only the name is relevant.
        final shortColumn = MoorColumn(
            type: column.type,
            dartGetterName: column.dartGetterName,
            name: column.name);
        writeColumnGetter(shortColumn, scope.generationOptions, false);
      }
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
