import 'package:moor/moor.dart';
import 'package:moor_generator/moor_generator.dart';

class FindStreamUpdateRules {
  final Database db;

  FindStreamUpdateRules(this.db);

  StreamQueryUpdateRules identifyRules() {
    final rules = <UpdateRule>[];

    for (final trigger in db.entities.whereType<MoorTrigger>()) {
      rules.add(
        WritePropagation(
          TableUpdateQuery.onTable(trigger.on.sqlName),
          {
            for (final update in trigger.bodyUpdates)
              TableUpdate(update.sqlName)
          },
        ),
      );
    }

    return StreamQueryUpdateRules(rules);
  }
}
