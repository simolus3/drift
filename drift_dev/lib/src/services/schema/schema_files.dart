import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show DriftSqlType, SqlDialect, UpdateKind;
import 'package:pub_semver/pub_semver.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart' hide PrimaryKeyColumn;

import '../../analysis/resolver/shared/data_class.dart';
import '../../analysis/results/results.dart';
import '../../analysis/options.dart';
import '../../writer/utils/column_constraints.dart';

class _ExportedSchemaVersion {
  static final Version current = Version(1, 1, 0);
  static final Version _supportDartIndex = Version(1, 1, 0);

  final Version version;

  _ExportedSchemaVersion(this.version);

  bool get supportsDartIndex => version >= _supportDartIndex;
}

/// Utilities to transform moor schema entities to json.
class SchemaWriter {
  final DriftOptions options;
  final List<DriftElement> elements;

  final Map<DriftElement, int> _entityIds = {};
  int _maxId = 0;

  SchemaWriter(this.elements, {this.options = const DriftOptions.defaults()});

  int _idOf(DriftElement entity) {
    return _entityIds.putIfAbsent(entity, () => _maxId++);
  }

  Map<String, dynamic> createSchemaJson() {
    return {
      '_meta': {
        'description': 'This file contains a serialized version of schema '
            'entities for drift.',
        'version': _ExportedSchemaVersion.current.toString(),
      },
      'options': _serializeOptions(),
      'entities': elements.map(_entityToJson).whereType<Map>().toList(),
    };
  }

  Map _serializeOptions() {
    const relevantKeys = {'store_date_time_values_as_text'};
    final asJson = options.toJson()
      ..removeWhere((key, _) => !relevantKeys.contains(key));

    return asJson;
  }

  Map? _entityToJson(DriftElement entity) {
    String? type;
    Map? data;

    if (entity is DriftTable) {
      type = 'table';
      data = _tableData(entity);
    } else if (entity is DriftTrigger) {
      type = 'trigger';
      data = {
        'on': _idOf(entity.on!),
        'references_in_body': [
          for (final ref in entity.references.whereType<DriftSchemaElement>())
            _idOf(ref),
        ],
        'name': entity.schemaName,
        'sql': entity.createStmt,
      };
    } else if (entity is DriftIndex) {
      type = 'index';
      data = {
        'on': _idOf(entity.table!),
        'name': entity.schemaName,
        'sql': entity.createStmt,
        'unique': entity.unique,
        'columns': [
          for (final column in entity.indexedColumns) column.nameInSql,
        ],
      };
    } else if (entity is DriftView) {
      final source = entity.source;
      if (source is! SqlViewSource) {
        throw UnsupportedError(
            'Exporting Dart-defined views into a schema is not '
            'currently supported');
      }

      type = 'view';
      data = {
        'name': entity.schemaName,
        'sql': source.sqlCreateViewStmt,
        'dart_info_name': entity.entityInfoName,
        'columns': [for (final column in entity.columns) _columnData(column)],
      };
    } else if (entity is DefinedSqlQuery) {
      if (entity.mode == QueryMode.atCreate) {
        type = 'special-query';
        data = {
          'scenario': 'create',
          'sql': entity.sql,
        };
      }
    } else {
      throw AssertionError('unknown entity type $entity');
    }

    if (type == null) return null;

    return {
      'id': _idOf(entity),
      'references': [
        for (final reference in entity.references)
          if (reference != entity) _idOf(reference),
      ],
      'type': type,
      'data': data,
    };
  }

  Map _tableData(DriftTable table) {
    final primaryKeyFromTableConstraint =
        table.tableConstraints.whereType<PrimaryKeyColumns>().firstOrNull;
    final uniqueKeys = table.tableConstraints.whereType<UniqueColumns>();

    return {
      'name': table.schemaName,
      'was_declared_in_moor': table.declaration.isDriftDeclaration,
      'columns': [for (final column in table.columns) _columnData(column)],
      'is_virtual': table.isVirtual,
      if (table.isVirtual)
        'create_virtual_stmt': 'CREATE VIRTUAL TABLE "${table.schemaName}" '
            'USING ${table.virtualTableData!.module}'
            '(${table.virtualTableData!.moduleArguments.join(', ')})',
      'without_rowid': table.withoutRowId,
      'constraints': table.overrideTableConstraints,
      if (table.strict) 'strict': true,
      if (primaryKeyFromTableConstraint != null)
        'explicit_pk': [
          ...primaryKeyFromTableConstraint.primaryKey.map((c) => c.nameInSql)
        ],
      if (uniqueKeys.isNotEmpty)
        'unique_keys': [
          for (final uniqueKey in uniqueKeys)
            [for (final column in uniqueKey.uniqueSet) column.nameInSql],
        ]
    };
  }

  Map _columnData(DriftColumn column) {
    final constraints = defaultConstraints(column);

    return {
      'name': column.nameInSql,
      'getter_name': column.nameInDart,
      'moor_type': column.sqlType.builtin.toSerializedString(),
      'nullable': column.nullable,
      'customConstraints': column.customConstraints,
      if (constraints[SqlDialect.sqlite]!.isNotEmpty &&
          column.customConstraints == null)
        // TODO: Dialect-specific constraints in schema file
        'defaultConstraints': constraints[SqlDialect.sqlite]!,
      'default_dart': column.defaultArgument?.toString(),
      'default_client_dart': column.clientDefaultCode?.toString(),
      'dsl_features': [...column.constraints.map(_dslFeatureData)],
      if (column.typeConverter != null)
        'type_converter': {
          'dart_expr': column.typeConverter!.expression.toString(),
          'dart_type_name': column.typeConverter!.dartType
              .getDisplayString(withNullability: false),
        }
    };
  }

  dynamic _dslFeatureData(DriftColumnConstraint feature) {
    if (feature is PrimaryKeyColumn) {
      return feature.isAutoIncrement ? 'auto-increment' : 'primary-key';
    } else if (feature is LimitingTextLength) {
      return {
        'allowed-lengths': {
          'min': feature.minLength,
          'max': feature.maxLength,
        },
      };
    }
    return 'unknown';
  }
}

/// Reads files generated by [SchemaWriter].
class SchemaReader {
  static final Uri elementUri = Uri.parse('drift:hidden');

  // The format version of the exported schema we're reading.
  late final _ExportedSchemaVersion _version;

  final Map<int, DriftElement> _entitiesById = {};
  final Map<int, Map<String, dynamic>> _rawById = {};

  final Set<int> _currentlyProcessing = {};

  final SqlEngine _engine = SqlEngine();
  Map<String, Object?> options = const {};

  SchemaReader._();

  factory SchemaReader.readJson(Map<String, dynamic> json) {
    return SchemaReader._().._read(json);
  }

  Iterable<DriftElement> get entities => _entitiesById.values;

  void _read(Map<String, dynamic> json) {
    final meta = json['_meta'] as Map<String, Object?>;
    _version = _ExportedSchemaVersion(Version.parse(meta['version'] as String));

    // Read drift options if they are part of the schema file.
    final optionsInJson = json['options'] as Map<String, Object?>?;
    options = optionsInJson ??
        {
          'store_date_time_values_as_text': false,
        };

    final entities = json['entities'] as List<dynamic>;

    for (final raw in entities) {
      final rawData = raw as Map<String, dynamic>;
      final id = rawData['id'] as int;

      _rawById[id] = rawData;
    }

    _rawById.keys.forEach(_processById);
  }

  T _existingEntity<T extends DriftElement>(dynamic id) {
    return _entitiesById[id as int] as T;
  }

  DriftElementId _id(String name) => DriftElementId(elementUri, name);

  DriftDeclaration get _declaration =>
      DriftDeclaration(elementUri, -1, '<unknown>');

  void _processById(int id) {
    if (_entitiesById.containsKey(id)) return;
    if (_currentlyProcessing.contains(id)) {
      throw ArgumentError(
          'Could not read schema file: Contains circular references.');
    }

    _currentlyProcessing.add(id);

    final rawData = _rawById[id];
    final references = (rawData?['references'] as List<dynamic>).cast<int>();

    // Ensure that dependencies have been resolved
    references.forEach(_processById);

    final content = rawData?['data'] as Map<String, dynamic>;
    final type = rawData?['type'] as String;

    DriftElement entity;
    switch (type) {
      case 'index':
        entity = _readIndex(content);
        break;
      case 'trigger':
        entity = _readTrigger(content);
        break;
      case 'table':
        entity = _readTable(content);
        break;
      case 'view':
        entity = _readView(content);
        break;
      case 'special-query':
        // Not relevant for the schema.
        return;
      default:
        throw ArgumentError(
            'Could not read schema file: Unknown entity $rawData');
    }

    _entitiesById[id] = entity;
  }

  DriftIndex _readIndex(Map<String, dynamic> content) {
    final on = _existingEntity<DriftTable>(content['on']);
    final name = content['name'] as String;
    final sql = content['sql'] as String?;

    if (_version.supportsDartIndex) {
      final index = DriftIndex(
        _id(name),
        _declaration,
        table: on,
        indexedColumns: [
          for (final col in content['columns'] as List)
            on.columnBySqlName[col]!,
        ],
        unique: content['unique'] as bool,
        createStmt: sql,
      );

      if (sql != null) {
        index.parsedStatement =
            _engine.parse(sql).rootNode as CreateIndexStatement;
      } else {
        index.createStatementForDartDefinition();
      }

      return index;
    } else {
      // In older versions, we always had an SQL statement!
      final stmt = _engine.parse(sql!).rootNode as CreateIndexStatement;

      return DriftIndex(
        _id(name),
        _declaration,
        table: on,
        createStmt: sql,
        unique: stmt.unique,
        indexedColumns: [
          for (final column in stmt.columns)
            on.columnBySqlName[(column.expression as Reference).columnName]!,
        ],
      )..parsedStatement = stmt;
    }
  }

  DriftTrigger _readTrigger(Map<String, dynamic> content) {
    final on = _existingEntity<DriftTable>(content['on']);
    final name = content['name'] as String;
    final sql = content['sql'] as String;

    // Old versions of this file used to have a typo when serializing body
    // references.
    final bodyReferences =
        (content['references_in_body'] ?? content['refences_in_body']) as List;

    return DriftTrigger(
      _id(name),
      _declaration,
      on: on,
      onWrite: UpdateKind.delete,
      references: [
        for (final bodyRef in bodyReferences) _existingEntity(bodyRef)
      ],
      createStmt: sql,
      writes: const [],
    )..parsedStatement = _engine.parse(sql).rootNode as CreateTriggerStatement;
  }

  DriftTable _readTable(Map<String, dynamic> content) {
    final sqlName = content['name'] as String;
    final isVirtual = content['is_virtual'] as bool;
    final withoutRowId = content['without_rowid'] as bool? ?? false;
    final pascalCase = ReCase(sqlName).pascalCase;
    final columns = [
      for (final rawColumn in content['columns'] as List)
        _readColumn(rawColumn as Map<String, dynamic>)
    ];

    if (isVirtual) {
      final create = content['create_virtual_stmt'] as String;
      final parsed =
          _engine.parse(create).rootNode as CreateVirtualTableStatement;

      return DriftTable(
        _id(sqlName),
        _declaration,
        columns: columns,
        baseDartName: pascalCase,
        fixedEntityInfoName: pascalCase,
        nameOfRowClass: '${pascalCase}Data',
        writeDefaultConstraints: true,
        withoutRowId: withoutRowId,
        virtualTableData:
            VirtualTableData(parsed.moduleName, parsed.argumentContent, null),
      );
    }

    List<String>? tableConstraints;
    if (content.containsKey('constraints')) {
      tableConstraints = (content['constraints'] as List<dynamic>).cast();
    }

    Set<DriftColumn>? explicitPk;
    if (content.containsKey('explicit_pk')) {
      explicitPk = {
        for (final columnName in content['explicit_pk'] as List<dynamic>)
          columns.singleWhere((c) => c.nameInSql == columnName)
      };
    }

    List<Set<DriftColumn>> uniqueKeys = [];
    if (content.containsKey('unique_keys')) {
      for (final key in content['unique_keys'] as Iterable) {
        uniqueKeys.add({
          for (final columnName in key as Iterable)
            columns.singleWhere((c) => c.nameInSql == columnName)
        });
      }
    }

    return DriftTable(
      _id(sqlName),
      _declaration,
      columns: columns,
      baseDartName: pascalCase,
      fixedEntityInfoName: pascalCase,
      strict: content['strict'] == true,
      nameOfRowClass: '${pascalCase}Data',
      writeDefaultConstraints: content['was_declared_in_moor'] != true,
      withoutRowId: withoutRowId,
      overrideTableConstraints: tableConstraints ?? const [],
      tableConstraints: [
        if (explicitPk != null) PrimaryKeyColumns(explicitPk),
        for (final unique in uniqueKeys) UniqueColumns(unique)
      ],
    );
  }

  DriftView _readView(Map<String, dynamic> content) {
    final name = content['name'] as String;
    final entityInfoName = content['dart_info_name'] as String;

    return DriftView(
      _id(name),
      _declaration,
      columns: [
        for (final column in content['columns'] as Iterable)
          _readColumn(column as Map<String, dynamic>)
      ],
      source: SqlViewSource(content['sql'] as String),
      customParentClass: null,
      entityInfoName: entityInfoName,
      existingRowClass: null,
      nameOfRowClass: dataClassNameForClassName(entityInfoName),
      references: const [],
    );
  }

  DriftColumn _readColumn(Map<String, dynamic> data) {
    final name = data['name'] as String;
    final columnType =
        _SerializeSqlType.deserialize(data['moor_type'] as String);
    final nullable = data['nullable'] as bool;
    final customConstraints = data['customConstraints'] as String?;
    final defaultConstraints = data['defaultConstraints'] as String?;
    final dslFeatures = <DriftColumnConstraint?>[
      for (final feature in data['dsl_features'] as List<dynamic>)
        _columnFeature(feature),
      if (defaultConstraints != null)
        DefaultConstraintsFromSchemaFile(defaultConstraints),
    ].whereType<DriftColumnConstraint>().toList();
    final getterName = data['getter_name'] as String?;

    final defaultDart = data['default_dart'] as String?;

    // Note: Not including client default code because that usually depends on
    // imports from the database.
    return DriftColumn(
      sqlType: ColumnType.drift(columnType),
      nullable: nullable,
      nameInSql: name,
      nameInDart: getterName ?? ReCase(name).camelCase,
      defaultArgument:
          defaultDart != null ? AnnotatedDartCode([defaultDart]) : null,
      declaration: _declaration,
      customConstraints: customConstraints,
      constraints: dslFeatures,
    );
  }

  DriftColumnConstraint? _columnFeature(dynamic data) {
    if (data == 'auto-increment') return PrimaryKeyColumn(true);
    if (data == 'primary-key') return PrimaryKeyColumn(false);

    if (data is Map<String, dynamic>) {
      final allowedLengths = data['allowed-lengths'] as Map<String, dynamic>;
      return LimitingTextLength(
        minLength: allowedLengths['min'] as int?,
        maxLength: allowedLengths['max'] as int?,
      );
    }

    return null;
  }
}

// There used to be another enum to represent columns that has since been
// replaced with DriftSqlType. We still need to reflect the old description in
// the serialized format.
extension _SerializeSqlType on DriftSqlType {
  static DriftSqlType deserialize(String description) {
    switch (description) {
      case 'ColumnType.boolean':
        return DriftSqlType.bool;
      case 'ColumnType.text':
        return DriftSqlType.string;
      case 'ColumnType.bigInt':
        return DriftSqlType.bigInt;
      case 'ColumnType.integer':
        return DriftSqlType.int;
      case 'ColumnType.datetime':
        return DriftSqlType.dateTime;
      case 'ColumnType.blob':
        return DriftSqlType.blob;
      case 'ColumnType.real':
        return DriftSqlType.double;
    }

    try {
      return DriftSqlType.values.byName(description);
    } on ArgumentError {
      throw ArgumentError.value(
          description, 'description', 'Not a known column type');
    }
  }

  String toSerializedString() {
    return name;
  }
}
