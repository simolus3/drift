import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:drift/drift.dart' show SqlDialect;

import '../../../analysis/options.dart';
import '../../../analysis/results/file_results.dart';
import '../../../analysis/results/results.dart';
import '../../../services/schema/schema_files.dart';
import '../../../writer/database_writer.dart';
import '../../../writer/import_manager.dart';
import '../../../writer/writer.dart';
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

    // The roundtrip through the schema writer ensures that irrelevant things
    // like type converters that would break imports are removed.
    final schemaWriter = SchemaWriter(elements, options: cli.project.options);
    final json = schemaWriter.createSchemaJson();
    elements = SchemaReader.readJson(json).entities.toList();

    // Ok, so the way this works is that we create a Dart script containing the
    // relevant definitions and then spawn that as an isolate...

    final writer = Writer(
      DriftOptions.fromJson({
        ...cli.project.options.toJson(),
        'generate_manager': false,
        'sql': {
          'dialect': dialect.name,
        },
      }),
      generationOptions: GenerationOptions(
        forSchema: 1,
        writeCompanions: false,
        writeDataClasses: false,
        imports: NullImportManager(),
      ),
    );

    writer.leaf().writeln('''
import 'dart:isolate';
import 'package:drift/drift.dart';
import 'package:drift/internal/export_schema.dart';

void main(List<String> args, SendPort port) {
  SchemaExporter.run(args, port, DatabaseAtV1.new);
}
''');

    final database = DriftDatabase(
      id: DriftElementId(SchemaReader.elementUri, 'database'),
      declaration: DriftDeclaration(SchemaReader.elementUri, 0, 'database'),
      declaredIncludes: const [],
      declaredQueries: const [],
      declaredTables: const [],
      declaredViews: const [],
    );
    final resolved = ResolvedDatabaseAccessor(const {}, const [], elements);
    final input = DatabaseGenerationInput(database, resolved, const {}, null);

    DatabaseWriter(input, writer.child()).write();

    final receive = ReceivePort();
    final receiveErrors = ReceivePort();
    final isolate = await Isolate.spawnUri(
      Uri.dataFromString(writer.writeGenerated()),
      [dialect.name],
      receive.sendPort,
      errorsAreFatal: true,
      onError: receiveErrors.sendPort,
    );

    await Future.any([
      receiveErrors.firstOrNever.then((e) {
        stderr
          ..writeln('Could not spawn isolate to print statements: $e')
          ..flush();
      }),
      receive.firstOrNever.then((statements) {
        for (final statement in (statements as List).cast<String>()) {
          if (statement.endsWith(';')) {
            print(statement);
          } else {
            print('$statement;');
          }
        }
      }),
    ]);

    isolate.kill();
    receiveErrors.close();
    receive.close();
  }
}

extension<T> on Stream<T> {
  /// Variant of [Stream.first] that, when the stream is closed without emitting
  /// an event, simply never completes instead of throwing.
  Future<T> get firstOrNever {
    final completer = Completer<T>.sync();
    late StreamSubscription<T> subscription;
    subscription = listen((data) {
      subscription.cancel();
      completer.complete(data);
    }, onError: (Object error, StackTrace trace) {
      subscription.cancel();
      completer.completeError(error, trace);
    });
    return completer.future;
  }
}
