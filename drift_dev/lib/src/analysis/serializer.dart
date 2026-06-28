import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:drift/drift.dart' show DriftSqlType, UpdateKind;
import 'package:drift_dev/src/analysis/resolver/resolver.dart';
import 'package:sqlparser/sqlparser.dart' show OrderingMode, ReferenceAction;

import 'driver/driver.dart';
import 'results/results.dart';

class SerializedElements {
  final List<AnnotatedDartCode> dartTypes;
  final Map<String, Object?> serializedData;
  final Map<String, Object?> _serializedElements;

  SerializedElements(
    this.dartTypes,
    this.serializedData,
    this._serializedElements,
  ) {
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
        'custom_parent_class': _serializeCustomParentClass(
          element.customParentClass,
        ),
        'interfaces_for_row_class': [
          for (final implements in element.interfacesForRowClass)
            implements.toJson(),
        ],
        'fixed_entity_info_name': element.fixedEntityInfoName,
        'base_dart_name': element.baseDartName,
        'row_class_name': element.nameOfRowClass,
        'companion_class_name': element.nameOfCompanionClass,
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
          for (final column in element.indexedColumns)
            {
              'column': column.column.nameInSql,
              'order_by': column.orderBy?.name,
            },
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
            entry.key: _serializeType(entry.value),
        },
      };
    } else if (element is DriftTrigger) {
      additionalInformation = {
        'type': 'trigger',
        'sql': element.createStmt,
        if (element.on != null)
          'on': _serializeElementReference(element.on!.element),
        'onWrite': element.onWrite.name,
        'writes': [
          for (final write in element.writes)
            {
              'table': _serializeElementReference(write.table),
              'kind': write.kind.name,
            },
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
          ],
          'staticSource': source.staticSource,
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
        'interfaces_for_row_class': [
          for (final implements in element.interfacesForRowClass)
            implements.toJson(),
        ],
        'custom_parent_class': _serializeCustomParentClass(
          element.customParentClass,
        ),
        'name_of_row_class': element.nameOfRowClass,
        'name_of_companion_class': element.nameOfCompanionClass,
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
            _serializeElementReference(table.element),
        ],
        'views': [
          for (final view in element.declaredViews)
            _serializeElementReference(view.element),
        ],
        'includes': [
          for (final include in element.declaredIncludes) include.toString(),
        ],
        'queries': element.declaredQueries,
        if (element is DatabaseAccessor) ...{
          'dart_type': element.ownType.toJson(),
          'database': element.databaseClass.toJson(),
        },
        if (element is DriftDatabase) ...{
          'schema_version': element.schemaVersion,
          'daos': [
            for (final dao in element.accessors)
              _serializeElementReference(dao.element),
          ],
          'has_constructor_arg': element.hasConstructorArgumentForConnection,
        },
      };
    } else {
      throw UnimplementedError('Unknown element $element');
    }

    return {
      'id': element.id.toJson(),
      'declaration': element.declaration.toJson(),
      'references': [
        for (final referenced in element.references)
          _serializeElementReference(referenced.element),
      ],
      ...additionalInformation,
    };
  }

  Map<String, Object?> _serializeColumnType(ColumnType type) {
    return switch (type) {
      ColumnDriftType() => {'builtin': type.builtin.name},
      ColumnCustomType(:final custom) => {
        'custom': {
          'dart': _serializeType(custom.dartType),
          'expression': custom.expression.toJson(),
        },
      },
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
      'referenceName': column.referenceName,
      'documentationComment': column.documentationComment,
      'constraints': [
        for (final constraint in column.constraints)
          _serializeColumnConstraint(constraint),
      ],
      'customConstraints': column.customConstraints,
    };
  }

  Map<String, Object?> _serializeColumnConstraint(
    DriftColumnConstraint constraint,
  ) {
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
        'initiallyDeferred': constraint.initiallyDeferred,
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
    DriftTableConstraint constraint,
  ) {
    if (constraint is UniqueColumns) {
      return {
        'type': 'unique',
        'columns': [
          for (final column in constraint.uniqueSet) column.nameInSql,
        ],
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
        'initiallyDeferred': constraint.initiallyDeferred,
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

  Map<String, Object?>? _serializeCustomParentClass(CustomParentClass? pc) {
    if (pc == null) return null;

    return {'class': pc.parentClass.toJson(), 'const': pc.isConst};
  }

  String? _serializeReferenceAction(ReferenceAction? action) {
    return action?.name;
  }

  Map<String, Object?> _serializeTypeConverter(
    DriftColumn appliedTo,
    AppliedTypeConverter converter,
  ) {
    return {
      'expression': converter.expression.toJson(),
      'dart_type': _serializeType(converter.dartType),
      'json_type': _serializeType(converter.jsonType),
      'sql_type': _serializeColumnType(converter.sqlType),
      'dart_type_is_nullable': converter.dartTypeIsNullable,
      'sql_type_is_nullable': converter.sqlTypeIsNullable,
      'json_type_is_nullable': converter.jsonTypeIsNullable,
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
      'getters': existing.columnGetters,
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
    TableReferenceInDartView ref,
  ) {
    return {
      'table': _serializeElementReference(ref.table.element),
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

final class ElementFileDeserializer {
  final Map<String, Object?> _elements;

  ElementFileDeserializer(this._elements);

  Map<String, Object?> _serializedElement(String name) {
    final data = _elements[name] as Map<String, Object?>?;
    if (data == null) {
      throw CouldNotDeserializeException(
        'Element $name not found in ${_elements.keys}',
      );
    }

    return data;
  }

  DriftElementKind kindFor(String localName) {
    final element = _serializedElement(localName);
    final type = element['type'] as String;

    return switch (type) {
      'table' => DriftElementKind.table,
      'index' => DriftElementKind.dbIndex,
      'query' => DriftElementKind.definedQuery,
      'trigger' => DriftElementKind.trigger,
      'view' => DriftElementKind.view,
      'database' => DriftElementKind.database,
      'dao' => DriftElementKind.databaseAccessor,
      _ => throw CouldNotDeserializeException('Unknown element type $type'),
    };
  }

  Future<PendingDriftElement> deserialize(
    DependencyAwareResolver resolver,
    DriftElementKind kind,
  ) {
    final deserializer = ElementDeserializer._(resolver);
    return deserializer.readDriftElement(
      _serializedElement(resolver.ownElementReference.id.name),
      resolver.ownElementReference,
      kind,
    );
  }
}

/// Deserializes the element structure emitted by [ElementSerializer].
final class ElementDeserializer {
  final DependencyAwareResolver resolver;
  final List<void Function(ResolvedDependencies)> _resolve = [];

  DriftAnalysisDriver get driver => resolver.driver;

  ElementDeserializer._(this.resolver);

  Future<DartType> _readDartType(Uri import, int typeId) async {
    LibraryElement? element;
    final helpers = driver.cache.typeHelperLibraries;

    if (helpers.containsKey(import)) {
      element = helpers[import];
    } else {
      element = helpers[import] = await driver.cacheReader!.readTypeHelperFor(
        import,
      );
    }

    if (element == null) {
      throw ArgumentError('Unknown serialized type: Helper does not exist.');
    }

    final typedef =
        element.exportNamespace.get2('T$typeId') as TypeAliasElement;

    return typedef.aliasedType;
  }

  Future<DependencyToken> _readDependency(Map json) async {
    final id = DriftElementId.fromJson(json);
    final result = await resolver.resolveReferencedElement(id);
    switch (result) {
      case ResolvedReferenceFound(:final token):
        return token;
      case InvalidReferenceResult(:final error, :final message):
        throw CouldNotDeserializeException(
          'Error resolving deserialized reference to $id: $error, $message',
        );
      case ReferencedElementCouldNotBeResolved():
        throw CouldNotDeserializeException(
          'Could not resolve reference to $id',
        );
    }
  }

  DriftColumn _readDriftColumnReference(
    Map json,
    DriftElementWithResultSet owner,
  ) {
    final id = DriftElementId.fromJson(json['table'] as Map);
    assert(id == owner.id);

    final name = json['name'] as String;
    return owner.columns.singleWhere((c) => c.nameInSql == name);
  }

  Future<PendingDriftElement> readDriftElement(
    Map json,
    DriftElementReference ownReference,
    DriftElementKind kind,
  ) async {
    final id = DriftElementId.fromJson(json['id'] as Map);
    assert(id == ownReference.id);

    final declaration = DriftDeclaration.fromJson(json['declaration'] as Map);
    final dependencies = <DependencyToken>[
      for (final reference in json.list('references'))
        await _readDependency(reference as Map),
    ];
    final references = dependencies.map((d) => d.reference).toList();

    DriftElement element;
    switch (kind) {
      case DriftElementKind.table:
        final columns = [
          for (final rawColumn in json['columns'] as List)
            await _readColumn(rawColumn as Map, id),
        ];
        final columnByName = {
          for (final column in columns) column.nameInSql: column,
        };

        final tableConstraints = <DriftTableConstraint>[];
        for (final constraint in json.list('table_constraints')) {
          await _readTableConstraint(
            tableConstraints,
            constraint as Map,
            columnByName,
          );
        }

        final table = element = DriftTable(
          ownReference,
          declaration,
          references: references,
          columns: columns,
          existingRowClass: json['existing_data_class'] != null
              ? await _readExistingRowClass(
                  id.libraryUri,
                  json['existing_data_class'] as Map,
                )
              : null,
          tableConstraints: tableConstraints,
          customParentClass: _readCustomParentClass(
            json['custom_parent_class'] as Map?,
          ),
          interfacesForRowClass: [
            for (final entry in json['interfaces_for_row_class'] as List)
              AnnotatedDartCode.fromJson(entry as Map),
          ],
          fixedEntityInfoName: json['fixed_entity_info_name'] as String?,
          baseDartName: json['base_dart_name'] as String,
          nameOfRowClass: json['row_class_name'] as String,
          nameOfCompanionClass: json['companion_class_name'] as String?,
          withoutRowId: json['without_rowid'] as bool,
          strict: json['strict'] as bool,
          writeDefaultConstraints: json['write_default_constraints'] as bool,
          overrideTableConstraints: json['custom_constraints'] != null
              ? (json['custom_constraints'] as List).cast()
              : const [],
          attachedIndices: (json['attached_indices'] as List).cast(),
        );

        if (json['virtual'] != null) {
          final data = json['virtual'] as Map;
          final module = data['module'] as String;
          final arguments = (data['arguments'] as List).cast<String>();

          final rawRecognized = data['recognized'];
          if (rawRecognized != null) {
            final rawTable = (rawRecognized as Map)['content_table'];
            final rawTableDependency = rawTable != null
                ? await _readDependency(rawTable as Map)
                : null;
            final rawRowid = rawRecognized['content_rowid'];

            _resolve.add((deps) {
              final contentTable =
                  deps.resolveNullable(rawTableDependency) as DriftTable?;

              table.virtualTableData = VirtualTableData(
                module,
                arguments,
                DriftFts5Table(
                  contentTable,
                  rawRowid != null
                      ? _readDriftColumnReference(
                          rawRowid as Map,
                          contentTable!,
                        )
                      : null,
                ),
              );
            });
          } else {
            table.virtualTableData = VirtualTableData(module, arguments, null);
          }
        }
      case DriftElementKind.dbIndex:
        final indexedColumns = <DriftIndexedColumn>[];

        element = DriftIndex(
          ownReference,
          declaration,
          table: references.first,
          createStmt: json['sql'] as String?,
          indexedColumns: indexedColumns,
          unique: json['unique'] as bool,
        );

        _resolve.add((deps) {
          final resolvedTable = deps.resolve(dependencies.first) as DriftTable;

          for (final entry
              in (json['columns'] as List).cast<Map<String, Object?>>()) {
            indexedColumns.add(
              DriftIndexedColumn(
                column:
                    resolvedTable.columnBySqlName[entry['column'] as String]!,
                orderBy: switch (entry['order_by']) {
                  null => null,
                  final orderBy => OrderingMode.values.byName(
                    orderBy as String,
                  ),
                },
              ),
            );
          }
        });

      case DriftElementKind.definedQuery:
        final types = <String, DartType>{};

        for (final entry in (json['dart_types'] as Map).entries) {
          types[entry.key as String] = await _readDartType(
            id.libraryUri,
            entry.value as int,
          );
        }

        RequestedQueryResultType? existingDartType;

        final rawExistingType = json['existing_type'];
        if (rawExistingType != null) {
          existingDartType = RequestedQueryResultType(
            await _readDartType(id.libraryUri, rawExistingType['type'] as int),
            rawExistingType['constructor_name'] as String?,
          );
        }

        element = DefinedSqlQuery(
          ownReference,
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
      case DriftElementKind.trigger:
        DependencyToken? on;

        if (json['on'] != null) {
          on = await _readDependency(json['on'] as Map);
        }

        final rawWrites = <(DependencyToken, UpdateKind)>[];
        final writes = <WrittenDriftTable>[];
        for (final write in json.list('writes').cast<Map>()) {
          final dep = await _readDependency(write['table'] as Map);
          rawWrites.add((
            dep,
            UpdateKind.values.byName(write['kind'] as String),
          ));
        }

        element = DriftTrigger(
          ownReference,
          declaration,
          references: references,
          createStmt: json['sql'] as String,
          on: on?.reference,
          onWrite: UpdateKind.values.byName(json['onWrite'] as String),
          writes: writes,
        );
        _resolve.add((deps) {
          for (final (table, updateKind) in rawWrites) {
            writes.add(
              WrittenDriftTable(deps.resolve(table) as DriftTable, updateKind),
            );
          }
        });
      case DriftElementKind.view:
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
            final reference = references.firstWhere((e) => e.id == id);
            return TableReferenceInDartView(reference, json['name'] as String);
          }

          source = DartViewSource(
            AnnotatedDartCode.fromJson(serializedSource['query'] as Map),
            serializedSource['primaryFrom'] != null
                ? readReference(serializedSource['primaryFrom'] as Map)
                : null,
            [
              for (final element in serializedSource.list('staticReferences'))
                readReference(element as Map),
            ],
            serializedSource['staticSource'] != null
                ? serializedSource['staticSource'] as String
                : null,
          );
        } else {
          throw UnsupportedError('Unknown view source $serializedSource');
        }

        element = DriftView(
          ownReference,
          declaration,
          references: references,
          columns: columns,
          entityInfoName: json['entity_info_name'] as String,
          customParentClass: _readCustomParentClass(
            json['custom_parent_class'] as Map?,
          ),
          interfacesForRowClass: [
            for (final entry in json['interfaces_for_row_class'] as List)
              AnnotatedDartCode.fromJson(entry as Map),
          ],
          nameOfRowClass: json['name_of_row_class'] as String,
          nameOfCompanionClass: json['name_of_companion_class'] as String?,
          existingRowClass: json['existing_data_class'] != null
              ? await _readExistingRowClass(
                  id.libraryUri,
                  json['existing_data_class'] as Map,
                )
              : null,
          source: source,
        );
      case DriftElementKind.database:
      case DriftElementKind.databaseAccessor:
        final referenceById = {
          for (final reference in references) reference.id: reference,
        };

        final tables = [
          for (final tableId in json.list('tables'))
            referenceById[DriftElementId.fromJson(tableId as Map)]!,
        ];
        final views = [
          for (final tableId in json.list('views'))
            referenceById[DriftElementId.fromJson(tableId as Map)]!,
        ];
        final includes = (json['includes'] as List)
            .cast<String>()
            .map(Uri.parse)
            .toList();
        final queries = (json['queries'] as List)
            .cast<Map>()
            .map(QueryOnAccessor.fromJson)
            .toList();

        if (kind == DriftElementKind.database) {
          element = DriftDatabase(
            reference: ownReference,
            declaration: declaration,
            declaredTables: tables,
            declaredViews: views,
            declaredIncludes: includes,
            declaredQueries: queries,
            schemaVersion: json['schema_version'] as int?,
            accessors: [
              for (final dao in json.list('daos'))
                (await _readDependency(dao as Map)).reference,
            ],
            hasConstructorArgumentForConnection:
                json['has_constructor_arg'] as bool,
          );
        } else {
          assert(kind == DriftElementKind.databaseAccessor);

          element = DatabaseAccessor(
            reference: ownReference,
            declaration: declaration,
            declaredTables: tables,
            declaredViews: views,
            declaredIncludes: includes,
            declaredQueries: queries,
            databaseClass: AnnotatedDartCode.fromJson(json['database'] as Map),
            ownType: AnnotatedDartCode.fromJson(json['dart_type'] as Map),
          );
        }
    }

    return PendingDriftElement(
      element: element,
      resolve: (deps) {
        for (final resolve in _resolve) {
          resolve(deps);
        }
      },
    );
  }

  Future<ColumnType> _readColumnType(Map json, Uri definition) async {
    if (json['custom'] case final customType?) {
      return ColumnType.custom(
        CustomColumnType(
          AnnotatedDartCode.fromJson(customType['expression'] as Map),
          await _readDartType(definition, customType['dart'] as int),
        ),
      );
    } else {
      return ColumnType.drift(
        DriftSqlType.values.byName(json['builtin'] as String),
      );
    }
  }

  Future<DriftColumn> _readColumn(Map json, DriftElementId ownTable) async {
    final rawConverter = json['typeConverter'] as Map?;
    final constraints = <DriftColumnConstraint>[];
    for (final rawConstraint in json['constraints'] as List) {
      await _readConstraint(constraints, rawConstraint as Map, ownTable);
    }

    final column = DriftColumn(
      sqlType: await _readColumnType(
        json['sqlType'] as Map,
        ownTable.libraryUri,
      ),
      nullable: json['nullable'] as bool,
      nameInSql: json['nameInSql'] as String,
      nameInDart: json['nameInDart'] as String,
      declaration: DriftDeclaration.fromJson(json['declaration'] as Map),
      typeConverter: null,
      foreignConverter: rawConverter != null && rawConverter['owner'] != null,
      clientDefaultCode: json['clientDefaultCode'] != null
          ? AnnotatedDartCode.fromJson(json['clientDefaultCode'] as Map)
          : null,
      defaultArgument: json['defaultArgument'] != null
          ? AnnotatedDartCode.fromJson(json['defaultArgument'] as Map)
          : null,
      overriddenJsonName: json['overriddenJsonName'] as String?,
      referenceName: json['referenceName'] as String?,
      documentationComment: json['documentationComment'] as String?,
      constraints: constraints,
      customConstraints: json['customConstraints'] as String?,
    );

    if (rawConverter != null) {
      await _readTypeConverter(column, ownTable.libraryUri, rawConverter);
    }

    return column;
  }

  Future<void> _readTypeConverter(
    DriftColumn column,
    Uri definition,
    Map json,
  ) async {
    final owner = json['owner'];

    final converter = AppliedTypeConverter(
      expression: AnnotatedDartCode.fromJson(json['expression'] as Map),
      dartType: await _readDartType(definition, json['dart_type'] as int),
      jsonType: json['json_type'] != null
          ? await _readDartType(definition, json['json_type'] as int)
          : null,
      sqlType: await _readColumnType(json['sql_type'] as Map, definition),
      dartTypeIsNullable: json['dart_type_is_nullable'] as bool,
      sqlTypeIsNullable: json['sql_type_is_nullable'] as bool,
      jsonTypeIsNullable: json['json_type_is_nullable'] as bool,
      isDriftEnumTypeConverter: json['is_drift_enum_converter'] as bool,
    );

    if (owner != null) {
      final table = await _readDependency(owner['table'] as Map);
      _resolve.add((deps) {
        converter.owningColumn = _readDriftColumnReference(
          owner as Map,
          deps.resolve(table) as DriftElementWithResultSet,
        );
      });
    } else {
      converter.owningColumn = column;
    }

    column.typeConverter = converter;
  }

  Future<ExistingRowClass> _readExistingRowClass(
    Uri definition,
    Map json,
  ) async {
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
      columnGetters: (json['getters'] as Map).cast(),
    );
  }

  CustomParentClass? _readCustomParentClass(Map? json) {
    if (json == null) return null;

    return CustomParentClass(
      parentClass: AnnotatedDartCode.fromJson(json['class'] as Map),
      isConst: json['const'] as bool,
    );
  }

  ReferenceAction? _readAction(String? value) {
    return value == null ? null : ReferenceAction.values.byName(value);
  }

  Future<void> _readConstraint(
    List<DriftColumnConstraint> constraints,

    Map json,
    DriftElementId ownTable,
  ) async {
    final type = json['type'] as String;

    switch (type) {
      case 'unique':
        return constraints.add(const UniqueColumn());
      case 'primary':
        return constraints.add(PrimaryKeyColumn.fromJson(json));
      case 'foreign_key':
        final referencedColumn = json['column'] as Map;
        final table = await _readDependency(referencedColumn['table'] as Map);

        _resolve.add((deps) {
          final ref = _readDriftColumnReference(
            referencedColumn,
            deps.resolve(table) as DriftTable,
          );

          constraints.add(
            ForeignKeyReference(
              ref,
              _readAction(json['onUpdate'] as String?),
              _readAction(json['onDelete'] as String?),
              json['initiallyDeferred'] as bool,
            ),
          );
        });
      case 'generated_as':
        return constraints.add(ColumnGeneratedAs.fromJson(json));
      case 'check':
        return constraints.add(DartCheckExpression.fromJson(json));
      case 'limit_text_length':
        return constraints.add(LimitingTextLength.fromJson(json));
      default:
        throw UnimplementedError('Unsupported constraint: $type');
    }
  }

  Future<void> _readTableConstraint(
    List<DriftTableConstraint> constraints,
    Map json,
    Map<String, DriftColumn> localColumns,
  ) async {
    final type = json['type'] as String;

    switch (type) {
      case 'unique':
        return constraints.add(
          UniqueColumns({
            for (final ref in json.list('columns')) localColumns[ref]!,
          }),
        );
      case 'primary_key':
        return constraints.add(
          PrimaryKeyColumns({
            for (final ref in json.list('columns')) localColumns[ref]!,
          }),
        );
      case 'foreign':
        final otherTableDep = await _readDependency(json['table'] as Map);
        _resolve.add((deps) {
          final otherTable = deps.resolve(otherTableDep) as DriftTable;

          constraints.add(
            ForeignKeyTable(
              localColumns: [
                for (final ref in json.list('local')) localColumns[ref]!,
              ],
              otherTable: otherTable,
              otherColumns: [
                for (final ref in json.list('foreign'))
                  _readDriftColumnReference(ref as Map, otherTable),
              ],
              onUpdate: _readAction(json['onUpdate'] as String?),
              onDelete: _readAction(json['onDelete'] as String?),
              initiallyDeferred: json['initiallyDeferred'] as bool,
            ),
          );
        });

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
