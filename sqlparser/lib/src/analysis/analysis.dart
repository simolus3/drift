import 'dart:math' show min, max;

import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';
// hiding because of http://dartbug.com/39263
import 'package:sqlparser/sqlparser.dart' hide ExpandParameters;
import 'package:sqlparser/src/engine/options.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:sqlparser/src/utils/meta.dart';

import 'types2/types.dart';
export 'types2/types.dart' show TypeInferenceResults;

part 'context.dart';
part 'error.dart';
part 'schema/column.dart';
part 'schema/from_create_table.dart';
part 'schema/references.dart';
part 'schema/resultset.dart';
part 'schema/table.dart';
part 'schema/view.dart';
part 'steps/column_resolver.dart';
part 'steps/linting_visitor.dart';
part 'steps/prepare_ast.dart';
part 'steps/reference_resolver.dart';
part 'steps/set_parent_visitor.dart';
part 'steps/type_resolver.dart';
part 'types/data.dart';
part 'types/resolver.dart';
part 'types/typeable.dart';
part 'options.dart';
part 'utils/expand_function_parameters.dart';

/// Something that can be represented in a human-readable description.
abstract class HumanReadable {
  String humanReadableDescription();
}
