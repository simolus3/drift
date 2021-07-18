/// Provides access to the [Writer], which can generate Dart code for parsed
/// databases, daos, queries, tables and more.
library writer;

import 'src/writer/writer.dart' show Writer;

export 'src/writer/database_writer.dart';
export 'src/writer/queries/query_writer.dart';
export 'src/writer/queries/result_set_writer.dart';
export 'src/writer/tables/data_class_writer.dart';
export 'src/writer/tables/table_writer.dart';
export 'src/writer/tables/update_companion_writer.dart';
export 'src/writer/utils/hash_code.dart';
export 'src/writer/utils/memoized_getter.dart';
export 'src/writer/utils/override_equals.dart';
export 'src/writer/writer.dart';
