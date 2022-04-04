import 'package:sqlite3/common.dart';

String? ifOlderThanSqlite335(Version version) => version.versionNumber > 3035000
    ? null
    : 'RETURNING not supported by sqlite version ${version.libVersion}';
