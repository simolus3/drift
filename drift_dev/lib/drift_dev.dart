import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:drift_dev/src/lints/custom_lint_plugin.dart';

/// This function is automaticly recognized by custom_lint to include this drift_dev package as a linter
PluginBase createPlugin() {
  return DriftLinter();
}
