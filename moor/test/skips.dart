import 'package:sqlite3/sqlite3.dart';

String? onNoReturningSupport() => sqlite3.version.versionNumber > 3035000
    ? null
    : 'RETURNING not supported by sqlite version ${sqlite3.version.libVersion}';
