import 'package:collection/collection.dart';

import '../../analysis/results/results.dart';
import '../../utils/string_escaper.dart';
import '../utils/column_constraints.dart';
import '../utils/memoized_getter.dart';
import '../writer.dart';
import 'data_class_writer.dart';
import 'update_companion_writer.dart';

/// Common writer for tables or views.
///
/// Both classes need to generate column getters and a mapping function.
abstract class TableOrViewWriter {
  DriftElementWithResultSet get tableOrView;

  TextEmitter get emitter;

  StringBuffer get buffer => emitter.buffer;

  void writeColumnGetter(DriftColumn column, {bool isOverride = false}) {
    bool? isRequiredForInsert;

    if (tableOrView is DriftTable) {
      isRequiredForInsert =
          (tableOrView as DriftTable).isColumnRequiredForInsert(column);
    }

    final (type, expression) = instantiateColumn(
      column,
      emitter,
      isRequiredForInsert: isRequiredForInsert,
      isForTable: tableOrView is DriftTable,
    );

    writeMemoizedGetter(
      buffer: buffer,
      getterName: column.nameInDart,
      returnType: type,
      code: expression,
      hasOverride: isOverride,
    );
  }

  void writeConvertersAsStaticFields() {
    if (emitter.writer.generationOptions.avoidUserCode) {
      return;
    }

    for (final converter in tableOrView.appliedConverters) {
      if (converter.owningColumn?.owner != tableOrView) continue;

      final typeName =
          emitter.dartCode(emitter.writer.converterType(converter));
      final code = emitter.dartCode(converter.expression);
      buffer.write('static $typeName ${converter.fieldName} = $code;');

      // Generate wrappers for non-nullable type converters that are applied to
      // nullable columns.
      final column = converter.owningColumn!;
      if (converter.canBeSkippedForNulls && column.nullable) {
        final nullableTypeName = emitter.dartCode(
            emitter.writer.converterType(converter, makeNullable: true));

        final wrap = converter.alsoAppliesToJsonConversion
            ? emitter.drift('JsonTypeConverter2.asNullable')
            : emitter.drift('NullAwareTypeConverter.wrap');

        final code = '$wrap(${converter.fieldName})';

        buffer
            .write('static $nullableTypeName ${converter.nullableFieldName} = '
                '$code;');
      }
    }
  }

  void writeMappingMethod(Scope scope) {
    final driftResultSet = emitter.drift('DriftResultSet');
    final driftRow = emitter.drift('DriftRow');

    if (!scope.generationOptions.writeDataClasses) {
      buffer.writeln('''
        @override
        Never createMapperToDart($driftResultSet resultSet) {
          throw UnsupportedError('Mapping to Dart in schema verification code');
        }
      ''');
      return;
    }

    final dataClassType = emitter.dartCode(emitter.writer.rowType(tableOrView));

    buffer
      ..writeln('@override')
      ..write('$dataClassType? Function($driftRow) createMapperToDart(')
      ..writeln('$driftResultSet resultSet) {')
      ..writeln('final columnPositions = resultSet.structure.tables[this]!;')
      ..writeln('return ($driftRow row) {');

    // We need to check whether this table is present in the row at all (it may
    // be absent for left outer joins).
    final firstNonNullableColumn =
        tableOrView.columns.indexed.firstWhereOrNull((c) => !c.$2.nullable);
    if (firstNonNullableColumn case (final index, final column)?) {
      buffer
        ..writeln(
            ' // Table not part of row if non-nullable column ${column.nameInDart} is missing')
        ..writeln('if (row.raw.rawValue(columnPositions[$index]) == null) {')
        ..writeln('return null;')
        ..writeln('}');
    }

    if (tableOrView.hasExistingRowClass) {
      final info = tableOrView.existingRowClass!;

      final writer = RowMappingWriter(
        positional: [
          for (final positional in info.positionalColumns)
            tableOrView.columnBySqlName[positional]!
        ],
        named: info.namedColumns.map((dartParameter, columnName) {
          return MapEntry(
              tableOrView.columnBySqlName[columnName]!, dartParameter);
        }),
        table: tableOrView,
        writer: scope.writer,
        databaseGetter: 'attachedDatabase',
      );

      final ctor = info.constructor;
      emitter.write('return ');
      if (!info.isRecord) {
        // Write the constructor or async mapping method for this existing row
        // class. It will later be invoked by writing the arguments below.
        // For records, the argument syntax is already a valid record literal.
        emitter.writeDart(AnnotatedDartCode.type(info.targetType));

        if (ctor.isNotEmpty) {
          buffer
            ..write('.')
            ..write(ctor);
        }
      }

      writer.writeArguments(buffer);
      buffer.write(';\n');
    } else {
      final columns = tableOrView.columns;

      final writer = RowMappingWriter(
        positional: const [],
        named: {for (final column in columns) column: column.nameInDart},
        table: tableOrView,
        writer: scope.writer,
        databaseGetter: 'attachedDatabase',
      );

      emitter
        ..write('return ')
        ..writeDart(emitter.writer.rowClass(tableOrView));
      writer.writeArguments(buffer);
      buffer.writeln(';');
    }

    buffer.write('};}\n');
  }

  void writeGetColumnsOverride() {
    final type = tableOrView is DriftTable ? 'TableColumn' : 'SchemaColumn';

    final columnsWithGetters =
        tableOrView.columns.map((c) => c.nameInDart).join(', ');
    buffer.write('@override\nList<${emitter.drift(type)}> get columns => '
        '[$columnsWithGetters];\n');
  }

  /// Returns the Dart type and the Dart expression creating a `SchemaColumn`
  /// instance in drift for the given [column].
  static (String, String) instantiateColumn(
    DriftColumn column,
    TextEmitter emitter, {
    bool isForTable = false,
    bool? isRequiredForInsert,
  }) {
    final namedParameters = <String, String>{
      'name': asDartLiteral(column.nameInSql),
      'type': switch (column.sqlType) {
        ColumnDriftType(:final builtin) => emitter.drift(builtin.toString()),
        ColumnCustomType(:final custom) => emitter.dartCode(custom.expression),
      },
      'isNullable': column.nullable.toString(),
    };
    final expressionBuffer = StringBuffer();
    final constraints = defaultConstraints(emitter.writer.options, column);

    for (final constraint in column.constraints) {
      if (constraint is LimitingTextLength) {
        final buffer =
            StringBuffer(emitter.drift('GeneratedColumn.checkTextLength('));

        if (constraint.minLength != null) {
          buffer.write('minTextLength: ${constraint.minLength},');
        }
        if (constraint.maxLength != null) {
          buffer.write('maxTextLength: ${constraint.maxLength}');
        }
        buffer.write(')');

        namedParameters['additionalChecks'] = buffer.toString();
      }

      if (constraint is DartCheckExpression) {
        final dartCheck = emitter.dartCode(constraint.dartExpression);
        namedParameters['check'] = '() => $dartCheck';
      }

      if (constraint is ColumnGeneratedAs) {
        final dartCode = emitter.dartCode(constraint.dartExpression);

        namedParameters['generatedAs'] =
            '${emitter.drift('GeneratedAs')}($dartCode, ${constraint.stored})';
      }
    }

    if (isRequiredForInsert != null) {
      namedParameters['requiredDuringInsert'] = isRequiredForInsert.toString();
    }

    if (column.customConstraints != null) {
      namedParameters['\$customConstraints'] =
          asDartLiteral(column.customConstraints!);
    } else if (constraints.values.any((constraint) => constraint.isNotEmpty)) {
      // Use the default constraints supported by drift

      if (constraints.values.any(
        (value) => value != constraints.values.first,
      )) {
        // One or more constraints are different depending on dialect, generate
        // per-dialect constraints

        final literalEntries = [
          for (final entry in constraints.entries)
            '${emitter.drift('SqlDialect.${entry.key.name}')}: ${asDartLiteral(entry.value)},',
        ];

        namedParameters['defaultConstraints'] =
            '${emitter.drift('GeneratedColumn.constraintsDependsOnDialect')}({${literalEntries.join('\n')}})';
      } else {
        // Constraints are the same regardless of dialect, only generate one set
        // of them

        final constraint = asDartLiteral(constraints.values.first);

        namedParameters['defaultConstraints'] =
            '${emitter.drift('GeneratedColumn.constraintIsAlways')}($constraint)';
      }
    }

    if (column.defaultArgument != null) {
      namedParameters['defaultValue'] =
          emitter.dartCode(column.defaultArgument!);
    }

    if (column.clientDefaultCode != null &&
        !emitter.writer.generationOptions.avoidUserCode) {
      namedParameters['clientDefault'] =
          emitter.dartCode(column.clientDefaultCode!);
    }

    final innerType = emitter.innerColumnType(column.sqlType);
    var type =
        '${emitter.drift(isForTable ? 'TableColumn' : 'SchemaColumn')}<${emitter.dartCode(innerType)}>';

    expressionBuffer
      ..write(type)
      ..write('(');

    var first = true;
    namedParameters.forEach((name, value) {
      if (!first) {
        expressionBuffer.write(', ');
      } else {
        first = false;
      }

      expressionBuffer
        ..write(name)
        ..write(': ')
        ..write(value);
    });

    expressionBuffer.write(')');

    final converter = column.typeConverter;
    if (converter != null && !emitter.writer.generationOptions.avoidUserCode) {
      // Generate a GeneratedColumnWithTypeConverter instance, as it has
      // additional methods to check for equality against a mapped value.
      final mappedType = emitter.dartCode(emitter.writer.dartType(column));

      final converterCode = emitter.dartCode(emitter.writer
          .readConverter(converter, forNullable: column.nullable));

      type = '${emitter.drift('GeneratedColumnWithTypeConverter')}'
          '<$mappedType, ${emitter.dartCode(innerType)}>';
      expressionBuffer
        ..write('.withConverter<')
        ..write(mappedType)
        ..write('>(')
        ..write(converterCode)
        ..write(')');
    }

    expressionBuffer.write('..owningResultSet = this');
    return (type, expressionBuffer.toString());
  }

  void writeAsSelfType() {
    emitter.writeln(
        '@override\n${tableOrView.entityInfoName} asSelfType() => this;\n');
  }
}

class TableWriter extends TableOrViewWriter {
  final DriftTable table;
  final Scope scope;

  @override
  late TextEmitter emitter;

  @override
  DriftTable get tableOrView => table;

  TableWriter(this.table, this.scope);

  void writeInto() {
    emitter = scope.leaf();

    writeDataClass();
    writeTableInfoClass();
  }

  void writeDataClass() {
    if (scope.generationOptions.writeDataClasses) {
      if (scope.options.writeToColumnsMixins) {
        writeToColumnsMixin();
      }

      final existing = table.existingRowClass;
      if (existing != null) {
        // We don't have to write a row class if we're using one provided by the
        // user. However, if the existing row type is a record, it is helpful
        // to generate a typedef for it.
        if (existing.isRecord) {
          emitter
            ..write('typedef ${table.nameOfRowClass} = ')
            ..writeDart(AnnotatedDartCode.type(existing.targetType))
            ..write(';');
        }
      } else {
        DataClassWriter(table, scope.child()).write();
      }
    }

    if (scope.generationOptions.writeCompanions) {
      UpdateCompanionWriter(table, scope.child()).write();
    }
  }

  void writeTableInfoClass() {
    if (!scope.generationOptions.writeDataClasses) {
      // Write a small table header without data class
      buffer
        ..write('class ${table.entityInfoName} extends ')
        ..write(emitter.drift('Table'))
        ..write(' with ')
        ..write(emitter.drift('ResultSet'))
        ..write(' implements ')
        ..write(emitter.drift('GeneratedTable'));
      if (table.isVirtual) {
        buffer.write(', ${emitter.drift('VirtualTableInfo')}');
      }
    } else {
      // Regular generation, write full table class
      final dataClass = emitter.dartCode(emitter.writer.rowType(table));
      final tableDslName = table.definingDartClass ??
          AnnotatedDartCode.importedSymbol(AnnotatedDartCode.drift, 'Table');

      // class UsersTable extends Users implements with ResultSet<User, Users> implements GeneratedTable<User, Users> {
      final typeArgs = '<$dataClass, ${table.entityInfoName}>';

      emitter
        ..write('class ${table.entityInfoName} extends ')
        ..writeDart(tableDslName)
        ..write(' with ')
        ..writeDriftRef('ResultSet')
        ..write(typeArgs)
        ..write(' implements ')
        ..writeDriftRef('GeneratedTable')
        ..write(typeArgs);

      if (table.isVirtual) {
        buffer.write(', ${emitter.drift('VirtualTableInfo')}$typeArgs ');
      }
    }

    buffer
      ..writeln('{')
      ..writeln('@override')
      ..writeln('final String? alias;')
      ..writeln('${table.entityInfoName}([this.alias]);');
    ;

    // Generate the columns
    for (final column in table.columns) {
      // Only add an @override to a column getter if we're overriding the column
      // from a Dart DSL class.
      writeColumnGetter(column, isOverride: table.id.isDefinedInDart);
    }

    // Generate $columns, $tableName, asDslTable getters
    writeGetColumnsOverride();
    buffer
      ..write('@override\nString get entityName => \$name;')
      ..write('static const String \$name = \'${table.id.name}\';\n');

    writeAsSelfType();
    _writePrimaryKeyOverride();
    _writeUniqueKeyOverride();

    writeMappingMethod(scope);
    // _writeReverseMappingMethod();

    _writeAliasGenerator();

    writeConvertersAsStaticFields();
    _overrideFieldsIfNeeded();

    // close class
    buffer.write('}');
  }

  void writeToColumnsMixin() {
    buffer.write('mixin ${table.toColumnsMixin} ');

    final type = emitter.dartCode(emitter.writer.rowType(table));
    buffer.writeln('implements ${emitter.drift('Insertable')}<$type> {');

    for (final column in table.columns) {
      if (column.documentationComment != null) {
        buffer.write('${column.documentationComment}\n');
      }
      final typeName = emitter.dartCode(emitter.dartType(column));
      buffer.writeln('$typeName get ${column.nameInDart};');
    }

    emitter.writeToColumnsOverride(table.columns);
    buffer.write('}');
  }

  void _writePrimaryKeyOverride() {
    buffer.write(
        '@override\nSet<${emitter.drift('TableColumn')}> get primaryKey => ');
    final primaryKey = table.fullPrimaryKey;

    if (primaryKey.isEmpty) {
      buffer.write('const {};');
      return;
    }

    buffer.write('{');
    final pkList = primaryKey.toList();
    for (var i = 0; i < pkList.length; i++) {
      final pk = pkList[i];

      buffer.write(pk.nameInDart);
      if (i != pkList.length - 1) {
        buffer.write(', ');
      }
    }
    buffer.write('};\n');
  }

  void _writeUniqueKeyOverride() {
    final uniqueKeys =
        table.tableConstraints.whereType<UniqueColumns>().toList();

    if (uniqueKeys.isEmpty) {
      // We inherit from `TableInfo` which defaults this getter to an empty
      // list.
      return;
    }

    buffer.write('@override\nList<Set<${emitter.drift('GeneratedColumn')}>> '
        'get uniqueKeys => [');

    for (final uniqueKey in uniqueKeys) {
      buffer.write('{');
      final uqList = uniqueKey.uniqueSet.toList();
      for (var i = 0; i < uqList.length; i++) {
        final pk = uqList[i];

        buffer.write(pk.nameInDart);
        if (i != uqList.length - 1) {
          buffer.write(', ');
        }
      }
      buffer.write('},\n');
    }
    buffer.write('];\n');
  }

  void _writeAliasGenerator() {
    final typeName = table.entityInfoName;

    buffer
      ..write('@override\n')
      ..write('$typeName withAlias(String alias) {\n')
      ..write('return $typeName(alias);')
      ..write('}');
  }

  void _overrideFieldsIfNeeded() {
    if (table.withoutRowId) {
      buffer
        ..writeln('@override')
        ..writeln('bool get withoutRowId => true;');
    }

    if (table.strict) {
      buffer
        ..write('@override\n')
        ..write('bool get isStrict => true;\n');
    }

    // For Dart tables, the user already overrides the `customConstraints`
    // getter in the source. So, since we extend that class by default, there's
    // no need to override them again.
    final writeTableConstraints = table.definingDartClass == null ||
        scope.generationOptions.forSchema != null;
    if (writeTableConstraints && table.overrideTableConstraints.isNotEmpty) {
      final value =
          table.overrideTableConstraints.map(asDartLiteral).join(', ');

      buffer
        ..write('@override\n')
        ..write('List<String> get customConstraints => const [$value];\n');
    }

    if (!table.writeDefaultConstraints) {
      buffer
        ..write('@override\n')
        ..write('bool get dontWriteConstraints => true;\n');
    }

    if (table.isVirtual) {
      final stmt = table.virtualTableData!;
      final moduleAndArgs = asDartLiteral(stmt.moduleAndArgs);
      buffer
        ..write('@override\n')
        ..write('String get moduleAndArgs => $moduleAndArgs;\n');
    }
  }
}
