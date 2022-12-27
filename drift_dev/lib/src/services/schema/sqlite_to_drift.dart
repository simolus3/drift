import 'package:analyzer/dart/element/element.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/services/schema/verifier_impl.dart';
import 'package:logging/logging.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlparser/sqlparser.dart';

import '../../analysis/backend.dart';
import '../../analysis/driver/driver.dart';
import '../../analysis/results/results.dart';

/// Extracts drift elements from the schema of an existing database.
///
/// At the moment, this is used to generate database schema files for databases
/// (as an alternative to using static analysis to infer the expected schema).
/// In the future, this could also be a starting point for users with existing
/// databases wanting to migrate to drift.
Future<List<DriftElement>> extractDriftElementsFromDatabase(
    CommonDatabase database) async {
  // Put everything from sqlite_schema into a fake drift file, analyze it.
  final logger = Logger('extractDriftElementsFromDatabase');
  final uri = Uri.parse('db.drift');
  final backend = _SingleFileNoAnalyzerBackend(logger, uri);
  final driver = DriftAnalysisDriver(
    backend,
    DriftOptions.defaults(
      sqliteAnalysisOptions: SqliteAnalysisOptions(
        modules: SqlModule.values,
        version: SqliteVersion.current,
      ),
    ),
  );

  final engineForParsing = driver.newSqlEngine();
  final entities = <String, String>{};
  final virtualTableNames = <String>[];
  for (final row in database.select('select * from sqlite_master')) {
    final name = row['name'] as String?;
    var sql = row['sql'] as String?;

    if (name == null ||
        sql == null ||
        isInternalElement(name, virtualTableNames)) {
      continue;
    }

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

    entities[name] = sql;
  }
  entities.removeWhere((name, _) => isInternalElement(name, virtualTableNames));
  backend.contents = entities.values.join('\n');

  final file = await driver.resolveElements(uri);
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
  Future<LibraryElement> readDart(Uri uri) async {
    _noAnalyzer();
  }

  @override
  Future<Never> resolveExpression(
      Uri context, String dartExpression, Iterable<String> imports) async {
    _noAnalyzer();
  }

  @override
  Uri resolveUri(Uri base, String uriString) {
    return uri;
  }
}
