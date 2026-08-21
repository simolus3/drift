import 'dart:async';

import '../../services/upgrade/drift3.dart';
import '../cli.dart';

final class UpgradeCommand extends DriftCommand {
  UpgradeCommand(super.cli);

  @override
  String get name => 'upgrade';

  @override
  String get description => 'Upgrade to a preview for drift version 3';

  @override
  bool get hidden => true;

  @override
  Future<void> run() async {
    final tool = UpgradeToDrift3(cli.project, cli.logger);
    await tool.upgrade();

    cli.logger.info(
      'Applied source changes for drift3. Run `dart run build_runner build` '
      'and `dart run drift_dev make-migrations` to generate code.',
    );
  }
}
