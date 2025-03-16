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

    final viewClassName = emitter.dartCode(emitter.entityInfoType(view));
    final dataClass = emitter.dartCode(emitter.rowType(view));
    final typeArgs = scope.generationOptions.writeDataClasses
        ? '<$dataClass, $viewClassName>'
        : '<Never, $viewClassName>';
    final viewDslName = view.definingDartClass ??
        AnnotatedDartCode.importedSymbol(AnnotatedDartCode.drift, 'View');
    final dbClassName =
        databaseWriter?.dbClassName ?? emitter.drift('GeneratedDatabase');

    emitter
      ..write('class ${view.entityInfoName} extends ')
      ..writeDart(viewDslName)
      ..write(' with ')
      ..writeDriftRef('ResultSet')
      ..write(typeArgs)
      ..write(' implements ')
      ..writeDriftRef('GeneratedView')
      ..write(typeArgs)
      ..writeln('{');

    buffer
      ..writeln('@override')
      ..writeln('final String? alias;')
      ..writeln('final $dbClassName _attachedDatabase;')
      ..writeln(
          '${view.entityInfoName}(this._attachedDatabase, [this.alias]);');

    final source = view.source;
    if (source is DartViewSource) {
      // A view may read from the same table more than once, so we implicitly
      // introduce aliases for tables.
      var tableCounter = 0;

      for (final ref in source.staticReferences) {
        final table = ref.table;
        final alias = asDartLiteral('t${tableCounter++}');

        emitter
          ..writeDart(emitter.entityInfoType(table))
          ..write(' get ${ref.name} => ')
          ..writeDart(emitter.referenceElement(ref.table, '_attachedDatabase'))
          ..writeln('.withAlias($alias);');
      }
    } else {
      emitter
        ..writeln('@override')
        ..writeDriftRef('BaseSelectStatement')
        ..write(' as() => throw UnimplementedError();');
    }

    writeGetColumnsOverride();

    buffer.write('@override\n String get entityName=>'
        ' ${asDartLiteral(view.schemaName)};\n');

    writeAsSelfType();
    writeMappingMethod(scope);

    for (final column in view.columns) {
      writeColumnGetter(column);
    }

    _writeAliasGenerator();
    _writeQuery();
    _writeDefinition();

    final readTables = view.transitiveTableReferences
        .map((e) => asDartLiteral(e.schemaName))
        .join(', ');
    buffer.writeln('''
      @override
      Set<String> get readsFrom => const {$readTables};
    ''');

    writeConvertersAsStaticFields();

    buffer.writeln('}');
  }

  void _writeAliasGenerator() {
    final typeName = view.entityInfoName;

    buffer
      ..write('@override\n')
      ..write('$typeName withAlias(String alias) {\n')
      ..write('return $typeName(_attachedDatabase, alias);')
      ..write('}');
  }

  void _writeDefinition() {
    final source = view.source;

    emitter
      ..writeln('@override')
      ..write(emitter.drift('CustomComponent'))
      ..write(source is! SqlViewSource ? '?' : '')
      ..write(' get sqlDefinition => ');

    if (source case final SqlViewSource sql) {
      emitter.writeDart(emitter.customComponent(sql.parsedStatement!));
    } else {
      emitter.write('null');
    }

    emitter.writeln(';');
  }

  void _writeQuery() {
    buffer
        .write('@override\n${emitter.drift('SelectStatement')}? get query => ');

    final source = view.source;
    if (source is DartViewSource) {
      emitter
        ..write(
            '(_attachedDatabase.selectOnly(${scope.options.assumeCorrectReference ? source.primaryFrom?.name ?? source.staticSource : source.primaryFrom?.name})'
            '..addColumns(columns))')
        ..writeDart(source.dartQuerySource)
        ..writeln(';');
    } else {
      buffer.writeln('null;');
    }
  }
}
