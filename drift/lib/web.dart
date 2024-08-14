/// A version of drift that runs on the web by using [sql.js](https://github.com/sql-js/sql.js)
/// You manually need to include that library into your website to use the
/// web version of drift. See [the documentation](https://drift.simonbinder.eu/web)
/// for a more detailed instruction.
@Deprecated(
  'This variant of web support has downsides compared to '
  '`package:drift/wasm.dart` and is in a deprecated bugfix-only mode. '
  'Please consider migrating to the new web APIS: https://drift.simonbinder.eu/web',
)
library drift.web;

export 'src/web/sql_js.dart';
export 'src/web/storage.dart' hide CustomSchemaVersionSave;
export 'src/web/web_db.dart';
export 'src/web/channel.dart' show PortToChannel;
