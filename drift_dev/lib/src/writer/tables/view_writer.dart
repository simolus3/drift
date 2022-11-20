import '../../analysis/results/results.dart';
import '../../utils/string_escaper.dart';
import '../database_writer.dart';
import '../writer.dart';
import 'data_class_writer.dart';
import 'table_writer.dart';

class ViewWriter extends TableOrViewWriter {
  final DriftView view;
  final Scope scope;
  final DatabaseWriter? databaseWriter;

  @override
  late TextEmitter emitter;

  @override
  DriftView get tableOrView => view;

  ViewWriter(this.view, this.scope, this.databaseWriter);

  void write() {
    if (scope.generationOptions.writeDataClasses &&
        !tableOrView.hasExistingRowClass) {
      DataClassWriter(view, scope).write();
    }

    _writeViewInfoClass();
  }

  void _writeViewInfoClass() {
    emitter = scope.leaf();

    buffer.write('class ${view.entityInfoName} extends ViewInfo');
    if (scope.generationOptions.writeDataClasses) {
      emitter
        ..write('<${view.entityInfoName}, ')
        ..writeDart(emitter.rowType(view))
        ..write('>');
    } else {
      buffer.write('<${view.entityInfoName}, Never>');
    }
    buffer.writeln(' implements HasResultSet {');

    final dbClassName = databaseWriter?.dbClassName ?? 'GeneratedDatabase';
    buffer
      ..writeln('final String? _alias;')
      ..writeln('@override final $dbClassName attachedDatabase;')
      ..writeln('${view.entityInfoName}(this.attachedDatabase, '
          '[this._alias]);');

    final source = view.source;
    if (source is DartViewSource) {
      // A view may read from the same table more than once, so we implicitly
      // introduce aliases for tables.
      var tableCounter = 0;

      for (final ref in source.staticReferences) {
        final table = ref.table;
        final alias = asDartLiteral('t${tableCounter++}');

        final declaration = '${table.entityInfoName} get ${ref.name} => '
            'attachedDatabase.${table.dbGetterName}.createAlias($alias);';
        buffer.writeln(declaration);
      }
    }

    writeGetColumnsOverride();

    buffer
      ..write('@override\nString get aliasedName => '
          '_alias ?? entityName;\n')
      ..write('@override\n String get entityName=>'
          ' ${asDartLiteral(view.schemaName)};\n');

    if (source is SqlViewSource) {
      final astNode = source.parsedStatement;

      emitter.write('@override\nString get createViewStmt =>');
      if (astNode != null) {
        emitter.writeSqlAsDartLiteral(astNode);
      } else {
        emitter.write(asDartLiteral(source.createView));
      }
      buffer.writeln(';');
    } else {
      buffer.write('@override\n String? get createViewStmt => null;\n');
    }

    writeAsDslTable();
    writeMappingMethod(scope);

    for (final column in view.columns) {
      writeColumnGetter(column, false);
    }

    _writeAliasGenerator();
    _writeQuery();

    final readTables = view.transitiveTableReferences
        .map((e) => asDartLiteral(e.schemaName))
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

    final source = view.source;
    if (source is DartViewSource) {
      emitter
        ..write('(attachedDatabase.selectOnly(${source.primaryFrom?.name})'
            '..addColumns(\$columns))')
        ..writeDart(source.dartQuerySource)
        ..writeln(';');
    } else {
      buffer.writeln('null;');
    }
  }
}
