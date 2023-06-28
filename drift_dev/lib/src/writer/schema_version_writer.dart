import 'package:collection/collection.dart';

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

class SchemaVersionWriter {
  static final Uri _schemaLibrary =
      Uri.parse('package:drift/internal/versioned_schema.dart');

  /// All schema versions, sorted by [SchemaVersion.version].
  final List<SchemaVersion> versions;
  final Scope scope;

  final Map<String, String> _columnCodeToFactory = {};

  /// All schema entities across all versions are put in a single list, sorted
  /// by their schema version.
  ///
  /// By keeping a start and end-index pair for each schema, we can efficiently
  /// find all schema entities for a given version at runtime.
  final rangesForVersion = <(int, int)>[];

  SchemaVersionWriter(this.versions, this.scope);

  String _referenceColumn(DriftColumn column) {
    final text = scope.leaf();
    final (type, code) = TableOrViewWriter.instantiateColumn(column, text);

    return _columnCodeToFactory.putIfAbsent(code, () {
      final methodName = 'column_${_columnCodeToFactory.length}';
      text.write('$type $methodName(String aliasedName) => $code;');
      return methodName;
    });
  }

  void _writeTable(DriftTable table, TextEmitter writer) {
    writer
      ..writeUriRef(_schemaLibrary, 'VersionedTable(')
      ..write('entityName: ${asDartLiteral(table.schemaName)},')
      ..write('withoutRowId: ${table.withoutRowId},')
      ..write('isStrict: ${table.strict},')
      ..write('attachedDatabase: database,')
      ..write('columns: [');

    for (final column in table.columns) {
      writer
        ..write(_referenceColumn(column))
        ..write(',');
    }

    writer
      ..write('],')
      ..write('tableConstraints: [],')
      ..write(')');
  }

  void _writeEntity(DriftSchemaElement element, TextEmitter writer) {
    if (element is DriftTable) {
      _writeTable(element, writer);
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

  void _implementAllEntitiesAt(TextEmitter writer) {
    writer
      ..writeln('@override')
      ..write('Iterable<')
      ..writeDriftRef('DatabaseSchemaEntity')
      ..writeln('> allEntitiesAt(int version) {')
      ..writeln('int start, count;')
      ..writeln('switch (version) {');

    versions.forEachIndexed((index, schema) {
      final (start, end) = rangesForVersion[index];

      writer
        ..writeln('case ${schema.version}:')
        ..writeln('start = $start;')
        ..writeln('count = ${end - start};');
    });

    writer
      ..writeln('default:')
      ..writeln(r"throw ArgumentError('Unknown schema version $version');");

    writer
      ..writeln('}')
      ..writeln('return entities.skip(start).take(count);')
      ..writeln('}');
  }

  void write() {
    final classWriter = scope.leaf();

    classWriter
      ..write('final class VersionedSchema extends ')
      ..writeUriRef(_schemaLibrary, 'VersionedSchema')
      ..writeln('{')
      ..writeln('VersionedSchema(super.database);');

    var currentIndex = 0;
    classWriter
      ..write('late final ')
      ..writeUriRef(AnnotatedDartCode.dartCore, 'List')
      ..write('<')
      ..writeDriftRef('DatabaseSchemaEntity')
      ..write('> entities = [');

    for (final version in versions) {
      classWriter.writeln(' // VERSION ${version.version}');
      final startIndex = currentIndex;

      for (final entity in version.schema) {
        _writeEntity(entity, classWriter);
        classWriter.writeln(',');
        currentIndex++;
      }

      final endIndex = currentIndex;
      rangesForVersion.add((startIndex, endIndex));
    }
    classWriter.write('];');

    _implementAllEntitiesAt(classWriter);

    classWriter.writeln('}');
  }
}
