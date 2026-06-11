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
    final dataClass = scope.generationOptions.writeDataClasses
        ? emitter.dartCode(emitter.rowType(view))
        : 'Never';

    if (scope.drift3) {
      final typeArgs = '<$dataClass, $viewClassName>';
      final viewDslName = view.definingDartClass;

      emitter
        ..write('class ${view.entityInfoName}')
        ..write(
          viewDslName != null ? ' extends ${scope.dartCode(viewDslName)}' : '',
        )
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
        ..writeln('${view.entityInfoName}([this.alias]);');
    } else {
      emitter
        ..write(
          'class ${view.entityInfoName} extends ${emitter.drift('ViewInfo')}',
        )
        ..write('<$viewClassName, $dataClass>')
        ..writeln(' implements ${emitter.drift('HasResultSet')} {');

      final dbClassName =
          databaseWriter?.dbClassName ?? emitter.drift('GeneratedDatabase');
      buffer
        ..writeln('final String? _alias;')
        ..writeln('@override final $dbClassName $_attachedDatabase;')
        ..writeln(
          '${view.entityInfoName}(this.$_attachedDatabase, '
          '[this._alias]);',
        );
    }

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
          ..writeDart(emitter.referenceElement(ref.table, _attachedDatabase))
          ..writeln(
            scope.drift3 ? '.withAlias($alias);' : '.createAlias($alias);',
          );
      }
    }

    writeGetColumnsOverride();

    if (!scope.drift3) {
      buffer.write(
        '@override\nString get aliasedName => '
        '_alias ?? entityName;\n',
      );
    }

    buffer.write(
      '@override\n String get entityName=>'
      ' ${asDartLiteral(view.schemaName)};\n',
    );

    if (scope.drift3) {
      _writeDrift3SqlDefinition();
      writeAsSelfType();
    } else {
      _writeCreateViewStatements();
      writeAsDslTable();
    }

    writeMappingMethod(scope);

    for (final column in view.columns) {
      writeColumnGetter(column, false);
    }

    _writeAliasGenerator();
    _writeQuery();

    final readTables = view.transitiveTableReferences
        .map((e) => asDartLiteral(e.schemaName))
        .join(', ');
    final readTablesGetterName = scope.drift3 ? 'readsFrom' : 'readTables';
    buffer.writeln('''
      @override
      Set<String> get $readTablesGetterName => const {$readTables};
    ''');

    writeConvertersAsStaticFields();
    buffer.writeln('}');
  }

  void _writeCreateViewStatements() {
    final source = view.source;
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
  }

  void _writeDrift3SqlDefinition() {
    final source = view.source;
    emitter.writeln('@override');

    if (source is SqlViewSource) {
      final astNode = source.parsedStatement;

      emitter
        ..writeDriftRef('CustomComponent')
        ..write('? get sqlDefinition => ');

      if (astNode != null) {
        emitter.writeDart(emitter.customComponent(astNode));
      } else {
        emitter
          ..writeDriftRef('CustomComponent')
          ..write('(')
          ..write(asDartLiteral(source.sqlCreateViewStmt))
          ..write(')');
      }
      buffer.writeln(';');
    } else {
      emitter.writeln('Null get sqlDefinition => null;');
    }
  }

  void _writeAliasGenerator() {
    final typeName = view.entityInfoName;
    final methodName = scope.drift3 ? 'withAlias' : 'createAlias';
    buffer
      ..writeln('@override')
      ..write('$typeName $methodName(String alias) {\n')
      ..write(
        scope.drift3
            ? 'return $typeName(alias);'
            : 'return $typeName($_attachedDatabase, alias);',
      )
      ..writeln('}');
  }

  void _writeQuery() {
    final queryClass = scope.drift3 ? 'SelectStatement' : 'Query';
    buffer.write('@override\n${emitter.drift(queryClass)}? get query => ');

    final source = view.source;
    if (source is DartViewSource) {
      final columnsGetter = scope.drift3 ? 'columns' : r'$columns';
      final selectOnlyMethod = scope.drift3
          ? '${scope.drift('GeneratedView')}.defineStatementForView'
          : '$_attachedDatabase.selectOnly';

      emitter
        ..write(
          '($selectOnlyMethod(${scope.options.assumeCorrectReference ? source.primaryFrom?.name ?? source.staticSource : source.primaryFrom?.name})'
          '..addColumns($columnsGetter))',
        )
        ..writeDart(source.dartQuerySource)
        ..writeln(';');
    } else {
      buffer.writeln('null;');
    }
  }

  String get _attachedDatabase => scope.drift3 ? 'db' : 'attachedDatabase';
}
