import 'package:analyzer/dart/element/element.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:logging/logging.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlparser/sqlparser.dart';

import '../../analysis/backend.dart';
import '../../analysis/driver/driver.dart';
import '../../analysis/results/results.dart';
import 'schema_files.dart';
import 'verifier_common.dart';

/// Extracts drift elements from the schema of an existing database.
///
/// At the moment, this is used to generate database schema files for databases
/// (as an alternative to using static analysis to infer the expected schema).
/// In the future, this could also be a starting point for users with existing
/// databases wanting to migrate to drift.
Future<List<DriftElement>> extractDriftElementsFromDatabase(
    CommonDatabase database) async {
  // Put everything from sqlite_schema into a fake drift file, analyze it.
  final createStatements = <String>[];
  for (final row in database.select('select * from sqlite_master')) {
    final name = row['name'] as String?;
    var sql = row['sql'] as String?;

    if (name == null || sql == null) {
      continue;
    }

    if (!sql.endsWith(';')) {
      sql += ';';
    }

    createStatements.add(sql);
  }

  return await extractDriftElementsFromSql(createStatements);
}

Future<List<DriftElement>> extractDriftElementsFromSql(
    List<String> nameToCreateStatements) async {
  // Put all create statements into a fake file, then analyze it.
  final logger = Logger('extractDriftElementsFromSql');
  final uri = SchemaReader.elementUri;
  final backend = _SingleFileNoAnalyzerBackend(logger, uri);
  final driver = DriftAnalysisDriver(
      backend,
      DriftOptions.defaults(
        sqliteAnalysisOptions: SqliteAnalysisOptions(
          modules: SqlModule.values,
          version: SqliteVersion.current,
        ),
      ),
      isTesting: true);

  final engineForParsing = driver.newSqlEngine();
  final entities = <String, String>{};
  final virtualTableNames = <String>[];
  for (var sql in nameToCreateStatements) {
    if (!sql.endsWith(';')) {
      sql += ';';
    }

    final parsed = engineForParsing.parse(sql).rootNode;

    // Virtual table modules often add auxiliary tables that aren't part of the
    // user-defined database schema. So we need to keep track of them to be
    // able to filter internal tables out.
    if (parsed is CreateVirtualTableStatement) {
      virtualTableNames.add(parsed.tableName);
    }

    if (parsed is CreatingStatement) {
      if (!isInternalElement(parsed.createdName, virtualTableNames)) {
        entities[parsed.createdName] = sql;
      }
    } else {
      entities['atCreate_${entities.length}'] = '@create: $sql';
    }
  }
  entities.removeWhere((name, _) => isInternalElement(name, virtualTableNames));
  backend.contents = entities.values.join('\n');

  final file = await driver.resolveElements(uri);
  final engine = driver.newSqlEngine();
  for (final element in file.analysis.values) {
    final result = element.result;
    switch (result) {
      case DriftTrigger():
        result.parsedStatement = engine
            .parse(entities[element.ownId.name]!)
            .rootNode as CreateTriggerStatement;
      case DriftIndex():
        result.parsedStatement = engine
            .parse(entities[element.ownId.name]!)
            .rootNode as CreateIndexStatement;
      case DriftView():
        if (result.source case final SqlViewSource source) {
          source.parsedStatement = engine
              .parse(entities[element.ownId.name]!)
              .rootNode as CreateViewStatement;
        }
    }
  }

  return [
    for (final entry in file.analysis.values)
      if (entry.result != null) entry.result!
  ];
}

class _SingleFileNoAnalyzerBackend extends DriftBackend {
  @override
  final Logger log;

  late final String contents;
  final Uri uri;

  _SingleFileNoAnalyzerBackend(this.log, this.uri);

  Never _noAnalyzer() =>
      throw UnsupportedError('Dart analyzer not available here');

  @override
  Future<Never> loadElementDeclaration(Element element) async {
    _noAnalyzer();
  }

  @override
  Future<String> readAsString(Uri uri) {
    return Future.value(contents);
  }

  @override
  bool get canReadDart => false;

  @override
  Future<LibraryElement> readDart(Uri uri) async {
    _noAnalyzer();
  }

  @override
  Future<Never> resolveExpression(
      Uri context, String dartExpression, Iterable<String> imports) async {
    _noAnalyzer();
  }

  @override
  Future<Element?> resolveTopLevelElement(
      Uri context, String reference, Iterable<Uri> imports) {
    _noAnalyzer();
  }

  @override
  Uri resolveUri(Uri base, String uriString) {
    return uri;
  }
}
