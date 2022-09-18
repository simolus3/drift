import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show DriftSqlType, UpdateKind;
import 'package:sqlparser/sqlparser.dart' show ReferenceAction;

import 'driver/driver.dart';
import 'driver/state.dart';
import 'results/results.dart';

class ElementSerializer {
  Map<String, Object?> serializeElements(Iterable<DriftElement> elements) {
    return {
      for (final element in elements) element.id.name: serialize(element),
    };
  }

  Map<String, Object?> serialize(DriftElement element) {
    Map<String, Object?> additionalInformation;

    if (element is DriftTable) {
      additionalInformation = {
        'type': 'table',
        'columns': [
          for (final column in element.columns) _serializeColumn(column),
        ],
        'existing_data_class': element.existingRowClass?.toJson(),
        'primary_key_table_constraint': element.primaryKeyFromTableConstraint
            ?.map((e) => e.nameInSql)
            .toList(),
        'unique_keys_table_constraint': [
          for (final unique in element.uniqueKeysFromTableConstraint)
            [for (final column in unique) column.nameInSql]
        ],
        'custom_parent_class': element.customParentClass?.toJson(),
        'fixed_entity_info_name': element.fixedEntityInfoName,
        'base_dart_name': element.baseDartName,
        'row_class_name': element.nameOfRowClass,
        'without_rowid': element.withoutRowId,
        'strict': element.strict,
      };
    } else if (element is DriftIndex) {
      additionalInformation = {
        'type': 'index',
        'sql': element.createStmt,
      };
    } else if (element is DefinedSqlQuery) {
      additionalInformation = {
        'type': 'query',
        'sql': element.sql,
        'offset': element.sqlOffset,
        'result_class': element.resultClassName,
      };
    } else if (element is DriftTrigger) {
      additionalInformation = {
        'type': 'trigger',
        'sql': element.createStmt,
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
          'sql': source.createView,
        };
      }

      additionalInformation = {
        'type': 'view',
        'columns': [
          for (final column in element.columns) _serializeColumn(column),
        ],
        'entity_info_name': element.entityInfoName,
        'existing_data_class': element.existingRowClass?.toJson(),
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
        if (element is DatabaseAccessor)
          'database': element.databaseClass.toJson(),
        if (element is DriftDatabase) ...{
          'schema_version': element.schemaVersion,
          'daos': element.accessorTypes,
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

  Map<String, Object?> _serializeColumn(DriftColumn column) {
    return {
      'sqlType': column.sqlType.name,
      'nullable': column.nullable,
      'nameInSql': column.nameInSql,
      'nameInDart': column.nameInDart,
      'declaration': column.declaration.toJson(),
      'typeConverter': column.typeConverter != null
          ? _serializeTypeConverter(column.typeConverter!)
          : null,
      'clientDefaultCode': column.clientDefaultCode?.toJson(),
      'defaultArgument': column.clientDefaultCode?.toJson(),
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
        'onUpdate': constraint.onUpdate?.name,
        'onDelete': constraint.onDelete?.name,
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

  Map<String, Object?> _serializeTypeConverter(AppliedTypeConverter converter) {
    return {
      'expression': converter.expression.toJson(),
      'dart_type': converter.dartType.accept(const _DartTypeSerializer()),
      'sql_type': converter.sqlType.name,
      'dart_type_is_nullable': converter.dartTypeIsNullable,
      'sql_type_is_nullable': converter.sqlTypeIsNullable,
      'also_applies_to_json_conversion': converter.alsoAppliesToJsonConversion,
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
}

class _DartTypeSerializer extends TypeVisitor<Map<String, Object?>> {
  const _DartTypeSerializer();

  Map<String, Object?> _simple(String kind, NullabilitySuffix suffix) {
    return {
      'kind': kind,
      'suffix': suffix.name,
    };
  }

  @override
  Map<String, Object?> visitDynamicType(DynamicType type) {
    return _simple('dynamic', type.nullabilitySuffix);
  }

  @override
  Map<String, Object?> visitFunctionType(FunctionType type) {
    // We don't support function types yet.
    return _simple('dynamic', type.nullabilitySuffix);
  }

  @override
  Map<String, Object?> visitInterfaceType(InterfaceType type) {
    return {
      'kind': 'interface',
      'suffix': type.nullabilitySuffix.name,
      'library': type.element2.library.source.uri.toString(),
      'element': type.element2.name,
      'instantiation': [
        for (final instantiation in type.typeArguments)
          instantiation.accept(this),
      ]
    };
  }

  @override
  Map<String, Object?> visitRecordType(RecordType type) {
    throw UnsupportedError('Not yet supported: Record type serialization');
  }

  @override
  Map<String, Object?> visitNeverType(NeverType type) {
    return _simple('Never', type.nullabilitySuffix);
  }

  @override
  Map<String, Object?> visitTypeParameterType(TypeParameterType type) {
    // We don't support function types yet, and only serialize non-parametric
    // type otherwise.
    return _simple('dynamic', type.nullabilitySuffix);
  }

  @override
  Map<String, Object?> visitVoidType(VoidType type) {
    return _simple('void', type.nullabilitySuffix);
  }
}

class ElementDeserializer {
  final Map<Uri, LibraryElement> _loadedLibraries = {};

  final DriftAnalysisDriver driver;

  ElementDeserializer(this.driver);

  Future<DartType> _readDartType(Map json) async {
    final suffix = NullabilitySuffix.values.byName(json['suffix'] as String);
    final helper = await driver.loadKnownTypes();

    final typeProvider = helper.helperLibrary.typeProvider;

    switch (json['kind'] as String) {
      case 'dynamic':
        return typeProvider.dynamicType;
      case 'Never':
        return suffix == NullabilitySuffix.none
            ? typeProvider.neverType
            : typeProvider.nullType;
      case 'void':
        return typeProvider.voidType;
      case 'interface':
        final libraryUri = Uri.parse(json['library'] as String);
        final lib = _loadedLibraries[libraryUri] ??=
            await driver.backend.readDart(libraryUri);
        final element = lib.exportNamespace.get(json['element'] as String)
            as InterfaceElement;
        final instantiation = [
          for (final type in json['instantiation'])
            await _readDartType(type as Map)
        ];

        return element.instantiate(
            typeArguments: instantiation, nullabilitySuffix: suffix);
      default:
        throw ArgumentError.value(json, 'json', 'Invalid type descriptor');
    }
  }

  Future<DriftElement> _readElementReference(Map json) {
    return readDriftElement(DriftElementId.fromJson(json));
  }

  Future<DriftElement> readDriftElement(DriftElementId id) async {
    final state = driver.cache.stateForUri(id.libraryUri).analysis[id] ??=
        ElementAnalysisState(id);
    if (state.result != null && state.isUpToDate) {
      return state.result!;
    }

    final data = await driver.readStoredAnalysisResult(id.libraryUri);
    if (data == null) {
      throw CouldNotDeserializeException(
          'Analysis data for ${id..libraryUri} not found');
    }

    try {
      final result = await _readDriftElement(data[id.name] as Map);
      state
        ..result = result
        ..isUpToDate = true;
      return result;
    } catch (e, s) {
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
      for (final reference in json['references'])
        await _readElementReference(reference as Map),
    ];

    switch (type) {
      case 'table':
        final columns = [
          for (final rawColumn in json['columns'] as List)
            await _readColumn(rawColumn as Map),
        ];
        final columnByName = {
          for (final column in columns) column.nameInSql: column,
        };

        Set<DriftColumn>? primaryKeyFromTableConstraint;
        final serializedPk = json['primary_key_table_constraint'];
        if (serializedPk != null) {
          primaryKeyFromTableConstraint = {
            for (final entry in serializedPk) columnByName[entry]!,
          };
        }

        List<Set<DriftColumn>> uniqueKeysFromTableConstraint = const [];
        final serializedUnique = json['unique_keys_table_constraint'];
        if (serializedUnique != null) {
          uniqueKeysFromTableConstraint = [
            for (final entry in serializedUnique)
              {for (final column in entry) columnByName[column]!},
          ];
        }

        return DriftTable(
          id,
          declaration,
          references: references,
          columns: columns,
          existingRowClass: json['existing_data_class'] != null
              ? ExistingRowClass.fromJson(json['existing_data_class'] as Map)
              : null,
          primaryKeyFromTableConstraint: primaryKeyFromTableConstraint,
          uniqueKeysFromTableConstraint: uniqueKeysFromTableConstraint,
          customParentClass: json['custom_parent_class'] != null
              ? AnnotatedDartCode.fromJson(json['custom_parent_class'] as Map)
              : null,
          fixedEntityInfoName: json['fixed_entity_info_name'] as String?,
          baseDartName: json['base_dart_name'] as String,
          nameOfRowClass: json['row_class_name'] as String,
          withoutRowId: json['without_rowid'] as bool,
          strict: json['strict'] as bool,
        );
      case 'index':
        return DriftIndex(
          id,
          declaration,
          table: references.whereType<DriftTable>().firstOrNull,
          createStmt: json['sql'] as String,
        );
      case 'query':
        return DefinedSqlQuery(
          id,
          declaration,
          references: references,
          sql: json['sql'] as String,
          sqlOffset: json['offset'] as int,
          resultClassName: json['result_class'] as String?,
        );
      case 'trigger':
        return DriftTrigger(
          id,
          declaration,
          references: references,
          createStmt: json['sql'] as String,
          writes: [
            for (final write in json['writes'])
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
            await _readColumn(rawColumn as Map),
        ];

        final serializedSource = json['serializedSource'] as Map;
        DriftViewSource source;

        if (serializedSource['kind'] == 'sql') {
          source = SqlViewSource(serializedSource['sql'] as String);
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
              ? ExistingRowClass.fromJson(json['existing_data_class'] as Map)
              : null,
          source: source,
        );
      case 'database':
      case 'dao':
        final referenceById = {
          for (final reference in references) reference.id: reference,
        };

        final tables = [
          for (final tableId in json['tables'])
            referenceById[DriftElementId.fromJson(tableId as Map)] as DriftTable
        ];
        final views = [
          for (final tableId in json['views'])
            referenceById[DriftElementId.fromJson(tableId as Map)] as DriftView
        ];
        final includes =
            (json['includes'] as List).cast<String>().map(Uri.parse).toList();
        final queries = (json['views'] as List)
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
            schemaVersion: json['schema_version'] as int,
            accessorTypes: [
              for (final dao in json['daos'])
                AnnotatedDartCode.fromJson(dao as Map)
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
          );
        }
      default:
        throw UnimplementedError('Unsupported element type: $type');
    }
  }

  Future<DriftColumn> _readColumn(Map json) async {
    return DriftColumn(
      sqlType: DriftSqlType.values.byName(json['sqlType'] as String),
      nullable: json['nullable'] as bool,
      nameInSql: json['nameInSql'] as String,
      nameInDart: json['nameInDart'] as String,
      declaration: DriftDeclaration.fromJson(json['declaration'] as Map),
      typeConverter: json['typeConverter'] != null
          ? await _readTypeConverter(json['typeConverter'] as Map)
          : null,
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
          await _readConstraint(rawConstraint as Map)
      ],
      customConstraints: json['customConstraints'] as String?,
    );
  }

  Future<AppliedTypeConverter> _readTypeConverter(Map json) async {
    return AppliedTypeConverter(
      expression: AnnotatedDartCode.fromJson(json['expression'] as Map),
      dartType: await _readDartType(json['dart_type'] as Map),
      sqlType: DriftSqlType.values.byName(json['sql_type'] as String),
      dartTypeIsNullable: json['dart_type_is_nullable'] as bool,
      sqlTypeIsNullable: json['sql_type_is_nullable'] as bool,
      alsoAppliesToJsonConversion:
          json['also_applies_to_json_conversion'] as bool,
    );
  }

  Future<DriftColumnConstraint> _readConstraint(Map json) async {
    final type = json['type'] as String;

    switch (type) {
      case 'unique':
        return const UniqueColumn();
      case 'primary':
        return PrimaryKeyColumn.fromJson(json);
      case 'foreign_key':
        ReferenceAction? readAction(String? value) {
          return value == null ? null : ReferenceAction.values.byName(value);
        }

        return ForeignKeyReference(
          await _readDriftColumnReference(json['column'] as Map),
          readAction(json['onUpdate'] as String?),
          readAction(json['onDelete'] as String?),
        );
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
}

class CouldNotDeserializeException implements Exception {
  final String message;

  const CouldNotDeserializeException(this.message);

  @override
  String toString() => message;
}
