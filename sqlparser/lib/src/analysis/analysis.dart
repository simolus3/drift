import 'dart:math' show max;

import 'package:collection/collection.dart' show IterableExtension;
import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';
// hiding because of http://dartbug.com/39263
import 'package:sqlparser/sqlparser.dart' hide ExpandParameters;
import 'package:sqlparser/src/utils/meta.dart';

import '../../utils/case_insensitive_map.dart';

export 'types/data.dart';
export 'types/types.dart' show TypeInferenceResults;

part 'context.dart';
part 'error.dart';
part 'options.dart';
part 'schema/column.dart';
part 'schema/from_create_table.dart';
part 'schema/references.dart';
part 'schema/result_set.dart';
part 'schema/table.dart';
part 'schema/view.dart';
part 'steps/column_resolver.dart';
part 'steps/linting_visitor.dart';
part 'steps/prepare_ast.dart';
part 'steps/reference_resolver.dart';
part 'steps/set_parent_visitor.dart';
part 'utils/expand_function_parameters.dart';

/// Something that can be represented in a human-readable description.
abstract class HumanReadable {
  String humanReadableDescription();
}
