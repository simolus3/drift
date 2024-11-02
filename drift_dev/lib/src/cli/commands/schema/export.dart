import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:drift/drift.dart' show SqlDialect;

import '../../../services/schema/schema_isolate.dart';
import '../schema.dart';
import '../../cli.dart';

class ExportSchemaCommand extends Command {
  final DriftDevCli cli;

  ExportSchemaCommand(this.cli) {
    argParser.addOption(
      'dialect',
      abbr: 'd',
      help: 'The dialect for which to create DDL statements.',
      allowed: SqlDialect.values.map((e) => e.name),
      defaultsTo: 'sqlite',
    );
  }

  @override
  String get description =>
      'Emit semicolon-separated SQL statements for tables of a drift database.';

  @override
  String get name => 'export';

  @override
  String get invocation {
    return '${runner!.executableName} schema export [arguments] <path/to/database.dart>';
  }

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      usageException(
          'Expected input path to Dart source declaring database file.');
    }
    final dialect =
        SqlDialect.values.byName(argResults!.option('dialect') ?? 'sqlite');

    var (:elements, schemaVersion: _, db: _) =
        await cli.readElementsFromSource(File(rest.single).absolute);

    final options = (dialect: dialect, elements: elements);
    final statements = await SchemaIsolate.collectAllCreateStatements(options);
    for (final statement in statements) {
      if (statement.endsWith(';')) {
        print(statement);
      } else {
        print('$statement;');
      }
    }
  }
}
