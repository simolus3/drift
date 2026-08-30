import 'package:collection/collection.dart';

export 'src/connection/connection.dart';
export 'src/connection/interceptor.dart';
export 'src/connection/result_set.dart' show QueryResult, RawResultSet, RawRow;
export 'src/connection/streams/store.dart' hide QueryStream, QueryStreamFetcher;
export 'src/connection/streams/in_memory_store.dart';
export 'src/connection/streams/update_rules.dart'
    hide AnyUpdateQuery, MultipleUpdateQuery, SpecificUpdateQuery;

export 'src/database/batch.dart' hide createBatch, runBatch;
export 'src/database/connection_user.dart' hide InternalConnectionUser;
export 'src/database/custom_select.dart' show CustomRow, CustomResultSet;
export 'src/database/data_class.dart';
export 'src/database/accessor_base.dart';
export 'src/database/db_base.dart' hide InternalGeneratedDatabase;
export 'src/database/migrations.dart';
export 'src/database/selectable.dart';

export 'src/dsl/columns.dart';
export 'src/dsl/database.dart';
export 'src/dsl/table.dart';

export 'src/exceptions.dart';

export 'src/query_builder.dart' hide SingleTableStatementMixin, BuiltinSqlType;
export 'src/runtime_options.dart';

export 'src/utils/cancellation_zone.dart'
    show checkIfCancelled, cancellationSignal, CancellationException;

/// A [ListEquality] instance used by generated drift code for the `==` and
/// [Object.hashCode] implementation of generated classes if they contain lists.
const ListEquality<int> $driftBlobEquality = ListEquality();
