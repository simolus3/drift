import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show DriftSqlType, UpdateKind;
import 'package:sqlparser/sqlparser.dart' show ReferenceAction;

import 'driver/driver.dart';
import 'driver/state.dart';
import 'results/results.dart';

class SerializedElements {
  final List<AnnotatedDartCode> dartTypes;
  final Map<String, Object?> serializedData;
  final Map<String, Object?> _serializedElements;

  SerializedElements(
      this.dartTypes, this.serializedData, this._serializedElements) {
    serializedData['elements'] = _serializedElements;
  }
}

/// Serializes [DriftElement]s to JSON.
///
/// By first analyzing elements and later generating code, drift's build setup
/// is more efficient and incremental (as not everything is analyzed again if
/// a single file changes). However, it means that we have to serialize analysis
/// results to read them back in in a later build step.
class ElementSerializer {
  final SerializedElements _result = SerializedElements([], {}, {});

  ElementSerializer._();

  void _serializeElements(Iterable<DriftElement> elements) {
    for (final element in elements) {
      _result._serializedElements[element.id.name] = _serialize(element);
    }
  }

  Map<String, Object?> _serialize(DriftElement element) {
    Map<String, Object?> additionalInformation;

    if (element is DriftTable) {
      additionalInformation = {
        'type': 'table',
        'columns': [
          for (final column in element.columns) _serializeColumn(column),
        ],
        'existing_data_class': element.existingRowClass != null
            ? _serializeExistingRowClass(element.existingRowClass!)
            : null,
        'table_constraints': [
          for (final constraint in element.tableConstraints)
            _serializeTableConstraint(constraint),
        ],
        'custom_parent_class': element.customParentClass?.toJson(),
        'fixed_entity_info_name': element.fixedEntityInfoName,
        'base_dart_name': element.baseDartName,
        'row_class_name': element.nameOfRowClass,
        'without_rowid': element.withoutRowId,
        'strict': element.strict,
        if (element.isVirtual)
          'virtual': _serializeVirtualTableData(element.virtualTableData!),
        'write_default_constraints': element.writeDefaultConstraints,
        'custom_constraints': element.overrideTableConstraints,
        'attached_indices': element.attachedIndices,
      };
    } else if (element is DriftIndex) {
      additionalInformation = {
        'type': 'index',
        'sql': element.createStmt,
        'columns': [
          for (final column in element.indexedColumns) column.nameInSql,
        ],
        'unique': element.unique,
      };
    } else if (element is DefinedSqlQuery) {
      final existingDartType = element.existingDartType;

      additionalInformation = {
        'type': 'query',
        'sql': element.sql,
        'offset': element.sqlOffset,
        'result_class': element.resultClassName,
        'existing_type': existingDartType != null
            ? {
                'type': _serializeType(existingDartType.type),
                'constructor_name': existingDartType.constructorName,
              }
            : null,
        'mode': element.mode.name,
        'dart_tokens': element.dartTokens,
        'dart_types': {
          for (final entry in element.dartTypes.entries)
            entry.key: _serializeType(entry.value)
        },
      };
    } else if (element is DriftTrigger) {
      additionalInformation = {
        'type': 'trigger',
        'sql': element.createStmt,
        if (element.on != null) 'on': _serializeElementReference(element.on!),
        'onWrite': element.onWrite.name,
        'writes': [
          for (final write in element.writes)
            {
              'table': _serializeElementReference(write.table),
              'kind': write.kind.name,
            }
        ],
      };
    } else if (element is DriftView) {
      Object? serializedSource;

      final source = element.source;
      if (source is SqlViewSource) {
        serializedSource = {
          'kind': 'sql',
          'sql': source.sqlCreateViewStmt,
          'schema_sql': source.sqlCreateViewStmt,
        };
      } else if (source is DartViewSource) {
        serializedSource = {
          'kind': 'dart',
          'query': source.dartQuerySource.toJson(),
          'primaryFrom': source.primaryFrom != null
              ? _serializeTableReferenceInDartView(source.primaryFrom!)
              : null,
          'staticReferences': [
            for (final reference in source.staticReferences)
              _serializeTableReferenceInDartView(reference),
          ]
        };
      }

      additionalInformation = {
        'type': 'view',
        'columns': [
          for (final column in element.columns) _serializeColumn(column),
        ],
        'entity_info_name': element.entityInfoName,
        'existing_data_class': element.existingRowClass != null
            ? _serializeExistingRowClass(element.existingRowClass!)
            : null,
        'custom_parent_class': element.customParentClass?.toJson(),
        'name_of_row_class': element.nameOfRowClass,
        'source': serializedSource,
      };
    } else if (element is BaseDriftAccessor) {
      String type;

      if (element is DriftDatabase) {
        type = 'database';
      } else {
        type = 'dao';
      }

      additionalInformation = {
        'type': type,
        'tables': [
          for (final table in element.declaredTables)
            _serializeElementReference(table),
        ],
        'views': [
          for (final view in element.declaredViews)
            _serializeElementReference(view),
        ],
        'includes': [
          for (final include in element.declaredIncludes) include.toString()
        ],
        'queries': element.declaredQueries,
        if (element is DatabaseAccessor) ...{
          'dart_type': element.ownType.toJson(),
          'database': element.databaseClass.toJson(),
        },
        if (element is DriftDatabase) ...{
          'schema_version': element.schemaVersion,
          'daos': [
            for (final dao in element.accessors) _serializeElementReference(dao)
          ],
        }
      };
    } else {
      throw UnimplementedError('Unknown element $element');
    }

    return {
      'id': element.id.toJson(),
      'declaration': element.declaration.toJson(),
      'references': [
        for (final referenced in element.references)
          _serializeElementReference(referenced),
      ],
      ...additionalInformation,
    };
  }

  Map<String, Object?> _serializeColumnType(ColumnType type) {
    final custom = type.custom;

    return {
      if (custom != null)
        'custom': {
          'dart': _serializeType(custom.dartType),
          'expression': custom.expression.toJson(),
        }
      else
        'builtin': type.builtin.name,
    };
  }

  Map<String, Object?> _serializeColumn(DriftColumn column) {
    return {
      'sqlType': _serializeColumnType(column.sqlType),
      'nullable': column.nullable,
      'nameInSql': column.nameInSql,
      'nameInDart': column.nameInDart,
      'declaration': column.declaration.toJson(),
      'typeConverter': column.typeConverter != null
          ? _serializeTypeConverter(column, column.typeConverter!)
          : null,
      'clientDefaultCode': column.clientDefaultCode?.toJson(),
      'defaultArgument': column.defaultArgument?.toJson(),
      'overriddenJsonName': column.overriddenJsonName,
      'documentationComment': column.documentationComment,
      'constraints': [
        for (final constraint in column.constraints)
          _serializeColumnConstraint(constraint),
      ],
      'customConstraints': column.customConstraints,
    };
  }

  Map<String, Object?> _serializeColumnConstraint(
      DriftColumnConstraint constraint) {
    if (constraint is UniqueColumn) {
      return {'type': 'unique'};
    } else if (constraint is PrimaryKeyColumn) {
      return {'type': 'primary', ...constraint.toJson()};
    } else if (constraint is ForeignKeyReference) {
      return {
        'type': 'foreign_key',
        'column': _serializeColumnReference(constraint.otherColumn),
        'onUpdate': _serializeReferenceAction(constraint.onUpdate),
        'onDelete': _serializeReferenceAction(constraint.onDelete),
      };
    } else if (constraint is ColumnGeneratedAs) {
      return {'type': 'generated_as', ...constraint.toJson()};
    } else if (constraint is DartCheckExpression) {
      return {'type': 'check', ...constraint.toJson()};
    } else if (constraint is LimitingTextLength) {
      return {'type': 'limit_text_length', ...constraint.toJson()};
    } else {
      throw UnimplementedError('Unsupported column constraint: $constraint');
    }
  }

  Map<String, Object?> _serializeTableConstraint(
      DriftTableConstraint constraint) {
    if (constraint is UniqueColumns) {
      return {
        'type': 'unique',
        'columns': [for (final column in constraint.uniqueSet) column.nameInSql]
      };
    } else if (constraint is PrimaryKeyColumns) {
      return {
        'type': 'primary_key',
        'columns': [
          for (final column in constraint.primaryKey) column.nameInSql,
        ],
      };
    } else if (constraint is ForeignKeyTable) {
      return {
        'type': 'foreign',
        'local': [
          for (final column in constraint.localColumns) column.nameInSql,
        ],
        'table': _serializeElementReference(constraint.otherTable),
        'foreign': [
          for (final column in constraint.otherColumns)
            _serializeColumnReference(column),
        ],
        'onUpdate': _serializeReferenceAction(constraint.onUpdate),
        'onDelete': _serializeReferenceAction(constraint.onDelete),
      };
    } else {
      throw UnimplementedError('Unsupported table constraint: $constraint');
    }
  }

  Map<String, Object?> _serializeVirtualTableData(VirtualTableData data) {
    final recognized = data.recognized;
    Object? serializedRecognized;

    if (recognized is DriftFts5Table) {
      serializedRecognized = {
        'type': 'fts5',
        'content_table': (recognized.externalContentTable != null)
            ? _serializeElementReference(recognized.externalContentTable!)
            : null,
        'content_rowid': (recognized.externalContentRowId != null)
            ? _serializeColumnReference(recognized.externalContentRowId!)
            : null,
      };
    }

    return {
      'module': data.module,
      'arguments': data.moduleArguments,
      'recognized': serializedRecognized,
    };
  }

  String? _serializeReferenceAction(ReferenceAction? action) {
    return action?.name;
  }

  Map<String, Object?> _serializeTypeConverter(
      DriftColumn appliedTo, AppliedTypeConverter converter) {
    return {
      'expression': converter.expression.toJson(),
      'dart_type': _serializeType(converter.dartType),
      'json_type': _serializeType(converter.jsonType),
      'sql_type': _serializeColumnType(converter.sqlType),
      'dart_type_is_nullable': converter.dartTypeIsNullable,
      'sql_type_is_nullable': converter.sqlTypeIsNullable,
      'is_drift_enum_converter': converter.isDriftEnumTypeConverter,
      if (converter.owningColumn != appliedTo)
        'owner': _serializeColumnReference(converter.owningColumn!),
    };
  }

  Map<String, Object?> _serializeExistingRowClass(ExistingRowClass existing) {
    return {
      'target_class': existing.targetClass?.toJson(),
      'target_type': _serializeType(existing.targetType),
      'constructor': existing.constructor,
      'is_async_factory': existing.isAsyncFactory,
      'positional': existing.positionalColumns,
      'named': existing.namedColumns,
      'generate_insertable': existing.generateInsertable,
    };
  }

  Map<String, Object?> _serializeElementReference(DriftElement element) {
    return element.id.toJson();
  }

  Map<String, Object?> _serializeColumnReference(DriftColumn column) {
    return {
      'table': _serializeElementReference(column.owner),
      'name': column.nameInSql,
    };
  }

  Map<String, Object?> _serializeTableReferenceInDartView(
      TableReferenceInDartView ref) {
    return {
      'table': _serializeElementReference(ref.table),
      'name': ref.name,
    };
  }

  int? _serializeType(DartType? type) {
    if (type == null) return null;

    final code = AnnotatedDartCode.type(type);
    final index = _result.dartTypes.length;
    _result.dartTypes.add(code);

    return index;
  }

  static SerializedElements serialize(Iterable<DriftElement> elements) {
    return (ElementSerializer._().._serializeElements(elements))._result;
  }
}

/// Deserializes the element structure emitted by [ElementSerializer].
class ElementDeserializer {
  final List<DriftElementId> _currentlyReading;

  final DriftAnalysisDriver driver;

  ElementDeserializer(this.driver, this._currentlyReading);

  Future<DartType> _readDartType(Uri import, int typeId) async {
    LibraryElement? element;
    final helpers = driver.cache.typeHelperLibraries;

    if (helpers.containsKey(import)) {
      element = helpers[import];
    } else {
      element =
          helpers[import] = await driver.cacheReader!.readTypeHelperFor(import);
    }

    if (element == null) {
      throw ArgumentError('Unknown serialized type: Helper does not exist.');
    }

    final typedef = element.exportNamespace.get('T$typeId') as TypeAliasElement;

    return typedef.aliasedType;
  }

  Future<DriftElement> _readElementReference(Map json) async {
    final id = DriftElementId.fromJson(json);

    if (_currentlyReading.contains(id)) {
      throw StateError(
          'Circular error when deserializing drift modules. This is a '
          'bug in drift_dev!');
    }

    _currentlyReading.add(id);

    try {
      return await readDriftElement(DriftElementId.fromJson(json));
    } finally {
      final lastId = _currentlyReading.removeLast();
      assert(lastId == id);
    }
  }

  Future<DriftElement> readDriftElement(DriftElementId id) async {
    assert(_currentlyReading.last == id);

    final state = driver.cache.stateForUri(id.libraryUri).analysis[id] ??=
        ElementAnalysisState(id);
    if (state.result != null && state.isUpToDate) {
      return state.result!;
    }

    final data = await driver.readStoredAnalysisResult(id.libraryUri);
    if (data == null) {
      throw CouldNotDeserializeException(
          'Analysis data for ${id.libraryUri} not found');
    }

    try {
      final result = await _readDriftElement(data[id.name] as Map);
      state
        ..result = result
        ..isUpToDate = true;

      return result;
    } catch (e, s) {
      if (e is CouldNotDeserializeException) rethrow;

      throw CouldNotDeserializeException(
          'Internal error while deserializing $id: $e at \n$s');
    }
  }

  Future<DriftColumn> _readDriftColumnReference(Map json) async {
    final table =
        (await _readElementReference(json['table'] as Map)) as DriftTable;
    final name = json['name'] as String;

    return table.columns.singleWhere((c) => c.nameInSql == name);
  }

  Future<DriftElement> _readDriftElement(Map json) async {
    final type = json['type'] as String;
    final id = DriftElementId.fromJson(json['id'] as Map);
    final declaration = DriftDeclaration.fromJson(json['declaration'] as Map);
    final references = <DriftElement>[
      for (final reference in json.list('references'))
        await _readElementReference(reference as Map),
    ];

    switch (type) {
      case 'table':
        final columns = [
          for (final rawColumn in json['columns'] as List)
            await _readColumn(rawColumn as Map, id),
        ];
        final columnByName = {
          for (final column in columns) column.nameInSql: column,
        };

        VirtualTableData? virtualTableData;
        if (json['virtual'] != null) {
          final data = json['virtual'] as Map;

          RecognizedVirtualTableModule? recognizedModule;
          final rawRecognized = data['recognized'];
          if (rawRecognized != null) {
            final rawTable = (rawRecognized as Map)['content_table'];
            final rawRowid = rawRecognized['content_rowid'];

            recognizedModule = DriftFts5Table(
              rawTable != null
                  ? await _readElementReference(rawTable as Map) as DriftTable
                  : null,
              rawRowid != null
                  ? await _readDriftColumnReference(rawRowid as Map)
                  : null,
            );
          }

          virtualTableData = VirtualTableData(
            data['module'] as String,
            (data['arguments'] as List).cast(),
            recognizedModule,
          );
        }

        final table = DriftTable(
          id,
          declaration,
          references: references,
          columns: columns,
          existingRowClass: json['existing_data_class'] != null
              ? await _readExistingRowClass(
                  id.libraryUri, json['existing_data_class'] as Map)
              : null,
          tableConstraints: [
            for (final constraint in json.list('table_constraints'))
              await _readTableConstraint(constraint as Map, columnByName),
          ],
          customParentClass: json['custom_parent_class'] != null
              ? AnnotatedDartCode.fromJson(json['custom_parent_class'] as Map)
              : null,
          fixedEntityInfoName: json['fixed_entity_info_name'] as String?,
          baseDartName: json['base_dart_name'] as String,
          nameOfRowClass: json['row_class_name'] as String,
          withoutRowId: json['without_rowid'] as bool,
          strict: json['strict'] as bool,
          virtualTableData: virtualTableData,
          writeDefaultConstraints: json['write_default_constraints'] as bool,
          overrideTableConstraints: json['custom_constraints'] != null
              ? (json['custom_constraints'] as List).cast()
              : const [],
          attachedIndices: (json['attached_indices'] as List).cast(),
        );

        for (final column in columns) {
          for (var i = 0; i < column.constraints.length; i++) {
            final constraint = column.constraints[i];

            if (constraint is _PendingReferenceToOwnTable) {
              column.constraints[i] = ForeignKeyReference(
                columns.singleWhere(
                    (e) => e.nameInSql == constraint.referencedColumn),
                constraint.onUpdate,
                constraint.onDelete,
              );
            }
          }
        }

        return table;
      case 'index':
        final onTable = references.whereType<DriftTable>().firstOrNull;

        return DriftIndex(
          id,
          declaration,
          table: onTable,
          createStmt: json['sql'] as String?,
          indexedColumns: [
            for (final entry in json['columns'] as List)
              onTable!.columnBySqlName[entry as String]!,
          ],
          unique: json['unique'] as bool,
        );
      case 'query':
        final types = <String, DartType>{};

        for (final entry in (json['dart_types'] as Map).entries) {
          types[entry.key as String] =
              await _readDartType(id.libraryUri, entry.value as int);
        }

        RequestedQueryResultType? existingDartType;

        final rawExistingType = json['existing_type'];
        if (rawExistingType != null) {
          existingDartType = RequestedQueryResultType(
            await _readDartType(id.libraryUri, rawExistingType['type'] as int),
            rawExistingType['constructor_name'] as String?,
          );
        }

        return DefinedSqlQuery(
          id,
          declaration,
          references: references,
          sql: json['sql'] as String,
          sqlOffset: json['offset'] as int,
          resultClassName: json['result_class'] as String?,
          existingDartType: existingDartType,
          mode: QueryMode.values.byName(json['mode'] as String),
          dartTokens: (json['dart_tokens'] as List).cast(),
          dartTypes: types,
        );
      case 'trigger':
        DriftTable? on;

        if (json['on'] != null) {
          on = await _readElementReference(json['on'] as Map) as DriftTable;
        }

        return DriftTrigger(
          id,
          declaration,
          references: references,
          createStmt: json['sql'] as String,
          on: on,
          onWrite: UpdateKind.values.byName(json['onWrite'] as String),
          writes: [
            for (final write in json.list('writes').cast<Map>())
              WrittenDriftTable(
                await _readElementReference(write['table'] as Map)
                    as DriftTable,
                UpdateKind.values.byName(write['kind'] as String),
              )
          ],
        );
      case 'view':
        final columns = [
          for (final rawColumn in json['columns'] as List)
            await _readColumn(rawColumn as Map, id),
        ];

        final serializedSource = json['source'] as Map;
        final sourceKind = serializedSource['kind'];
        DriftViewSource source;

        if (sourceKind == 'sql') {
          source = SqlViewSource(serializedSource['sql'] as String);
        } else if (sourceKind == 'dart') {
          TableReferenceInDartView readReference(Map json) {
            final id = DriftElementId.fromJson(json['table'] as Map);
            final reference = references.singleWhere((e) => e.id == id);
            return TableReferenceInDartView(
                reference as DriftTable, json['name'] as String);
          }

          source = DartViewSource(
            AnnotatedDartCode.fromJson(serializedSource['query'] as Map),
            serializedSource['primaryFrom'] != null
                ? readReference(serializedSource['primaryFrom'] as Map)
                : null,
            [
              for (final element in serializedSource.list('staticReferences'))
                readReference(element as Map)
            ],
          );
        } else {
          throw UnsupportedError('Unknown view source $serializedSource');
        }

        return DriftView(
          id,
          declaration,
          references: references,
          columns: columns,
          entityInfoName: json['entity_info_name'] as String,
          customParentClass: json['custom_parent_class'] != null
              ? AnnotatedDartCode.fromJson(json['custom_parent_class'] as Map)
              : null,
          nameOfRowClass: json['name_of_row_class'] as String,
          existingRowClass: json['existing_data_class'] != null
              ? await _readExistingRowClass(
                  id.libraryUri, json['existing_data_class'] as Map)
              : null,
          source: source,
        );
      case 'database':
      case 'dao':
        final referenceById = {
          for (final reference in references) reference.id: reference,
        };

        final tables = [
          for (final tableId in json.list('tables'))
            referenceById[DriftElementId.fromJson(tableId as Map)] as DriftTable
        ];
        final views = [
          for (final tableId in json.list('views'))
            referenceById[DriftElementId.fromJson(tableId as Map)] as DriftView
        ];
        final includes =
            (json['includes'] as List).cast<String>().map(Uri.parse).toList();
        final queries = (json['queries'] as List)
            .cast<Map>()
            .map(QueryOnAccessor.fromJson)
            .toList();

        if (type == 'database') {
          return DriftDatabase(
            id: id,
            declaration: declaration,
            declaredTables: tables,
            declaredViews: views,
            declaredIncludes: includes,
            declaredQueries: queries,
            schemaVersion: json['schema_version'] as int?,
            accessors: [
              for (final dao in json.list('daos'))
                await _readElementReference(dao as Map<String, Object?>)
                    as DatabaseAccessor,
            ],
          );
        } else {
          assert(type == 'dao');

          return DatabaseAccessor(
            id: id,
            declaration: declaration,
            declaredTables: tables,
            declaredViews: views,
            declaredIncludes: includes,
            declaredQueries: queries,
            databaseClass: AnnotatedDartCode.fromJson(json['database'] as Map),
            ownType: AnnotatedDartCode.fromJson(json['dart_type'] as Map),
          );
        }
      default:
        throw UnimplementedError('Unsupported element type: $type');
    }
  }

  Future<ColumnType> _readColumnType(Map json, Uri definition) async {
    if (json.containsKey('custom')) {
      return ColumnType.custom(CustomColumnType(
        AnnotatedDartCode.fromJson(json['expression'] as Map),
        await _readDartType(definition, json['dart'] as int),
      ));
    } else {
      return ColumnType.drift(
          DriftSqlType.values.byName(json['builtin'] as String));
    }
  }

  Future<DriftColumn> _readColumn(Map json, DriftElementId ownTable) async {
    final rawConverter = json['typeConverter'] as Map?;

    return DriftColumn(
      sqlType:
          await _readColumnType(json['sqlType'] as Map, ownTable.libraryUri),
      nullable: json['nullable'] as bool,
      nameInSql: json['nameInSql'] as String,
      nameInDart: json['nameInDart'] as String,
      declaration: DriftDeclaration.fromJson(json['declaration'] as Map),
      typeConverter: rawConverter != null
          ? await _readTypeConverter(ownTable.libraryUri, rawConverter)
          : null,
      foreignConverter: rawConverter != null && rawConverter['owner'] != null,
      clientDefaultCode: json['clientDefaultCode'] != null
          ? AnnotatedDartCode.fromJson(json['clientDefaultCode'] as Map)
          : null,
      defaultArgument: json['defaultArgument'] != null
          ? AnnotatedDartCode.fromJson(json['defaultArgument'] as Map)
          : null,
      overriddenJsonName: json['overriddenJsonName'] as String?,
      documentationComment: json['documentationComment'] as String?,
      constraints: [
        for (final rawConstraint in json['constraints'] as List)
          await _readConstraint(rawConstraint as Map, ownTable)
      ],
      customConstraints: json['customConstraints'] as String?,
    );
  }

  Future<AppliedTypeConverter> _readTypeConverter(
      Uri definition, Map json) async {
    final owner = json['owner'];
    DriftColumn? readOwner;
    if (owner != null) {
      readOwner = await _readDriftColumnReference(owner as Map);
    }

    final converter = AppliedTypeConverter(
      expression: AnnotatedDartCode.fromJson(json['expression'] as Map),
      dartType: await _readDartType(definition, json['dart_type'] as int),
      jsonType: json['json_type'] != null
          ? await _readDartType(definition, json['json_type'] as int)
          : null,
      sqlType: await _readColumnType(json['sql_type'] as Map, definition),
      dartTypeIsNullable: json['dart_type_is_nullable'] as bool,
      sqlTypeIsNullable: json['sql_type_is_nullable'] as bool,
      isDriftEnumTypeConverter: json['is_drift_enum_converter'] as bool,
    );

    if (readOwner != null) converter.owningColumn = readOwner;

    return converter;
  }

  Future<ExistingRowClass> _readExistingRowClass(
      Uri definition, Map json) async {
    return ExistingRowClass(
      targetClass: json['target_class'] != null
          ? AnnotatedDartCode.fromJson(json['target_class']! as Map)
          : null,
      targetType: await _readDartType(definition, json['target_type'] as int),
      constructor: json['constructor'] as String,
      isAsyncFactory: json['is_async_factory'] as bool,
      positionalColumns: (json['positional'] as List).cast(),
      namedColumns: (json['named'] as Map).cast(),
      generateInsertable: json['generate_insertable'] as bool,
    );
  }

  ReferenceAction? _readAction(String? value) {
    return value == null ? null : ReferenceAction.values.byName(value);
  }

  Future<DriftColumnConstraint> _readConstraint(
      Map json, DriftElementId ownTable) async {
    final type = json['type'] as String;

    switch (type) {
      case 'unique':
        return const UniqueColumn();
      case 'primary':
        return PrimaryKeyColumn.fromJson(json);
      case 'foreign_key':
        final table = DriftElementId.fromJson(json['column']['table'] as Map);
        if (table == ownTable) {
          return _PendingReferenceToOwnTable(
            json['column']['name'] as String,
            _readAction(json['onUpdate'] as String?),
            _readAction(json['onDelete'] as String?),
          );
        } else {
          return ForeignKeyReference(
            await _readDriftColumnReference(json['column'] as Map),
            _readAction(json['onUpdate'] as String?),
            _readAction(json['onDelete'] as String?),
          );
        }
      case 'generated_as':
        return ColumnGeneratedAs.fromJson(json);
      case 'check':
        return DartCheckExpression.fromJson(json);
      case 'limit_text_length':
        return LimitingTextLength.fromJson(json);
      default:
        throw UnimplementedError('Unsupported constraint: $type');
    }
  }

  Future<DriftTableConstraint> _readTableConstraint(
      Map json, Map<String, DriftColumn> localColumns) async {
    final type = json['type'] as String;

    switch (type) {
      case 'unique':
        return UniqueColumns({
          for (final ref in json.list('columns')) localColumns[ref]!,
        });
      case 'primary_key':
        return PrimaryKeyColumns(
          {for (final ref in json.list('columns')) localColumns[ref]!},
        );
      case 'foreign':
        return ForeignKeyTable(
          localColumns: [
            for (final ref in json.list('local')) localColumns[ref]!,
          ],
          otherTable:
              await _readElementReference(json['table'] as Map) as DriftTable,
          otherColumns: [
            for (final ref in json.list('foreign'))
              await _readDriftColumnReference(ref as Map)
          ],
          onUpdate: _readAction(json['onUpdate'] as String?),
          onDelete: _readAction(json['onDelete'] as String?),
        );
      default:
        throw UnimplementedError('Unsupported constraint: $type');
    }
  }
}

extension on Map {
  Iterable<Object?> list(String key) => this[key] as Iterable;
}

class CouldNotDeserializeException implements Exception {
  final String message;

  const CouldNotDeserializeException(this.message);

  @override
  String toString() => message;
}

class _PendingReferenceToOwnTable extends DriftColumnConstraint {
  final String referencedColumn;
  final ReferenceAction? onUpdate, onDelete;

  _PendingReferenceToOwnTable(
      this.referencedColumn, this.onUpdate, this.onDelete);
}
