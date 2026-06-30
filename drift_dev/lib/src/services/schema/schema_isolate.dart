import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:drift/drift.dart' show SqlDialect;
import 'package:path/path.dart' as p;

import '../../analysis/options.dart';
import '../../analysis/results/file_results.dart';
import '../../analysis/results/results.dart';
import '../../writer/database_writer.dart';
import '../../writer/import_manager.dart';
import '../../writer/writer.dart';
import 'schema_files.dart';

/// Utilities for starting up an isolate to run Dart code extracting information
/// about a drift schema.
///
/// By design, most drift elements are fully resolved at build time - allowing
/// us to infer the exact schema of the database without running user code.
/// However, drift views defined in a Dart use the query builder APIs to define
/// the inner select statement, which we can't infer statically.
/// [SchemaIsolate] is able to obtain the generated `CREATE` statements by
/// running the generator and then spawning a new isolate with the generated
/// code.
class SchemaIsolate {
  static Future<String> generateStartupCode(
    SchemaIsolateOptions options,
  ) async {
    final imports = LibraryImportManager();
    final writer = Writer(
      DriftOptions.fromJson({
        ...options.options.toJson(),
        'generate_manager': false,
        'skip_verification_code': true,
        'data_class_to_companions': false,
        'sql': {
          'dialects': switch (options.dialect) {
            null => SqlDialect.values.map((e) => e.name).toList(),
            var dialect => [dialect.name],
          },
        },
      }),
      generationOptions: GenerationOptions(
        forSchema: 1,
        writeCompanions: false,
        writeDataClasses: false,
        avoidUserCode: true,
        imports: imports,
      ),
    );
    imports.linkToWriter(writer);

    String prefixed(Uri uri, String element) {
      final prefix = imports.prefixFor(uri, element);
      if (prefix == null) {
        return element;
      } else {
        return '$prefix.$element';
      }
    }

    final core = AnnotatedDartCode.dartCore;
    final isolate = Uri.parse('dart:isolate');
    final schemaTools = Uri.parse('package:drift/internal/export_schema.dart');

    writer.leaf()
      ..writeln(
        'void main('
        '${prefixed(core, 'List')}<${prefixed(core, 'String')}> args, '
        '${prefixed(isolate, 'SendPort')} port) {',
      )
      ..writeln(
        '${prefixed(schemaTools, 'SchemaExporter')}'
        '.run(args, port, DatabaseAtV1.new);',
      )
      ..writeln('}');

    final database = DriftDatabase(
      id: DriftElementId(SchemaReader.elementUri, 'database'),
      declaration: DriftDeclaration(SchemaReader.elementUri, 0, 'database'),
      declaredIncludes: const [],
      declaredQueries: const [],
      declaredTables: const [],
      declaredViews: const [],
      hasConstructorArgumentForConnection: false,
    );
    final resolved = ResolvedDatabaseAccessor(
      const {},
      const [],
      options.elements,
    );
    final input = DatabaseGenerationInput(database, resolved, {
      for (final query in options.elements.whereType<DefinedSqlQuery>())
        if (query.mode == QueryMode.atCreate) query: ?query.resolved,
    }, null);

    DatabaseWriter(input, writer.child()).write();

    return writer.writeGenerated();
  }

  static Future<Object?> _startAndRun(
    SchemaIsolateOptions options,
    List<String> args,
  ) async {
    final code = await generateStartupCode(options);
    File entrypointFile;
    Directory? deleteAfterGeneration;

    if (options.dumpStartupCode case final file?) {
      await file.parent.create(recursive: true);
      entrypointFile = file;
    } else {
      deleteAfterGeneration = Directory.systemTemp.createTempSync(
        'drift_export',
      );
      entrypointFile = File(p.join(deleteAfterGeneration.path, 'main.dart'));
    }

    await entrypointFile.writeAsString(code);

    final receive = ReceivePort();
    final receiveErrors = ReceivePort();
    final Isolate isolate;
    try {
      isolate = await Isolate.spawnUri(
        entrypointFile.uri,
        args,
        receive.sendPort,
        errorsAreFatal: true,
        onError: receiveErrors.sendPort,
        packageConfig: await Isolate.packageConfig,
      );
    } catch (e) {
      throw SchemaIsolateException(e, entrypointFile);
    }

    final result = await Future.any([
      receive.firstOrNever,
      receiveErrors.firstOrNever.then((e) {
        throw SchemaIsolateException(e! as Object, entrypointFile);
      }),
    ]);

    isolate.kill();
    receiveErrors.close();
    receive.close();
    if (deleteAfterGeneration != null) {
      await deleteAfterGeneration.delete(recursive: true);
    }

    return result;
  }

  static Future<List<String>> collectAllCreateStatements(
    SchemaIsolateOptions options,
  ) async {
    final result = await _startAndRun(options, [options.dialect!.name]);
    return result as List<String>;
  }

  static Future<List<CreateStatement>> collectStatements({
    required DriftOptions options,
    required List<DriftElement> allElements,
    File? dumpStartupCode,
  }) async {
    final result = await _startAndRun(
      (
        options: options,
        dialect: null,
        elements: allElements,
        dumpStartupCode: dumpStartupCode,
      ),
      [
        'v2',
        json.encode({
          'dialects': [
            for (final dialect in options.supportedDialects) dialect.name,
          ],
        }),
      ],
    );

    // This returns a list of [name, dialectName, createStmt] entries
    return (result as List<List>).map((row) {
      return (
        elementName: row[0] as String,
        dialect: SqlDialect.values.byName(row[1] as String),
        createStatement: row[2] as String,
      );
    }).toList();
  }
}

typedef SchemaIsolateOptions = ({
  DriftOptions options,
  List<DriftElement> elements,
  SqlDialect? dialect,
  File? dumpStartupCode,
});

typedef CreateStatement = ({
  String elementName,
  SqlDialect dialect,
  String createStatement,
});

extension<T> on Stream<T> {
  /// Variant of [Stream.first] that, when the stream is closed without emitting
  /// an event, simply never completes instead of throwing.
  Future<T> get firstOrNever {
    final completer = Completer<T>.sync();
    late StreamSubscription<T> subscription;
    subscription = listen(
      (data) {
        subscription.cancel();
        completer.complete(data);
      },
      onError: (Object error, StackTrace trace) {
        subscription.cancel();
        completer.completeError(error, trace);
      },
    );
    return completer.future;
  }
}

final class SchemaIsolateException implements Exception {
  final Object cause;
  final File startupCodeWrittenTo;

  SchemaIsolateException(this.cause, this.startupCodeWrittenTo);

  String description({bool isFatal = true}) {
    var causeDesc = cause.toString();
    if (causeDesc.length > 300) {
      causeDesc = '${causeDesc.substring(0, 300)}...';
    }

    var desc =
        'Drift tried to run parts of your database code to obtain a '
        'complete schema for aspects where static analysis is not enough.\n'
        'This failed: $causeDesc.\n'
        'A copy of the code that failed to run has been written to: '
        '${p.relative(startupCodeWrittenTo.path)}.';

    if (!isFatal) {
      desc +=
          '\nDrift will fall-back to only using results obtained through '
          'static analysis, but restructing your code to avoid this compiler '
          'error can help drift export more detailed schema descriptions.';
    }

    desc +=
        '\nMore information is available here: https://drift.simonbinder.eu/migrations/exports/#debugging-issues-exporting-your-schema';
    return desc;
  }

  @override
  String toString() {
    return description();
  }
}

extension RegisterExportSchemaStartupOptions on ArgParser {
  void registerExportSchemaStartupCodeOption() {
    addOption(
      'export-schema-startup-code',
      valueHelp: 'file',
      help:
          'When drift needs to run parts of your database code to infer '
          'the schema, emit that code to find possible issues.',
    );
  }
}

extension GetExportSchemaStartupOptions on ArgResults {
  File? get exportSchemaStartupCode {
    return switch (option('export-schema-startup-code')) {
      final path? => File(path),
      _ => null,
    };
  }
}
