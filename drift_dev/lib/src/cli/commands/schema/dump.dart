import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../services/schema/schema_files.dart';
import '../../../services/schema/sqlite_to_drift.dart';
import '../../cli.dart';
import '../schema.dart';

class DumpSchemaCommand extends Command {
  @override
  String get description => 'Export the entire table structure into a file';

  @override
  String get name => 'dump';

  @override
  String get invocation {
    return '${runner!.executableName} schema dump [arguments] <input> <output>';
  }

  final DriftDevCli cli;

  DumpSchemaCommand(this.cli) {
    argParser.addSeparator("It's recommended to run this commend from the "
        'directory containing your pubspec.yaml so that compiler options '
        'are respected.');
  }

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      usageException('Expected input and output files');
    }

    final absolute = File(rest[0]).absolute;
    final AnalyzedDatabase result;
    if (await absolute.isSqlite3File) {
      result = await _readElementsFromDatabase(absolute);
    } else {
      result = await cli.readElementsFromSource(absolute);
    }

    final writer = SchemaWriter(result.elements, options: cli.project.options);

    var target = rest[1];
    // This command is most commonly used to write into
    // `<dir>/drift_schema_vx.json`. When we get a directory as a second arg,
    // try to infer the file name.
    if (await FileSystemEntity.isDirectory(target) ||
        !target.endsWith('.json')) {
      final version = result.schemaVersion;

      if (version == null) {
        // Couldn't read schema from database, so fail.
        usageException(
          'Target is a directory and the schema version could not be read from '
          'the database class. Please use a full filename (e.g. '
          '`$target/drift_schema_v3.json`)',
        );
      }

      target = join(target, 'drift_schema_v$version.json');
    }

    final file = File(target).absolute;
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    await file.writeAsString(json.encode(writer.createSchemaJson()));
    print('Wrote to $target');
  }

  /// Reads available drift elements from an existing sqlite database file.
  Future<AnalyzedDatabase> _readElementsFromDatabase(File database) async {
    final opened = sqlite3.open(database.path);

    try {
      final elements = await extractDriftElementsFromDatabase(opened);
      final userVersion =
          opened.select('pragma user_version').single.columnAt(0) as int;

      return (elements: elements, schemaVersion: userVersion, db: null);
    } finally {
      opened.dispose();
    }
  }
}

extension on File {
  static final _headerStart = ascii.encode('SQLite format 3\u0000');

  /// Checks whether the file is probably a sqlite3 database file by looking at
  /// the initial bytes of the expected header.
  Future<bool> get isSqlite3File async {
    final opened = await open();

    try {
      final bytes = Uint8List(_headerStart.length);
      final bytesRead = await opened.readInto(bytes);

      if (bytesRead < bytes.length) {
        return false;
      }

      return const ListEquality<int>().equals(_headerStart, bytes);
    } finally {
      await opened.close();
    }
  }
}
