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

    buffer.write(
        'class ${view.entityInfoName} extends ${emitter.drift('ViewInfo')}');
    if (scope.generationOptions.writeDataClasses) {
      final viewClassName = emitter.dartCode(emitter.entityInfoType(view));
      emitter
        ..write('<$viewClassName, ')
        ..writeDart(emitter.rowType(view))
        ..write('>');
    } else {
      buffer.write('<${view.entityInfoName}, Never>');
    }
    buffer.writeln(' implements ${emitter.drift('HasResultSet')} {');

    final dbClassName =
        databaseWriter?.dbClassName ?? emitter.drift('GeneratedDatabase');
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

    emitter
      ..writeln('@override')
      ..write('Map<${emitter.drift('SqlDialect')}, String>')
      ..write(source is! SqlViewSource ? '?' : '')
      ..write('get createViewStatements => ');
    if (source is SqlViewSource) {
      final astNode = source.parsedStatement;

      if (astNode != null) {
        emitter.writeSqlByDialectMap(astNode);
      } else {
        final firstDialect = scope.options.supportedDialects.first;

        emitter
          ..write('{')
          ..writeDriftRef('SqlDialect')
          ..write('.${firstDialect.name}: ')
          ..write(asDartLiteral(source.sqlCreateViewStmt))
          ..write('}');
      }
      buffer.writeln(';');
    } else {
      buffer.writeln('null;');
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

    writeConvertersAsStaticFields();
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
    buffer.write('@override\n${emitter.drift('Query?')} get query => ');

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
