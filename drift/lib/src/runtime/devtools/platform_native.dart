import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

/// True if exporting is supported on this platform, false otherwise.
final bool isExportSupported = true;

/// Exports contents of the [database] as a [Uint8List] representing its main
/// file.
Future<Uint8List> exportDatabase(GeneratedDatabase database) async {
  final destination = p.join(Directory.systemTemp.path,
      "drift-export-${DateTime.now().toUtc().millisecondsSinceEpoch}.tmp");

  await database.exclusively(() async {
    await database.customStatement('VACUUM INTO ?;', [destination]);
  });

  final file = File(destination);
  final rawBytes = await file.readAsBytes();
  await file.delete();
  return rawBytes;
}
