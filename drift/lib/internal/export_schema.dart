import 'dart:convert';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift/src/runtime/devtools/shared.dart';

import '../sqlite3/dialect.dart';
import '../src/runtime/database/connection_user.dart';
import '../src/runtime/devtools/dialects.dart';
import '../src/runtime/devtools/service_extension.dart';

/// Utility that exports the DDL schema statements making up a drift database.
final class SchemaExporter {
  final GeneratedDatabase Function(DriftConnection) _database;

  /// Utility that exports the DDL schema statements making up a drift database.
  ///
  /// The passed function must take a [DriftConnection] and return a drift
  /// database class.
  SchemaExporter(this._database);

  /// Opens the database and runs the `onCreate` migration callback, collecting
  /// all statements that were executed in the process.
  Future<List<String>> collectOnCreateStatements(
      [DriftDialect dialect = const SqliteDialect()]) async {
    final collected = await _collect(dialects: [dialect]);
    return collected.collectedStatements.map((e) => e.stmt).toList();
  }

  Future<_CollectByDialect> _collect({
    required Iterable<DriftDialect> dialects,
    List<String>? elementNames,
  }) async {
    final interceptor = _CollectByDialect();
    for (final dialect in dialects) {
      final known = dialect.known;
      if (known == null) continue;

      interceptor.currentDialect = known;

      final connection = DriftConnection(
          dialect: dialect,
          openConnection: () async =>
              CollectCreateStatements().interceptWith(interceptor));
      final (session, streams) = await connection.open();
      final db = _database(connection);

      await db.runConnectionZoned(session, streams, () async {
        final migrator = db.createMigrator();

        for (final entity in db.allSchemaEntities) {
          if (elementNames == null ||
              elementNames.contains(entity.entityName)) {
            interceptor.currentName = entity.entityName;
            await migrator.create(entity);
          }
        }
      });
    }

    return interceptor;
  }

  /// Creates a [SchemaExporter] with the [database], parses the single-argument
  /// [args] list as a dialect name, calls [collectOnCreateStatements] and sends
  /// the resulting list over the [port].
  ///
  /// This sequence is used by the `drift_dev schema export` command, which
  /// prints `CREATE` statements making up a drift database analyzed from
  /// source. For this to work, it emulates a drift build and then creates a
  /// Dart program calling this method.
  ///
  /// This method is thus internal to that utility and likely not useful outside
  /// of that.
  static Future<void> run(
    List<String> args,
    SendPort port,
    GeneratedDatabase Function(DriftConnection) database,
  ) async {
    final export = SchemaExporter(database);

    if (args case ['v2', final options]) {
      final parsedOptions = json.decode(options);
      final dialects = (parsedOptions['dialects'] as List)
          .map((e) => deserializeDialect(e as JsonObject));
      final elements = (parsedOptions['elements'] as List).cast<String>();

      final result =
          await export._collect(dialects: dialects, elementNames: elements);
      final serialized = [
        for (final row in result.collectedStatements)
          [row.element, row.dialect.name, row.stmt]
      ];

      port.send(serialized);
    } else {
      throw UnsupportedError('Unsupported arguments');
    }
  }
}

final class _CollectByDialect extends QueryInterceptor {
  KnownSqlDialect currentDialect = KnownSqlDialect.sqlite;
  String? currentName;

  final List<({String element, KnownSqlDialect dialect, String stmt})>
      collectedStatements = [];

  @override
  Future<QueryResult> execute(DriftSession session, StatementInfo statement) {
    if (currentName != null) {
      collectedStatements.add((
        element: currentName!,
        dialect: currentDialect,
        stmt: statement.sql
      ));
    }

    return session.execute(statement);
  }
}
