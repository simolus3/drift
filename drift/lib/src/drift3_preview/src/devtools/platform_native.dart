import 'dart:io';
import 'dart:typed_data';

import '../database/db_base.dart';
import '../query_builder/expressions/variables.dart';

/// True if exporting is supported on this platform, false otherwise.
final bool isExportSupported = true;

/// Exports contents of the [database] as a [Uint8List] representing its main
/// file.
Future<Uint8List> exportDatabase(GeneratedDatabase database) async {
  final destination = Directory.systemTemp.uri.resolve(
    "drift-export-${DateTime.now().toUtc().millisecondsSinceEpoch}.tmp",
  );

  await database.exclusively(() async {
    await database.customStatement('VACUUM INTO ?;', [
      Variable.withString(destination.toFilePath()),
    ]);
  });

  final file = File.fromUri(destination);
  final rawBytes = await file.readAsBytes();
  await file.delete();
  return rawBytes;
}
