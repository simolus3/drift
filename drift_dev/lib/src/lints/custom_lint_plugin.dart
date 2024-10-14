import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:drift_dev/src/lints/offset_without_limit.dart';
import 'package:drift_dev/src/lints/drift_backend_errors.dart';
import 'package:drift_dev/src/lints/unawaited_futures_in_transaction.dart';
import 'package:meta/meta.dart';

@internal
class DriftLinter extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        UnawaitedFuturesInTransaction(),
        DriftBuildErrors(),
        OffsetWithoutLimit()
      ];
}
