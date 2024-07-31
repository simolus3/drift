import 'dart:isolate';

import 'package:drift/drift.dart';

import '../src/runtime/devtools/service_extension.dart';
import '../src/runtime/executor/transactions.dart';
import '../src/runtime/api/runtime_api.dart';

/// Utility that exports the DDL schema statements making up a drift database.
final class SchemaExporter {
  final GeneratedDatabase Function(QueryExecutor) _database;

  /// Utility that exports the DDL schema statements making up a drift database.
  ///
  /// The passed function must take a [QueryExecutor] and return a drift
  /// database class.
  SchemaExporter(this._database);

  /// Opens the database and runs the `onCreate` migration callback, collecting
  /// all statements that were executed in the process.
  Future<List<String>> collectOnCreateStatements(
      [SqlDialect dialect = SqlDialect.sqlite]) async {
    final collector = CollectCreateStatements(dialect);
    final db = _database(collector);
    await db.runConnectionZoned(BeforeOpenRunner(db, collector), () async {
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      final migrator = db.createMigrator();
      await migrator.createAll();
    });

    return collector.statements;
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
    GeneratedDatabase Function(QueryExecutor) database,
  ) async {
    final export = SchemaExporter(database);
    final statements = await export
        .collectOnCreateStatements(SqlDialect.values.byName(args.single));
    port.send(statements);
  }
}
