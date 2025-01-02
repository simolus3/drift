import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:drift_dev/src/lints/drift_backend_error_lint.dart';
import 'package:drift_dev/src/lints/non_null_insert_with_ignore_lint.dart';
import 'package:drift_dev/src/lints/offset_without_limit_lint.dart';
import 'package:drift_dev/src/lints/unawaited_futures_in_transaction_lint.dart';
import 'package:meta/meta.dart';

@internal
class DriftLinter extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        unawaitedFuturesInMigration,
        unawaitedFuturesInTransaction,
        OffsetWithoutLimit(),
        DriftBuildErrors(),
        NonNullInsertWithIgnore()
      ];
}
