library drift;

import 'package:collection/collection.dart';

// needed for the generated code that generates data classes with an Uint8List
// field.
export 'dart:typed_data' show Uint8List;

export 'src/dsl/dsl.dart';
export 'src/runtime/api/options.dart';
export 'src/runtime/api/runtime_api.dart';
export 'src/runtime/custom_result_set.dart';
export 'src/runtime/data_class.dart';
export 'src/runtime/data_verification.dart';
export 'src/runtime/exceptions.dart';
export 'src/runtime/executor/connection_pool.dart';
export 'src/runtime/executor/executor.dart';
export 'src/runtime/query_builder/query_builder.dart'
    hide CaseWhenExpressionWithBase, BaseCaseWhenExpression;
export 'src/runtime/types/converters.dart';
export 'src/runtime/types/mapping.dart' hide BaseSqlType;
export 'src/utils/lazy_database.dart';

/// A [ListEquality] instance used by generated drift code for the `==` and
/// [Object.hashCode] implementation of generated classes if they contain lists.
const ListEquality $driftBlobEquality = ListEquality();
