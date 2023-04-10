/// A version of drift that runs on the web by using [sql.js](https://github.com/sql-js/sql.js)
/// You manually need to include that library into your website to use the
/// web version of drift. See [the documentation](https://drift.simonbinder.eu/web)
/// for a more detailed instruction.
@experimental
library drift.web;

import 'package:meta/meta.dart';

export 'src/web/sql_js.dart';
export 'src/web/storage.dart' hide CustomSchemaVersionSave;
export 'src/web/web_db.dart';
export 'src/web/channel.dart';
