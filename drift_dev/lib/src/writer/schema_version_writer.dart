import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show DriftSqlType;
import 'package:sqlparser/sqlparser.dart' as sql;
import 'package:sqlparser/utils/node_to_text.dart';

import '../analysis/results/results.dart';
import '../utils/string_escaper.dart';
import 'tables/table_writer.dart';
import 'writer.dart';

class SchemaVersion {
  final int version;
  final List<DriftSchemaElement> schema;
  final Map<String, Object?> options;

  SchemaVersion(this.version, this.schema, this.options);
}

enum _ResultSetKind {
  table,
  virtualTable,
  view,
}

final class _TableShape {
  final _ResultSetKind kind;
  // Map from Dart getter names to column names in SQL and the SQL type.
  final Map<String, (String, DriftSqlType)> columnTypes;

  _TableShape(this.kind, this.columnTypes);

  @override
  int get hashCode => Object.hash(kind, _equality.hash(columnTypes));

  @override
  bool operator ==(Object other) {
    return other is _TableShape &&
        other.kind == kind &&
        _equality.equals(other.columnTypes, columnTypes);
  }

  static const _equality = MapEquality<String, (String, DriftSqlType)>();

  static Map<String, (String, DriftSqlType)> columnsFrom(
      DriftElementWithResultSet e) {
    return {
      for (final column in e.columns)
        column.nameInDart: (column.nameInSql, column.sqlType),
    };
  }
}

class SchemaVersionWriter {
  static final Uri _schemaLibrary =
      Uri.parse('package:drift/internal/versioned_schema.dart');

  /// All schema versions, sorted by [SchemaVersion.version].
  final List<SchemaVersion> versions;
  final Scope libraryScope;

  final Map<String, String> _columnCodeToFactory = {};
  final Map<_TableShape, String> _shapes = {};

  SchemaVersionWriter(this.versions, this.libraryScope);

  String _referenceColumn(DriftColumn column) {
    final text = libraryScope.leaf();
    final (type, code) = TableOrViewWriter.instantiateColumn(column, text);

    return _columnCodeToFactory.putIfAbsent(code, () {
      final methodName = '_column_${_columnCodeToFactory.length}';
      text.writeln('$type $methodName(String aliasedName) => $code;');
      return methodName;
    });
  }

  void _writeColumnsArgument(List<DriftColumn> columns, TextEmitter writer) {
    writer.write('columns: [');

    for (final column in columns) {
      writer
        ..write(_referenceColumn(column))
        ..write(',');
    }

    writer.write('],');
  }

  String _shapeClass(DriftElementWithResultSet resultSet) {
    final (kind, superclass) = switch (resultSet) {
      DriftTable(virtualTableData: null) => (
          _ResultSetKind.table,
          'VersionedTable'
        ),
      DriftTable() => (_ResultSetKind.virtualTable, 'VersionedVirtualTable'),
      DriftView() => (_ResultSetKind.view, 'VersionedView'),
      _ => throw ArgumentError.value(resultSet, 'resultSet', 'Unknown type'),
    };

    final shape = _TableShape(kind, _TableShape.columnsFrom(resultSet));
    return _shapes.putIfAbsent(shape, () {
      final className = 'Shape${_shapes.length}';
      final classWriter = libraryScope.leaf();

      classWriter
        ..write('class $className extends ')
        ..writeUriRef(_schemaLibrary, superclass)
        ..writeln('{')
        ..writeln(
            '$className({required super.source, required super.alias}) : super.aliased();');

      for (final MapEntry(key: getterName, value: (sqlName, type))
          in shape.columnTypes.entries) {
        final columnType = AnnotatedDartCode([dartTypeNames[type]!]);

        classWriter
          ..writeDriftRef('GeneratedColumn<')
          ..writeDart(columnType)
          ..write('> get ')
          ..write(getterName)
          ..write(' => columnsByName[${asDartLiteral(sqlName)}]! as ')
          ..writeDriftRef('GeneratedColumn<')
          ..writeDart(columnType)
          ..writeln('>;');
      }

      classWriter.writeln('}');

      return className;
    });
  }

  void _writeWithResultSet(DriftElementWithResultSet entity, Scope classScope,
      TextEmitter intoListWriter) {
    final getterName = entity.dbGetterName;
    final shape = _shapeClass(entity);
    final writer = classScope.leaf()
      ..write('late final $shape $getterName = ')
      ..write('$shape(source: ');

    switch (entity) {
      case DriftTable():
        if (entity.isVirtual) {
          final info = entity.virtualTableData!;

          writer
            ..writeUriRef(_schemaLibrary, 'VersionedVirtualTable(')
            ..write('entityName: ${asDartLiteral(entity.schemaName)},')
            ..write('moduleAndArgs: ${asDartLiteral(info.moduleAndArgs)},');
        } else {
          final tableConstraints = <String>[];

          if (entity.writeDefaultConstraints) {
            // We don't override primaryKey and uniqueKey in generated table
            // classes to keep the code shorter. The migrator would use those
            // getters to generate SQL at runtime, which means that this burden
            // now falls onto the generator.
            for (final constraint in entity.tableConstraints) {
              final astNode = switch (constraint) {
                PrimaryKeyColumns(primaryKey: var columns) => sql.KeyClause(
                    null,
                    isPrimaryKey: true,
                    columns: [
                      for (final column in columns)
                        sql.IndexedColumn(
                            sql.Reference(columnName: column.nameInSql))
                    ],
                  ),
                UniqueColumns(uniqueSet: var columns) => sql.KeyClause(
                    null,
                    isPrimaryKey: false,
                    columns: [
                      for (final column in columns)
                        sql.IndexedColumn(
                            sql.Reference(columnName: column.nameInSql))
                    ],
                  ),
                ForeignKeyTable() => sql.ForeignKeyTableConstraint(
                    null,
                    columns: [
                      for (final column in constraint.localColumns)
                        sql.Reference(columnName: column.nameInSql)
                    ],
                    clause: sql.ForeignKeyClause(
                      foreignTable:
                          sql.TableReference(constraint.otherTable.schemaName),
                      columnNames: [
                        for (final column in constraint.otherColumns)
                          sql.Reference(columnName: column.nameInSql)
                      ],
                      onUpdate: constraint.onUpdate,
                      onDelete: constraint.onDelete,
                    ),
                  ),
              };

              tableConstraints.add(astNode.toSql());
            }
          }
          tableConstraints.addAll(entity.overrideTableConstraints.toList());

          writer
            ..writeUriRef(_schemaLibrary, 'VersionedTable(')
            ..write('entityName: ${asDartLiteral(entity.schemaName)},')
            ..write('withoutRowId: ${entity.withoutRowId},')
            ..write('isStrict: ${entity.strict},')
            ..write('tableConstraints: [');

          for (final constraint in tableConstraints) {
            writer
              ..write(asDartLiteral(constraint))
              ..write(',');
          }

          writer.write('],');
        }
        break;
      case DriftView():
        final source = entity.source as SqlViewSource;

        writer
          ..writeUriRef(_schemaLibrary, 'VersionedView(')
          ..write('entityName: ${asDartLiteral(entity.schemaName)},')
          ..write(
              'createViewStmt: ${asDartLiteral(source.sqlCreateViewStmt)},');

        break;
    }

    _writeColumnsArgument(entity.columns, writer);
    writer.write('attachedDatabase: database,');
    writer.write('), alias: null);');

    intoListWriter.write(getterName);
  }

  void _writeEntity({
    required DriftSchemaElement element,
    required Scope classScope,
    required TextEmitter writer,
  }) {
    if (element is DriftElementWithResultSet) {
      _writeWithResultSet(element, classScope, writer);
    } else if (element is DriftIndex) {
      writer
        ..writeDriftRef('Index(')
        ..write(asDartLiteral(element.schemaName))
        ..write(',')
        ..write(asDartLiteral(element.createStmt))
        ..write(')');
    } else if (element is DriftTrigger) {
      writer
        ..writeDriftRef('Trigger(')
        ..write(asDartLiteral(element.createStmt))
        ..write(',')
        ..write(asDartLiteral(element.schemaName))
        ..write(')');
    } else {
      writer.writeln('null');
    }
  }

  void write() {
    for (final version in versions) {
      final versionNo = version.version;
      final versionClass = '_S$versionNo';
      final versionScope = libraryScope.child();

      versionScope.leaf()
        ..write('final class $versionClass extends ')
        ..writeUriRef(_schemaLibrary, 'VersionedSchema')
        ..writeln('{')
        ..writeln('$versionClass({required super.database}): '
            'super(version: $versionNo);');

      final allEntitiesWriter = versionScope.leaf()
        ..write('@override')
        ..write(' late final ')
        ..writeUriRef(AnnotatedDartCode.dartCore, 'List')
        ..write('<')
        ..writeDriftRef('DatabaseSchemaEntity')
        ..write('> entities = [');

      for (final entity in version.schema) {
        _writeEntity(
          element: entity,
          classScope: versionScope,
          writer: allEntitiesWriter,
        );
        allEntitiesWriter.write(',');
      }

      allEntitiesWriter.write('];');
      versionScope.leaf().writeln('}');
    }

    final stepByStep = libraryScope.leaf()
      ..writeDriftRef('OnUpgrade')
      ..write(' stepByStep({');

    for (final (current, next) in versions.withNext) {
      stepByStep
        ..write('required Future<void> Function(')
        ..writeDriftRef('Migrator')
        ..write(' m, _S${next.version} schema)')
        ..writeln('from${current.version}To${next.version},');
    }

    stepByStep
      ..writeln('}) {')
      ..write('return ')
      ..writeDriftRef('Migrator')
      ..writeln('.stepByStepHelper(step: (currentVersion, database) async {')
      ..writeln('switch (currentVersion) {');

    for (final (current, next) in versions.withNext) {
      stepByStep
        ..writeln('case ${current.version}:')
        ..write('final schema = _S${next.version}(database: database);')
        ..write('final migrator = ')
        ..writeDriftRef('Migrator')
        ..writeln('(database, schema);')
        ..writeln(
            'await from${current.version}To${next.version}(migrator, schema);')
        ..writeln('return ${next.version};');
    }

    stepByStep
      ..writeln(
          r"default: throw ArgumentError.value('Unknown migration from $currentVersion');")
      ..writeln('}') // End of switch
      ..writeln('}') // End of stepByStepHelper function
      ..writeln(');') // End of stepByStepHelper call
      ..writeln('}'); // End of method
  }
}

extension<T> on Iterable<T> {
  Iterable<(T, T)> get withNext sync* {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return;

    var a = iterator.current;
    while (iterator.moveNext()) {
      var b = iterator.current;
      yield (a, b);

      a = b;
    }
  }
}
