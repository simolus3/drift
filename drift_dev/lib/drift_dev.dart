import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/lints/column_builder_on_table.dart';

PluginBase createPlugin() {
  return _DriftLinter();
}

class _DriftLinter extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        ColumnBuilderOnTable(),
      ];
}
