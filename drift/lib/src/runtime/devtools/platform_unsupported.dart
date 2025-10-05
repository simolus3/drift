import 'package:drift/drift.dart';

/// Exports contents of the [database] as a [Uint8List] representing its main
/// file.
Future<Uint8List> exportDatabase(GeneratedDatabase database) async {
  // We currently only support this for native databases. We should also be able
  // to support web fairly easily after migrating to sqlite3_web.
  throw UnsupportedError(
      'Exporting databases it not supported on this platform');
}
