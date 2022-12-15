import 'package:analyzer/dart/element/element.dart';
import 'package:drift_dev/src/analysis/options.dart';
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
  final contents = database
      .select('select * from sqlite_master')
      .map((row) => row['sql'])
      .whereType<String>()
      .map((sql) => sql.endsWith(';') ? sql : '$sql;')
      .join('\n');

  final logger = Logger('extractDriftElementsFromDatabase');
  final uri = Uri.parse('db.drift');
  final backend = _SingleFileNoAnalyzerBackend(logger, contents, uri);
  final driver = DriftAnalysisDriver(
    backend,
    DriftOptions.defaults(
      sqliteAnalysisOptions: SqliteAnalysisOptions(
        modules: SqlModule.values,
        version: SqliteVersion.current,
      ),
    ),
  );

  final file = await driver.fullyAnalyze(uri);

  return [
    for (final entry in file.analysis.values)
      if (entry.result != null) entry.result!
  ];
}

class _SingleFileNoAnalyzerBackend extends DriftBackend {
  @override
  final Logger log;

  final String file;
  final Uri uri;

  _SingleFileNoAnalyzerBackend(this.log, this.file, this.uri);

  Never _noAnalyzer() =>
      throw UnsupportedError('Dart analyzer not available here');

  @override
  Future<Never> loadElementDeclaration(Element element) async {
    _noAnalyzer();
  }

  @override
  Future<String> readAsString(Uri uri) {
    return Future.value(file);
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
