import 'package:collection/collection.dart';

export 'src/connections/connection.dart';
export 'src/connections/result_set.dart' show ColumnPosition, QueryResult;

export 'src/dsl/columns.dart';
export 'src/dsl/database.dart';
export 'src/dsl/table.dart';

export 'src/query_builder.dart';

export 'src/runtime/data_class.dart';
export 'src/runtime/database/connection_user.dart' hide InternalConnectionUser;
export 'src/runtime/database/custom_select.dart' hide CustomSelectStatement;
export 'src/runtime/database/db_base.dart' hide InternalGeneratedDatabase;
export 'src/runtime/exceptions.dart';
export 'src/runtime/migrations.dart';
export 'src/runtime/streams/update_rules.dart'
    hide AnyUpdateQuery, MultipleUpdateQuery, SpecificUpdateQuery;
export 'src/runtime/runtime_options.dart';
export 'src/runtime/selectable.dart';
export 'src/runtime/type_converter.dart';

/// A [ListEquality] instance used by generated drift code for the `==` and
/// [Object.hashCode] implementation of generated classes if they contain lists.
const ListEquality $driftBlobEquality = ListEquality();
